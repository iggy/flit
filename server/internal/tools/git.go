package tools

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// gitTimeout bounds one git command (a commit can run hooks).
const gitTimeout = 2 * time.Minute

// GitTools returns git_status, git_diff, git_log and git_commit. They work
// on the repository containing the session's working directory. None of
// them push or touch remotes.
func GitTools() []Tool {
	return []Tool{gitStatusTool, gitDiffTool, gitLogTool, gitCommitTool}
}

// git runs git in dir without prompts or a pager.
func git(ctx context.Context, dir string, args ...string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, gitTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, "git", append([]string{"-C", dir, "--no-pager"}, args...)...)
	cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0", "GIT_EDITOR=true", "GIT_PAGER=cat")
	var out bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &out
	err := cmd.Run()
	if err != nil {
		return out.String(), fmt.Errorf("git %s: %v\n%s", args[0], err, strings.TrimSpace(out.String()))
	}
	return out.String(), nil
}

func gitResult(out string, err error) Result {
	if err != nil {
		return errorf("%v", err)
	}
	if strings.TrimSpace(out) == "" {
		return Result{Text: "(no output)"}
	}
	return Result{Text: out}
}

var gitStatusTool = Tool{
	Name:        "git_status",
	ReadOnly:    true,
	Description: "Show the git branch and changed files of the repository you are working in.",
	Schema:      `{"type":"object","properties":{}}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		if err := decode(raw, &struct{}{}); err != nil {
			return errorf("%v", err)
		}
		return gitResult(git(ctx, env.Dir, "status", "--short", "--branch"))
	},
}

var gitDiffTool = Tool{
	Name:        "git_diff",
	ReadOnly:    true,
	Description: "Show changes as a unified diff: unstaged changes by default, staged ones with staged=true, or against a commit with ref.",
	Schema: `{"type":"object","properties":{
"staged":{"type":"boolean","description":"Diff the index instead of the working tree"},
"ref":{"type":"string","description":"Compare against this commit or branch, e.g. HEAD~1"},
"path":{"type":"string","description":"Limit to this file or directory"}
}}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Staged bool   `json:"staged"`
			Ref    string `json:"ref"`
			Path   string `json:"path"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		args := []string{"diff", "--no-color"}
		if a.Staged {
			args = append(args, "--staged")
		}
		if a.Ref != "" {
			if strings.HasPrefix(a.Ref, "-") {
				return errorf("ref must not start with -")
			}
			args = append(args, a.Ref)
		}
		if a.Path != "" {
			p, err := resolve(env.Dir, a.Path)
			if err != nil {
				return errorf("%v", err)
			}
			args = append(args, "--", p)
		}
		return gitResult(git(ctx, env.Dir, args...))
	},
}

var gitLogTool = Tool{
	Name:        "git_log",
	ReadOnly:    true,
	Description: "Show recent commits (hash, date, author, subject).",
	Schema: `{"type":"object","properties":{
"count":{"type":"integer","description":"How many commits (default 10, max 100)"},
"path":{"type":"string","description":"Only commits touching this file or directory"}
}}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Count int    `json:"count"`
			Path  string `json:"path"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		n := a.Count
		if n <= 0 {
			n = 10
		}
		args := []string{"log", "-n", strconv.Itoa(min(n, 100)), "--format=%h %ad %an: %s", "--date=short"}
		if a.Path != "" {
			p, err := resolve(env.Dir, a.Path)
			if err != nil {
				return errorf("%v", err)
			}
			args = append(args, "--", p)
		}
		return gitResult(git(ctx, env.Dir, args...))
	},
}

var gitCommitTool = Tool{
	Name: "git_commit",
	Description: "Commit changes locally (never pushes). Stages the given paths first, or every tracked change with all=true; " +
		"with neither, commits what is already staged.",
	Schema: `{"type":"object","properties":{
"message":{"type":"string","description":"The commit message"},
"paths":{"type":"array","items":{"type":"string"},"description":"Files to stage before committing"},
"all":{"type":"boolean","description":"Stage all changes to tracked files"}
},"required":["message"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Message string   `json:"message"`
			Paths   []string `json:"paths"`
			All     bool     `json:"all"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		if strings.TrimSpace(a.Message) == "" {
			return errorf("message is empty")
		}
		if len(a.Paths) > 0 {
			add := []string{"add", "--"}
			for _, p := range a.Paths {
				abs, err := resolve(env.Dir, p)
				if err != nil {
					return errorf("%v", err)
				}
				add = append(add, abs)
			}
			if out, err := git(ctx, env.Dir, add...); err != nil {
				return gitResult(out, err)
			}
		}
		args := []string{"commit", "-m", a.Message}
		if a.All {
			args = append(args, "--all")
		}
		return gitResult(git(ctx, env.Dir, args...))
	},
}
