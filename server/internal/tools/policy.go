package tools

import (
	"fmt"
	"regexp"
	"slices"
	"strings"

	"mvdan.cc/sh/v3/syntax"

	"github.com/iggy/flit/server/internal/config"
)

// Decision is what the shell rules say about a command.
type Decision int

const (
	Allow Decision = iota
	Ask
	Deny
)

func (d Decision) String() string {
	return [...]string{"allow", "ask", "deny"}[d]
}

// Rules are everything that decides whether a shell command runs.
type Rules struct {
	Shell config.Shell
	// Session are the patterns the user allowed for the rest of the
	// session (see Check.Patterns).
	Session []string
	// Yolo runs every command that no deny rule matches.
	Yolo bool
}

// Check is what the rules say about one command, and why.
type Check struct {
	Decision Decision
	// Reason says why, in a few words: the deny rule that matched, what
	// keeps the command from being auto-allowed, or the parts no rule
	// covers.
	Reason string
	// Patterns is what "allow for this session" would add: one per part of
	// the command that isn't already allowed. Empty when it can't be
	// offered (redirection to a file, command substitution, ...).
	Patterns []string
}

// fallbackSplit separates the parts of a command the parser can't read,
// so deny rules still see each part.
var fallbackSplit = regexp.MustCompile("&&|\\|\\||[;&|\\n`]|\\$\\(")

// CheckShell applies the rules to cmd.
//
// The command is parsed as a shell script and split into its simple
// commands (the parts of chains, pipes, loops and conditionals). Deny
// patterns are checked against the whole command and every part, and deny
// always wins. Otherwise the command runs without asking when every part is
// allowed: by an allow pattern, by the built-in read-only list (see
// shell.read_only), or by an "allow for this session" pattern. Command and
// process substitution, redirection to a file, function definitions and
// other constructs the rules can't see through always fall to
// shell.default.
//
// These rules are a convenience to avoid prompts, not a sandbox.
func CheckShell(cmd string, r Rules) Check {
	cmd = strings.TrimSpace(cmd)
	p := parseShell(cmd)

	texts := []string{cmd}
	for _, part := range fallbackSplit.Split(cmd, -1) {
		texts = append(texts, strings.TrimSpace(part))
	}
	for _, s := range p.segments {
		texts = append(texts, s.text, s.full)
	}
	for _, pat := range r.Shell.Deny {
		for _, t := range texts {
			if t != "" && globMatch(pat, t) {
				return Check{Decision: Deny, Reason: fmt.Sprintf("denied by shell rule %q", pat)}
			}
		}
	}
	if r.Yolo {
		return Check{Decision: Allow, Reason: "yolo mode"}
	}

	fallback := func(reason string, patterns []string) Check {
		switch r.Shell.Default {
		case "allow":
			return Check{Decision: Allow, Reason: "shell.default is allow"}
		case "deny":
			return Check{Decision: Deny, Reason: reason + "; shell.default is deny"}
		}
		return Check{Decision: Ask, Reason: reason, Patterns: patterns}
	}
	if p.unsafe != "" {
		return fallback(p.unsafe, nil)
	}

	var uncovered, patterns []string
	for _, s := range p.segments {
		if segmentAllowed(s, r) {
			continue
		}
		uncovered = append(uncovered, s.text)
		if pat := s.sessionPattern(); !slices.Contains(patterns, pat) {
			patterns = append(patterns, pat)
		}
	}
	if len(uncovered) == 0 {
		return Check{Decision: Allow, Reason: "every part is allowed"}
	}
	return fallback("not allowed by any rule: "+strings.Join(uncovered, "; "), patterns)
}

// ShellDecision is CheckShell(cmd, Rules{Shell: sh}).Decision.
func ShellDecision(cmd string, sh config.Shell) Decision {
	return CheckShell(cmd, Rules{Shell: sh}).Decision
}

