// Package facts learns small facts about a project's environment from the
// event log, without any model calls: that `pytest` only works as
// `python -m pytest` here, that a host is unreachable, that a variable must
// be set. See docs/learning.md.
package facts

import (
	"encoding/json"
	"path"
	"regexp"
	"strconv"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/tools"
)

// Intents: what a part of a command is for.
const (
	intentTests       = "run_tests"
	intentBuild       = "run_build"
	intentPackage     = "package_tool"
	intentInterpreter = "run_interpreter"
	intentFetch       = "fetch"
	intentVCSProbe    = "vcs_probe"
)

// Error classes read off a command's output.
const (
	errModule     = "module_missing"
	errCommand    = "command_missing"
	errPermission = "permission_denied"
	errEnv        = "env_missing"
	errRefused    = "connection_refused"
	errResolve    = "name_resolution"
	errUnreach    = "unreachable"
	errBlocked    = "host_blocked"
)

// outcome is what can be said about one part of a command.
type outcome int

const (
	unknown outcome = iota
	worked
	failed
)

// observation is one classified part of a shell command.
type observation struct {
	turn   int // 1-based, as in flit learn's T1, T2, ...
	call   int
	intent string
	form   string // how it was spelled, without its arguments
	tool   string // what it runs, however spelled: python -m pytest is pytest
	bare   bool   // the form is the tool's name and nothing else
	hosts  []string
	env    map[string]envSetting // variables set for this part

	outcome outcome
	class   string   // error class, when failed or connected badly
	missing []string // environment variables the output asks for
}

type envSetting struct {
	value   string
	literal bool
}

func (o observation) typedOK() bool { return o.outcome == worked && len(o.env) == 0 }

var (
	exitCodeRE = regexp.MustCompile(`\[exit code (\d+)\]`)
	safeWordRE = regexp.MustCompile(`^[A-Za-z0-9_./:@+-]+$`)
	notFoundRE = regexp.MustCompile(`(?i)([^\s:'"]+):\s+(?:command\s+)?not found\b|command not found:\s+(\S+)|'([^']+)' is not recognized`)
	testsRanRE = regexp.MustCompile(`(?m)\b\d+ (?:passed|failed)\b|^FAILED\b|^--- (?:PASS|FAIL)|^(?:ok|FAIL)\s+\S+|^Ran \d+ tests?|^Tests:\s+\d+`)

	classes = []struct {
		name string
		re   *regexp.Regexp
	}{
		{errModule, regexp.MustCompile(`(?i)ModuleNotFoundError|No module named|Cannot find module|ERR_MODULE_NOT_FOUND|no required module provides package|cannot find package`)},
		{errCommand, regexp.MustCompile(`(?i)command not found|: not found\b|is not recognized as`)},
		{errPermission, regexp.MustCompile(`Permission denied|EACCES`)},
		{errBlocked, regexp.MustCompile(`(?i)CONNECT tunnel failed|Proxy CONNECT aborted|host not allowed|not in (?:the )?allow ?list|blocked by (?:network|egress|proxy|policy)`)},
		{errRefused, regexp.MustCompile(`(?i)Connection refused|Failed to connect to|couldn't connect to|Could not connect|ECONNREFUSED`)},
		{errResolve, regexp.MustCompile(`(?i)Could not resolve host|Temporary failure in name resolution|Name or service not known|nodename nor servname|ENOTFOUND|no such host`)},
		{errUnreach, regexp.MustCompile(`(?i)Network is unreachable|No route to host|Connection timed out|Operation timed out|ETIMEDOUT`)},
	}

	missingVarREs = []*regexp.Regexp{
		regexp.MustCompile(`\b[Ee]nv(?:ironment)?\s+[Vv]ar(?:iable)?s?\b[^\n]{0,20}?\b([A-Z][A-Z0-9_]{2,})\b`),
		regexp.MustCompile(`\b([A-Z][A-Z0-9_]{2,})\b['"]?\s+(?:is\s+)?(?:not set|unset|must be set|is required|required but not set)\b`),
		regexp.MustCompile(`KeyError: ['"]([A-Z][A-Z0-9_]{2,})['"]`),
		regexp.MustCompile(`\b([A-Z][A-Z0-9_]{2,}): (?:unbound variable|parameter null or not set)`),
	}
)

func isFormError(class string) bool {
	return class == errModule || class == errCommand || class == errPermission
}

func isNetworkError(class string) bool {
	return class == errRefused || class == errResolve || class == errUnreach || class == errBlocked
}

