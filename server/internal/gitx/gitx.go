// Package gitx runs git for flit. It shells out to the git binary (no cgo,
// no git library) without prompts, a pager or optional locks, and answers
// the questions the server asks about a session's repository: where it is,
// which commit it is on, what changed and the diff of those changes.
package gitx

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"
)

// Timeout bounds one git command unless Options.Timeout says otherwise.
const Timeout = 30 * time.Second

// ErrNoGit is returned when the git binary isn't installed.
var ErrNoGit = errors.New("git is not installed")

// Options tune one git command.
type Options struct {
	// Env is added to the environment.
	Env []string
	// Stdin is the command's input; nil means none.
	Stdin io.Reader
	// Timeout bounds the command; 0 means Timeout.
	Timeout time.Duration
	// Combined returns stderr together with stdout, for showing a command's
	// whole output to the model.
	Combined bool
	// Limit caps how much output is kept (0: no cap). Output beyond it is
	// discarded and reported by Truncated.
	Limit int
}

// Output is what a command printed.
type Output struct {
	Text string
	// Truncated says Options.Limit cut the output.
	Truncated bool
}

// Run runs git in dir and returns its stdout. On failure the error carries
// git's stderr.
func Run(ctx context.Context, dir string, args ...string) (string, error) {
	out, err := RunOpts(ctx, dir, Options{}, args...)
	return out.Text, err
}

// RunOpts is Run with options.
func RunOpts(ctx context.Context, dir string, o Options, args ...string) (Output, error) {
	timeout := o.Timeout
	if timeout <= 0 {
		timeout = Timeout
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, "git", append([]string{"-C", dir, "--no-pager"}, args...)...)
	cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0", "GIT_EDITOR=true", "GIT_PAGER=cat")
	cmd.Env = append(cmd.Env, o.Env...)
	cmd.Stdin = o.Stdin
	stdout := &capWriter{limit: o.Limit}
	var stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = stdout, &stderr
	if o.Combined {
		cmd.Stderr = stdout
	}
	err := cmd.Run()
	out := Output{Text: stdout.buf.String(), Truncated: stdout.truncated}
	if errors.Is(err, exec.ErrNotFound) {
		return out, ErrNoGit
	}
	if err != nil {
		msg := strings.TrimSpace(stderr.String())
		if o.Combined {
			msg = strings.TrimSpace(out.Text)
		}
		return out, fmt.Errorf("git %s: %v\n%s", args[0], err, msg)
	}
	return out, nil
}

// capWriter keeps the first limit bytes written to it (all of them if
// limit is 0) and swallows the rest, so git never blocks on a full pipe.
type capWriter struct {
	buf       bytes.Buffer
	limit     int
	truncated bool
}

func (w *capWriter) Write(p []byte) (int, error) {
	if w.limit > 0 {
		room := w.limit - w.buf.Len()
		if room < len(p) {
			w.truncated = true
			w.buf.Write(p[:max(room, 0)])
			return len(p), nil
		}
	}
	return w.buf.Write(p)
}

// readEnv is the environment for read-only queries: they must not take the
// index lock behind the user's (or the agent's) back, and paths are never
// pathspec patterns.
var readEnv = []string{"GIT_OPTIONAL_LOCKS=0", "GIT_LITERAL_PATHSPECS=1"}

func read(ctx context.Context, dir string, args ...string) (string, error) {
	out, err := RunOpts(ctx, dir, Options{Env: readEnv}, args...)
	return out.Text, err
}

// Root returns the top directory of the work tree containing dir, or ""
// when dir isn't inside one.
func Root(ctx context.Context, dir string) (string, error) {
	out, err := read(ctx, dir, "rev-parse", "--show-toplevel")
	if errors.Is(err, ErrNoGit) {
		return "", err
	}
	if err != nil {
		return "", nil
	}
	return strings.TrimSpace(out), nil
}

// Head returns the commit HEAD points at in dir's repository, or "" when
// dir isn't in a repository or HEAD is unborn (no commits yet).
func Head(ctx context.Context, dir string) (string, error) {
	root, err := Root(ctx, dir)
	if root == "" {
		return "", err
	}
	return head(ctx, root), nil
}

func head(ctx context.Context, root string) string {
	out, err := read(ctx, root, "rev-parse", "--verify", "--quiet", "HEAD^{commit}")
	if err != nil {
		return ""
	}
	return strings.TrimSpace(out)
}