func segmentAllowed(s segment, r Rules) bool {
	if s.name == "cd" {
		return true
	}
	for _, pat := range r.Shell.Allow {
		if globMatch(pat, s.text) || globMatch(pat, s.full) {
			return true
		}
	}
	if r.Shell.ReadOnlyEnabled() && readOnly(s.name, s.args) {
		return true
	}
	return slices.Contains(r.Session, s.sessionPattern())
}

// globMatch matches s against pattern, where "*" matches any run of
// characters (including none) and everything else is literal.
func globMatch(pattern, s string) bool {
	parts := strings.Split(strings.TrimSpace(pattern), "*")
	for i, p := range parts {
		parts[i] = regexp.QuoteMeta(p)
	}
	re, err := regexp.Compile("(?s)^" + strings.Join(parts, ".*") + "$")
	return err == nil && re.MatchString(s)
}

// segment is one simple command: a program and its arguments.
type segment struct {
	// text is the command as written, without leading FOO=bar
	// assignments; full includes them.
	text, full string
	name       string
	args       []arg
}

// arg is one argument after quote removal. lit is false when its value is
// only known when the command runs (it expands a variable or an unquoted
// glob).
type arg struct {
	val string
	lit bool
}

var subcommand = regexp.MustCompile(`^[a-z][a-z0-9:_-]*$`)

// sessionPattern is what "allow for this session" allows for s: its
// program plus subcommand (e.g. "go test *", "git status *"), or just the
// program when the second word isn't a subcommand ("ls *").
func (s segment) sessionPattern() string {
	key := s.name
	if len(s.args) > 0 && s.args[0].lit && subcommand.MatchString(s.args[0].val) {
		key += " " + s.args[0].val
	}
	return key + " *"
}

// parsed is a command split into its simple commands, plus the first
// reason, if any, that it can't be auto-allowed whatever its parts are.
type parsed struct {
	segments []segment
	unsafe   string
}

// dangerousEnv are variables that change what a command runs or loads, so
// FOO=bar prefixes setting them are never auto-allowed.
var dangerousEnv = regexp.MustCompile(`^(PATH|IFS|ENV|BASH_ENV|PS4|PROMPT_COMMAND|SHELLOPTS|BASHOPTS|PAGER|EDITOR|VISUAL|LESSOPEN|LESSCLOSE|PERL5OPT|PYTHONSTARTUP|NODE_OPTIONS|(LD|DYLD|GIT)_.*)$`)

func parseShell(src string) parsed {
	f, err := syntax.NewParser(syntax.Variant(syntax.LangBash)).Parse(strings.NewReader(src), "")
	if err != nil {
		return parsed{unsafe: "could not parse the command"}
	}
	var p parsed
	unsafe := func(reason string) {
		if p.unsafe == "" {
			p.unsafe = reason
		}
	}
	syntax.Walk(f, func(n syntax.Node) bool {
		switch n := n.(type) {
		case *syntax.CmdSubst:
			unsafe("uses command substitution")
		case *syntax.ProcSubst:
			unsafe("uses process substitution")
		case *syntax.Redirect:
			if !safeRedirect(n) {
				unsafe(fmt.Sprintf("redirects output to a file (%s)", n.Op))
			}
		}
		return true
	})
	slice := func(a, b syntax.Node) string {
		return src[a.Pos().Offset():b.End().Offset()]
	}

	var stmts func([]*syntax.Stmt)
	var command func(syntax.Command)
	stmts = func(list []*syntax.Stmt) {
		for _, st := range list {
			if st.Coprocess {
				unsafe("starts a coprocess")
			}
			if st.Cmd != nil {
				command(st.Cmd)
			}
		}
	}
	command = func(c syntax.Command) {
		switch c := c.(type) {
		case *syntax.CallExpr:
			for _, a := range c.Assigns {
				if a.Name == nil || dangerousEnv.MatchString(a.Name.Value) {
					unsafe("sets an environment variable that changes what runs")
				}
			}
			if len(c.Args) == 0 {
				return // FOO=bar on its own
			}
			name := wordValue(c.Args[0])
			if !name.lit || name.val == "" {
				unsafe("the program name is only known when it runs")
				return
			}
			s := segment{text: slice(c.Args[0], c.Args[len(c.Args)-1]), full: slice(c, c), name: name.val}
			for _, w := range c.Args[1:] {
				s.args = append(s.args, wordValue(w))
			}
			p.segments = append(p.segments, s)
		case *syntax.BinaryCmd:
			stmts([]*syntax.Stmt{c.X, c.Y})
		case *syntax.Block:
			stmts(c.Stmts)
		case *syntax.Subshell:
			stmts(c.Stmts)
		case *syntax.IfClause:
			for ; c != nil; c = c.Else {
				stmts(c.Cond)
				stmts(c.Then)
			}
		case *syntax.WhileClause:
			stmts(c.Cond)
			stmts(c.Do)
		case *syntax.ForClause:
			stmts(c.Do)
		case *syntax.TimeClause:
			if c.Stmt != nil {
				stmts([]*syntax.Stmt{c.Stmt})
			}
		case *syntax.TestClause, *syntax.ArithmCmd:
			// [[ ... ]] and (( ... )) only compute; substitutions inside
			// were caught above.
		case *syntax.FuncDecl:
			unsafe("defines a function")
		default:
			unsafe(fmt.Sprintf("uses a shell construct flit doesn't check (%s)", strings.TrimPrefix(fmt.Sprintf("%T", c), "*syntax.")))
		}
	}
	stmts(f.Stmts)
	return p
}

