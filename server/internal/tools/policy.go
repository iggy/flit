package tools

import (
	"regexp"
	"slices"
	"strings"

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

// shellOperators split or redirect commands. A command using any of them is
// never auto-allowed, so "ls; rm -rf x" doesn't ride on an "ls*" rule.
var shellOperators = regexp.MustCompile("[;&|<>`\\n]|\\$\\(")

// ShellDecision applies the shell allow/deny rules to cmd. Deny patterns are
// checked against the whole command and each part between shell operators.
// These rules are a convenience to avoid prompts, not a sandbox.
func ShellDecision(cmd string, sh config.Shell) Decision {
	return ShellDecisionWith(cmd, sh, nil)
}

// ShellDecisionWith is ShellDecision plus the session's own allowed
// patterns (see SessionPatterns): a command whose every part matches one is
// allowed, unless a deny rule matches first.
func ShellDecisionWith(cmd string, sh config.Shell, session []string) Decision {
	cmd = strings.TrimSpace(cmd)
	parts := append([]string{cmd}, shellOperators.Split(cmd, -1)...)
	for _, pat := range sh.Deny {
		for _, part := range parts {
			if globMatch(pat, strings.TrimSpace(part)) {
				return Deny
			}
		}
	}
	if !shellOperators.MatchString(cmd) {
		for _, pat := range sh.Allow {
			if globMatch(pat, cmd) {
				return Allow
			}
		}
	}
	if len(session) > 0 {
		if pats, ok := SessionPatterns(cmd); ok {
			all := true
			for _, p := range pats {
				if !slices.Contains(session, p) {
					all = false
					break
				}
			}
			if all {
				return Allow
			}
		}
	}
	switch sh.Default {
	case "allow":
		return Allow
	case "deny":
		return Deny
	default:
		return Ask
	}
}

// globMatch matches s against pattern, where "*" matches any run of
// characters (including none) and everything else is literal.
func globMatch(pattern, s string) bool {
	parts := strings.Split(strings.TrimSpace(pattern), "*")
	for i, p := range parts {
		parts[i] = regexp.QuoteMeta(p)
	}
	re, err := regexp.Compile("^" + strings.Join(parts, ".*") + "$")
	return err == nil && re.MatchString(s)
}

// sessionUnsafe marks commands "allow for session" never covers: command
// substitution and redirection can do far more than the program named.
var sessionUnsafe = regexp.MustCompile("[<>`]|\\$\\(")

// sessionSplit separates the parts of a compound command.
var sessionSplit = regexp.MustCompile(`&&|\|\||[;|&\n]`)

var assignment = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*=`)

var subcommand = regexp.MustCompile(`^[a-z][a-z0-9:_-]*$`)

// SessionPatterns returns what "allow for this session" would allow for
// cmd: for each part of the command, its program plus subcommand (e.g.
// "go test *", "git status *") or just the program when the second word
// isn't a subcommand ("ls *"). Leading "cd ..." parts and FOO=bar
// assignments are skipped. ok is false for commands that can't be allowed
// this way (redirection, command substitution, nothing left).
func SessionPatterns(cmd string) (patterns []string, ok bool) {
	if sessionUnsafe.MatchString(cmd) {
		return nil, false
	}
	for _, part := range sessionSplit.Split(cmd, -1) {
		words := strings.Fields(part)
		for len(words) > 0 && assignment.MatchString(words[0]) {
			words = words[1:]
		}
		if len(words) == 0 || words[0] == "cd" {
			continue
		}
		key := words[0]
		if len(words) > 1 && subcommand.MatchString(words[1]) {
			key += " " + words[1]
		}
		p := key + " *"
		if !slices.Contains(patterns, p) {
			patterns = append(patterns, p)
		}
	}
	return patterns, len(patterns) > 0
}