// classOf is the first error class the output shows.
func classOf(text string) string {
	for _, c := range classes {
		if c.re.MatchString(text) {
			return c.name
		}
	}
	return ""
}

// notFoundNames are the commands "not found" lines name.
func notFoundNames(text string) []string {
	var out []string
	for _, m := range notFoundRE.FindAllStringSubmatch(text, -1) {
		for _, g := range m[1:] {
			if g != "" {
				out = append(out, path.Base(g))
			}
		}
	}
	return out
}

func missingVars(text string) []string {
	var out []string
	seen := map[string]bool{}
	for _, re := range missingVarREs {
		for _, m := range re.FindAllStringSubmatch(text, -1) {
			if !seen[m[1]] {
				seen[m[1]] = true
				out = append(out, m[1])
			}
		}
	}
	return out
}

// exitCode reads the [exit code N] the shell tool ends its result with.
// A command that was refused, timed out or interrupted has none.
func exitCode(result string) (int, bool) {
	all := exitCodeRE.FindAllStringSubmatch(result, -1)
	if len(all) == 0 {
		return 0, false
	}
	n, err := strconv.Atoi(all[len(all)-1][1])
	return n, err == nil
}

// observeEvents reads the shell calls in a session's events (a path, in
// order) and classifies their parts. Calls that didn't run to an exit code
// are left out.
func observeEvents(events []*flitv1.Event, workDir string) []observation {
	type started struct {
		command, workdir string
		turn, call       int
	}
	var out []observation
	turn, call := 0, 0
	pending := map[string]started{}
	for _, ev := range events {
		switch p := ev.Payload.(type) {
		case *flitv1.Event_MessageStarted:
			if p.MessageStarted.Role == flitv1.Role_ROLE_USER {
				turn++
			}
		case *flitv1.Event_ToolCallStarted:
			c := p.ToolCallStarted
			call++
			delete(pending, c.ToolCallId) // providers reuse ids across steps
			if c.Name != "shell" {
				continue
			}
			var a struct {
				Command string `json:"command"`
				Workdir string `json:"workdir"`
			}
			if json.Unmarshal([]byte(c.Arguments), &a) != nil || a.Command == "" {
				continue
			}
			pending[c.ToolCallId] = started{a.Command, a.Workdir, max(turn, 1), call}
		case *flitv1.Event_ToolCallDone:
			d := p.ToolCallDone
			st, ok := pending[d.ToolCallId]
			if !ok {
				continue
			}
			delete(pending, d.ToolCallId)
			out = append(out, observeCall(st.command, st.workdir, workDir, d.Result, st.turn, st.call)...)
		}
	}
	return out
}

// passthrough commands say nothing about the environment, and don't count
// when working out which part of a chain an error belongs to.
var passthrough = map[string]bool{
	"cd": true, "echo": true, "printf": true, "true": true, "false": true, "head": true, "tail": true,
	"cat": true, "sort": true, "uniq": true, "tee": true, "wc": true, "grep": true, "rg": true, "ls": true,
	"pwd": true, "sleep": true, "clear": true, "less": true, "more": true, "cut": true, "tr": true, "sed": true, "awk": true,
}

// observeCall classifies the parts of one finished shell call.
func observeCall(command, workdir, sessionDir, result string, turn, call int) []observation {
	code, ok := exitCode(result)
	if !ok {
		return nil
	}
	parts, exports, ok := tools.ShellParts(command)
	if !ok {
		return nil
	}

	cd, cdOK := relativeDir(workdir, sessionDir)
	significant := 0
	for _, p := range parts {
		if !passthrough[p.Name] {
			significant++
		}
	}
	class := classOf(result)
	if code == 127 && class == "" {
		class = errCommand
	}
	if code == 126 && class == "" {
		class = errPermission
	}
	missing := missingVars(result)
	if class == "" && len(missing) > 0 {
		class = errEnv
	}
	names := notFoundNames(result)
	testsRan := testsRanRE.MatchString(result)

	var out []observation
	for _, p := range parts {
		if p.Name == "cd" {
			target := ""
			if len(p.Args) == 1 && p.Args[0].Literal {
				target = p.Args[0].Value
			}
			if len(p.Args) == 1 && p.Args[0].Literal && !p.Masked {
				d, ok := relativeDir(target, sessionDir)
				cd, cdOK = joinDir(cd, d), cdOK && ok
			} else {
				cdOK = false
			}
			continue
		}
		if passthrough[p.Name] {
			continue
		}
		c, ok := classify(p, sessionDir)
		if !ok || !cdOK {
			continue
		}
		o := observation{turn: turn, call: call, intent: c.intent, form: c.form, tool: c.tool, bare: c.bare, hosts: c.hosts}
		if cd != "" {
			o.form, o.bare = "cd "+cd+" && "+o.form, false
		}
		o.env = envOf(p.Assigns, c.env, exports)
		o.outcome, o.class, o.missing = judge(judgeInput{
			intent: c.intent, tool: c.tool, head: c.head, code: code, class: class,
			missing: missing, names: names, testsRan: testsRan,
			masked: p.Masked, significant: significant,
		})
		out = append(out, o)
	}
	return out
}

