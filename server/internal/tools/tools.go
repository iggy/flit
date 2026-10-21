// Package tools implements the agent's built-in tools: read, write, patch,
// list, grep and shell. File tools are confined to the session's working
// directory.
package tools

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
)

// Env is what a tool call can see and do.
type Env struct {
	// Dir is the session's working directory (absolute).
	Dir string
	// Shell is the shell config in effect for this call.
	Shell config.Shell
	// Output receives live output (shell). May be nil.
	Output func(string)
	// Approve asks the user to allow something and blocks until they
	// answer or ctx ends. Nil means nothing can be approved.
	Approve func(ctx context.Context, a Approval) (bool, error)
	// SessionAllowed are shell patterns the user allowed for the rest of
	// the session (see Check.Patterns).
	SessionAllowed []string
	// Yolo runs every shell command no deny rule matches.
	Yolo bool
	// Assess rates a shell command the rules would ask about, before the
	// user is asked (the permission task's model). Nil means no rating.
	Assess func(ctx context.Context, command, workdir string) Assessment
	// Todo receives the agent's task list whenever the todo tool changes
	// it. May be nil.
	Todo func([]TodoItem)
	// Subagent runs the agent tool's subagent. Nil inside a subagent, so
	// subagents can't start subagents.
	Subagent func(ctx context.Context, args json.RawMessage) Result
}

// ErrNotApproved wraps an Approve error that means nobody approved it (an
// unattended run); tools report it to the model as it is.
var ErrNotApproved = errors.New("not approved")

// Approval is what the user is asked to allow.
type Approval struct {
	// Title is short, e.g. "Run shell command"; Detail is exactly what
	// would happen, e.g. the command line.
	Title, Detail string
	// SessionPatterns, if any, are offered as "allow for this session".
	SessionPatterns []string
	// Reason is the safety check's reason for asking, if it ran.
	Reason string
}

// Verdict is the safety check's rating of a shell command.
type Verdict int

const (
	// VerdictError means the check failed (no answer, unreadable answer);
	// the user is asked.
	VerdictError Verdict = iota
	VerdictSafe
	VerdictAsk
	VerdictBlock
)

func (v Verdict) String() string {
	return [...]string{"error", "safe", "ask", "block"}[v]
}

// Assessment is the safety check's verdict and why.
type Assessment struct {
	Verdict Verdict
	Reason  string
}

// Result is what the model gets back.
type Result struct {
	Text    string
	IsError bool
}

func errorf(format string, args ...any) Result {
	return Result{Text: fmt.Sprintf(format, args...), IsError: true}
}

// Tool is one built-in tool.
type Tool struct {
	Name        string
	Description string
	Schema      string // JSON Schema of the arguments object
	// ReadOnly tools only read (files, git, the web), so explore
	// subagents may have them (see ReadOnlySet).
	ReadOnly bool
	Run      func(ctx context.Context, env *Env, args json.RawMessage) Result
}

// All returns the core built-in tools, always offered.
func All() []Tool {
	return []Tool{readTool, writeTool, patchTool, listTool, grepTool, shellTool, todoTool}
}

// ReadOnlySet is the part of set that only reads: the ReadOnly tools, and
// shell as ReadOnlyShellTool when set has shell and readOnly (the built-in
// read-only list, shell.read_only) is on.
func ReadOnlySet(set []Tool, readOnly bool) []Tool {
	var out []Tool
	for _, t := range set {
		switch {
		case t.ReadOnly:
			out = append(out, t)
		case t.Name == shellTool.Name && readOnly:
			out = append(out, readOnlyShellTool)
		}
	}
	return out
}

// Definitions returns set in chat completions format.
func Definitions(set []Tool) []llm.Tool {
	var out []llm.Tool
	for _, t := range set {
		out = append(out, llm.Tool{Type: "function", Function: llm.ToolFunction{
			Name: t.Name, Description: t.Description, Parameters: json.RawMessage(t.Schema),
		}})
	}
	return out
}

// Run runs the named tool from set. Unknown tools and malformed arguments
// are reported to the model as errors rather than failing the turn.
func Run(ctx context.Context, env *Env, set []Tool, name, args string) Result {
	for _, t := range set {
		if t.Name == name {
			if strings.TrimSpace(args) == "" {
				args = "{}"
			}
			if !json.Valid([]byte(args)) {
				return errorf("arguments are not valid JSON: %s", args)
			}
			return t.Run(ctx, env, json.RawMessage(args))
		}
	}
	return errorf("unknown tool %q", name)
}

// decode unmarshals args strictly, so misspelled argument names are reported.
func decode(args json.RawMessage, v any) error {
	dec := json.NewDecoder(strings.NewReader(string(args)))
	dec.DisallowUnknownFields()
	if err := dec.Decode(v); err != nil {
		return fmt.Errorf("bad arguments: %w", err)
	}
	return nil
}

// resolve turns a tool path argument into an absolute path inside dir.
// Relative paths are relative to dir. Paths that leave dir, including via
// symlinks, are refused.
func resolve(dir, p string) (string, error) {
	if p == "" {
		p = "."
	}
	if !filepath.IsAbs(p) {
		p = filepath.Join(dir, p)
	}
	p = filepath.Clean(p)
	if !within(dir, p) {
		return "", fmt.Errorf("%s is outside the working directory %s", p, dir)
	}

	// Check where symlinks really lead, using the deepest existing ancestor.
	realDir, err := filepath.EvalSymlinks(dir)
	if err != nil {
		return "", err
	}
	existing, rest := p, ""
	for {
		if _, err := os.Lstat(existing); err == nil {
			break
		}
		parent := filepath.Dir(existing)
		if parent == existing {
			break
		}
		rest = filepath.Join(filepath.Base(existing), rest)
		existing = parent
	}
	real, err := filepath.EvalSymlinks(existing)
	if err != nil {
		return "", err
	}
	if !within(realDir, filepath.Join(real, rest)) {
		return "", fmt.Errorf("%s leads outside the working directory %s", p, dir)
	}
	return p, nil
}

func within(dir, p string) bool {
	rel, err := filepath.Rel(dir, p)
	return err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) && !filepath.IsAbs(rel)
}

// rel shows p relative to dir for output.
func rel(dir, p string) string {
	if r, err := filepath.Rel(dir, p); err == nil {
		return filepath.ToSlash(r)
	}
	return p
}

func isBinary(b []byte) bool {
	if len(b) > 8000 {
		b = b[:8000]
	}
	for _, c := range b {
		if c == 0 {
			return true
		}
	}
	return false
}

// timeoutFor picks the shell timeout: requested (seconds) if positive,
// capped at max; otherwise def.
func timeoutFor(requested int, def, max time.Duration) time.Duration {
	if requested <= 0 {
		return def
	}
	d := time.Duration(requested) * time.Second
	if d > max {
		return max
	}
	return d
}
