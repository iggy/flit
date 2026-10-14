package tools

import (
	"regexp"
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