type judgeInput struct {
	intent, tool, head string
	code               int
	class              string
	missing, names     []string
	testsRan           bool
	masked             bool
	significant        int
}

// judge decides a part's outcome. An error in the output belongs to this
// part only if the part is the only real command in the chain, or the
// error names it: `make` failing because a recipe's cc is missing says
// nothing about make.
func judge(in judgeInput) (outcome, string, []string) {
	alone := in.significant == 1
	class := in.class
	missing := in.missing

	if class == errCommand && len(in.names) > 0 {
		named := false
		for _, n := range in.names {
			if n == in.tool || n == in.head || n == path.Base(in.head) {
				named = true
			}
		}
		if !named {
			if in.code == 0 && !in.masked {
				return worked, "", nil // the chain got through it
			}
			return unknown, "", nil
		}
		if in.masked || in.code != 0 {
			return failed, errCommand, nil
		}
		return unknown, "", nil
	}

	if in.intent == intentFetch && alone {
		if !isNetworkError(class) {
			class = fetchClass(in.head, in.code)
		}
		if isNetworkError(class) {
			return failed, class, nil
		}
		// curl 22 and wget 8 are HTTP errors: it connected.
		if !in.masked && (in.code == 0 || in.code == 22 || in.code == 8) {
			return worked, "", nil
		}
		return unknown, "", nil
	}

	if class != "" && (in.code != 0 || in.masked) {
		if !alone {
			return unknown, "", nil
		}
		return failed, class, missing
	}
	if class != "" {
		return unknown, "", nil // printed something scary but exited 0
	}
	if in.masked {
		if in.intent == intentTests && in.testsRan {
			return worked, "", nil
		}
		return unknown, "", nil
	}
	if in.code == 0 {
		return worked, "", nil
	}
	if in.intent == intentTests && in.testsRan {
		return worked, "", nil // the tests ran; some failed
	}
	return unknown, "", nil
}

// fetchClass reads curl and wget's exit codes, for when they ran silent.
func fetchClass(head string, code int) string {
	switch path.Base(head) {
	case "curl":
		switch code {
		case 6:
			return errResolve
		case 7:
			return errRefused
		case 28:
			return errUnreach
		}
	case "wget":
		if code == 4 {
			return errRefused
		}
	}
	return ""
}

func envOf(lists ...[]tools.ShellAssign) map[string]envSetting {
	var out map[string]envSetting
	for _, l := range lists {
		for _, a := range l {
			if out == nil {
				out = map[string]envSetting{}
			}
			out[a.Name] = envSetting{value: a.Value, literal: a.Literal}
		}
	}
	return out
}

// relativeDir is dir as a path relative to the session's directory, so
// forms compare equal between sessions and worktrees. "" means the
// session's directory; ok is false for one that can't be told or that is
// outside it.
func relativeDir(dir, sessionDir string) (string, bool) {
	if dir == "" || dir == "." {
		return "", true
	}
	if !safeWordRE.MatchString(dir) {
		return "", false
	}
	if path.IsAbs(dir) {
		rest, ok := strings.CutPrefix(path.Clean(dir), path.Clean(sessionDir))
		if !ok || (rest != "" && rest[0] != '/') {
			return "", false
		}
		dir = strings.TrimPrefix(rest, "/")
		if dir == "" {
			return "", true
		}
	}
	dir = path.Clean(dir)
	if dir == "." {
		return "", true
	}
	if dir == ".." || strings.HasPrefix(dir, "../") {
		return "", false
	}
	return dir, true
}

func joinDir(a, b string) string {
	switch {
	case a == "":
		return b
	case b == "":
		return a
	}
	return path.Join(a, b)
}