// safeRedirect reports whether r only reads, duplicates a descriptor or
// discards output: <file, here-documents, 2>&1, >/dev/null.
func safeRedirect(r *syntax.Redirect) bool {
	var target arg
	if r.Word != nil {
		target = wordValue(r.Word)
	}
	switch r.Op {
	case syntax.RdrIn, syntax.Hdoc, syntax.DashHdoc, syntax.WordHdoc:
		return true
	case syntax.DplIn, syntax.DplOut:
		// >&2, 2>&1, >&-; but >&file writes to file.
		return target.lit && target.val != "" && (target.val == "-" || strings.Trim(target.val, "0123456789") == "")
	case syntax.RdrOut, syntax.AppOut, syntax.RdrAll, syntax.AppAll, syntax.RdrClob:
		switch target.val {
		case "/dev/null", "/dev/stdout", "/dev/stderr":
			return target.lit
		}
	}
	return false
}

// wordValue is w after quote removal. It is not lit when the value depends
// on expansion (variables, unquoted globs, ~, ...).
func wordValue(w *syntax.Word) arg {
	var b strings.Builder
	lit := true
	var parts func([]syntax.WordPart, bool)
	parts = func(ps []syntax.WordPart, quoted bool) {
		for _, part := range ps {
			switch part := part.(type) {
			case *syntax.Lit:
				v := part.Value
				if !quoted {
					if isGlob(v) || strings.HasPrefix(v, "~") {
						lit = false
					}
					v = unescape(v)
				}
				b.WriteString(v)
			case *syntax.SglQuoted:
				if part.Dollar {
					lit = false
				}
				b.WriteString(part.Value)
			case *syntax.DblQuoted:
				if part.Dollar {
					lit = false
				}
				parts(part.Parts, true)
			default:
				lit = false
			}
		}
	}
	parts(w.Parts, false)
	return arg{val: b.String(), lit: lit}
}

// isGlob reports whether an unquoted literal is a pathname pattern.
func isGlob(v string) bool {
	return strings.ContainsAny(v, "*?") || strings.Contains(v, "[") && strings.Contains(v, "]") && len(v) > 1
}

// unescape removes backslash escapes from an unquoted literal.
func unescape(s string) string {
	if !strings.Contains(s, `\`) {
		return s
	}
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		if s[i] == '\\' && i+1 < len(s) {
			i++
		}
		b.WriteByte(s[i])
	}
	return b.String()
}
