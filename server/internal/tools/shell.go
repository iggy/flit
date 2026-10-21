package tools

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// shellKeep is how much output the shell tool holds at each end before
// Truncate trims it for the model.
const shellKeep = 1 << 20

var shellTool = Tool{
	Name: "shell",
	Description: "Run a shell command (sh -c on Unix, cmd /C on Windows) and return its combined stdout and stderr " +
		"and exit code. Some commands need the user's approval first. Long output is cut to its start and end.",
	Schema: shellSchema,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a shellArgs
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		if strings.TrimSpace(a.Command) == "" {
			return errorf("command is empty")
		}
		dir, err := resolve(env.Dir, a.Workdir)
		if err != nil {
			return errorf("%v", err)
		}

		check := CheckShell(a.Command, Rules{Shell: env.Shell, Session: env.SessionAllowed, Yolo: env.Yolo})
		var assessed string
		if check.Decision == Ask && env.Assess != nil {
			switch v := env.Assess(ctx, a.Command, rel(env.Dir, dir)); v.Verdict {
			case VerdictSafe:
				check.Decision = Allow
			case VerdictBlock:
				return errorf("flit's safety check refused this command: %s. Do not retry it; find another way or ask the user", v.Reason)
			case VerdictAsk, VerdictError:
				assessed = v.Reason
			}
		}
		switch check.Decision {
		case Deny:
			return errorf("the command is denied by flit's shell rules (%s); do not retry it, find another way or ask the user", check.Reason)
		case Ask:
			if env.Approve == nil {
				return errorf("the command needs approval and no one can approve it")
			}
			detail := a.Command
			if a.Workdir != "" {
				detail = fmt.Sprintf("%s\n(in %s)", a.Command, rel(env.Dir, dir))
			}
			ok, err := env.Approve(ctx, Approval{
				Title: "Run shell command", Detail: detail, SessionPatterns: check.Patterns, Reason: assessed,
			})
			if err != nil {
				return errorf("approval failed: %v", err)
			}
			if !ok {
				return errorf("the user denied this command; do not retry it unchanged")
			}
		}

		return runShell(ctx, env, dir, a.Command, a.TimeoutSeconds)
	},
}

// shellSchema is the shell tools' arguments.
const shellSchema = `{"type":"object","properties":{
"command":{"type":"string","description":"The command line"},
"workdir":{"type":"string","description":"Directory to run in, relative to the working directory (default .)"},
"timeout_seconds":{"type":"integer","description":"Kill the command after this many seconds (default from config)"}
},"required":["command"]}`

type shellArgs struct {
	Command        string `json:"command"`
	Workdir        string `json:"workdir"`
	TimeoutSeconds int    `json:"timeout_seconds"`
}

// readOnlyShellTool is shell for explore subagents: it runs only commands
// whose every part is on the built-in read-only list (and that no deny rule
// matches), and refuses the rest without asking anyone.
var readOnlyShellTool = Tool{
	Name: "shell",
	Description: "Run a read-only shell command (ls, cat, head, grep, rg, find, git log/show/diff, ...) and return its output " +
		"and exit code. Commands that could change anything are refused.",
	Schema: shellSchema,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a shellArgs
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		if strings.TrimSpace(a.Command) == "" {
			return errorf("command is empty")
		}
		dir, err := resolve(env.Dir, a.Workdir)
		if err != nil {
			return errorf("%v", err)
		}
		ro := true
		check := CheckShell(a.Command, Rules{Shell: config.Shell{Deny: env.Shell.Deny, ReadOnly: &ro, Default: "deny"}})
		if check.Decision != Allow {
			return errorf("only read-only commands can run here (%s); use another command or report what you found", check.Reason)
		}
		return runShell(ctx, env, dir, a.Command, a.TimeoutSeconds)
	},
}

// runShell runs command in dir, already allowed, with the requested
// timeout in seconds (0: the default).
func runShell(ctx context.Context, env *Env, dir, command string, timeoutSeconds int) Result {
	timeout := timeoutFor(timeoutSeconds, env.Shell.Timeout, env.Shell.MaxTimeout)
	runCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	cmd := shellCommand(runCtx, command)
	cmd.Dir = dir
	out := &headTail{keep: shellKeep, live: env.Output}
	cmd.Stdout, cmd.Stderr = out, out
	cmd.WaitDelay = 2 * time.Second
	err := cmd.Run()

	text := out.String()
	if text != "" && !strings.HasSuffix(text, "\n") {
		text += "\n"
	}
	var exitErr *exec.ExitError
	switch {
	case ctx.Err() != nil:
		return Result{Text: text + "[interrupted]", IsError: true}
	case errors.Is(runCtx.Err(), context.DeadlineExceeded):
		return Result{Text: text + fmt.Sprintf("[killed: timed out after %s]", timeout), IsError: true}
	case errors.As(err, &exitErr):
		return Result{Text: text + fmt.Sprintf("[exit code %d]", exitErr.ExitCode()), IsError: true}
	case err != nil:
		return errorf("%s[failed to run: %v]", text, err)
	}
	return Result{Text: text + "[exit code 0]"}
}

// headTail keeps the first and last keep bytes written to it, counts what
// it drops in between, and passes every write to live.
type headTail struct {
	keep    int
	live    func(string)
	mu      sync.Mutex
	head    []byte
	tail    []byte
	dropped int64
}

func (h *headTail) Write(p []byte) (int, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.live != nil {
		h.live(string(p))
	}
	n := len(p)
	if room := h.keep - len(h.head); room > 0 {
		take := min(room, len(p))
		h.head = append(h.head, p[:take]...)
		p = p[take:]
	}
	if len(p) == 0 {
		return n, nil
	}
	h.tail = append(h.tail, p...)
	if over := len(h.tail) - h.keep; over > 0 {
		h.dropped += int64(over)
		h.tail = append(h.tail[:0], h.tail[over:]...)
	}
	return n, nil
}

func (h *headTail) String() string {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.dropped == 0 {
		return string(h.head) + string(h.tail)
	}
	return fmt.Sprintf("%s\n[... %d bytes omitted ...]\n%s", h.head, h.dropped, h.tail)
}
