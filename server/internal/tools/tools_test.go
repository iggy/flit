package tools

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

func newEnv(t *testing.T) *Env {
	t.Helper()
	dir := t.TempDir()
	return &Env{Dir: dir, Shell: config.Default().Shell}
}

func run(t *testing.T, env *Env, name string, args any) Result {
	t.Helper()
	b, err := json.Marshal(args)
	if err != nil {
		t.Fatal(err)
	}
	return Run(context.Background(), env, name, string(b))
}

func writeFixture(t *testing.T, env *Env, name, content string) {
	t.Helper()
	p := filepath.Join(env.Dir, name)
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestReadWrite(t *testing.T) {
	env := newEnv(t)
	if r := run(t, env, "write", map[string]any{"path": "sub/a.txt", "content": "one\ntwo\nthree\n"}); r.IsError {
		t.Fatal(r.Text)
	}
	r := run(t, env, "read", map[string]any{"path": "sub/a.txt", "offset": 2, "limit": 1})
	if r.IsError || !strings.Contains(r.Text, "     2\ttwo") || strings.Contains(r.Text, "one") || !strings.Contains(r.Text, "offset 3") {
		t.Fatalf("read = %+v", r)
	}
	if r := run(t, env, "read", map[string]any{"path": "missing.txt"}); !r.IsError {
		t.Fatal("reading a missing file should fail")
	}
	writeFixture(t, env, "bin", "a\x00b")
	if r := run(t, env, "read", map[string]any{"path": "bin"}); !r.IsError {
		t.Fatal("reading a binary file should fail")
	}
	if r := run(t, env, "read", map[string]any{"path": "a", "bogus": 1}); !r.IsError || !strings.Contains(r.Text, "bogus") {
		t.Fatalf("unknown argument: %+v", r)
	}
	if r := Run(context.Background(), env, "read", "{not json"); !r.IsError {
		t.Fatal("invalid JSON should fail")
	}
	if r := Run(context.Background(), env, "nope", "{}"); !r.IsError {
		t.Fatal("unknown tool should fail")
	}
}

func TestPathsStayInWorkingDir(t *testing.T) {
	env := newEnv(t)
	outside := t.TempDir()
	for _, p := range []string{"../x", filepath.Join(outside, "x"), "a/../../x"} {
		if r := run(t, env, "write", map[string]any{"path": p, "content": "x"}); !r.IsError {
			t.Errorf("write %s succeeded", p)
		}
	}
	if runtime.GOOS != "windows" {
		if err := os.Symlink(outside, filepath.Join(env.Dir, "link")); err != nil {
			t.Fatal(err)
		}
		if r := run(t, env, "write", map[string]any{"path": "link/x", "content": "x"}); !r.IsError {
			t.Error("write through a symlink out of the working dir succeeded")
		}
		if _, err := os.Stat(filepath.Join(outside, "x")); err == nil {
			t.Error("file was written outside the working dir")
		}
	}
}

func TestPatch(t *testing.T) {
	env := newEnv(t)
	writeFixture(t, env, "f.go", "a := 1\nb := 1\nc := 2\n")

	r := run(t, env, "patch", map[string]any{"path": "f.go", "edits": []any{
		map[string]any{"old_string": "c := 2", "new_string": "c := 3"},
		map[string]any{"old_string": " 1", "new_string": " 9", "replace_all": true},
	}})
	if r.IsError {
		t.Fatal(r.Text)
	}
	b, _ := os.ReadFile(filepath.Join(env.Dir, "f.go"))
	if string(b) != "a := 9\nb := 9\nc := 3\n" {
		t.Fatalf("patched = %q", b)
	}

	// Ambiguous and missing matches fail without changing the file.
	for _, edits := range [][]any{
		{map[string]any{"old_string": "c := 3", "new_string": "c := 4"}, map[string]any{"old_string": " 9", "new_string": " 0"}},
		{map[string]any{"old_string": "c := 3", "new_string": "c := 4"}, map[string]any{"old_string": "zzz", "new_string": "y"}},
		{map[string]any{"old_string": "", "new_string": "y"}},
	} {
		if r := run(t, env, "patch", map[string]any{"path": "f.go", "edits": edits}); !r.IsError {
			t.Fatalf("patch %v succeeded", edits)
		}
	}
	if b2, _ := os.ReadFile(filepath.Join(env.Dir, "f.go")); string(b2) != string(b) {
		t.Fatalf("failed patch changed the file: %q", b2)
	}
}

func TestListAndGrep(t *testing.T) {
	env := newEnv(t)
	writeFixture(t, env, "main.go", "package main\nfunc main() { Hello() }\n")
	writeFixture(t, env, "lib/hello.go", "package lib\nfunc Hello() {}\n")
	writeFixture(t, env, "lib/deep/x.txt", "hello world\n")
	writeFixture(t, env, ".git/config", "Hello\n")

	r := run(t, env, "list", map[string]any{})
	if r.IsError || r.Text != "lib/\nmain.go" {
		t.Fatalf("list = %q", r.Text)
	}
	r = run(t, env, "list", map[string]any{"depth": 3})
	if !strings.Contains(r.Text, "lib/deep/x.txt") || strings.Contains(r.Text, ".git") {
		t.Fatalf("list depth 3 = %q", r.Text)
	}

	r = run(t, env, "grep", map[string]any{"pattern": "Hello", "glob": "*.go"})
	if r.IsError || !strings.Contains(r.Text, "lib/hello.go:2: func Hello() {}") || !strings.Contains(r.Text, "main.go:2:") ||
		strings.Contains(r.Text, ".git") || strings.Contains(r.Text, "x.txt") {
		t.Fatalf("grep = %q", r.Text)
	}
	r = run(t, env, "grep", map[string]any{"pattern": "HELLO WORLD", "ignore_case": true})
	if !strings.Contains(r.Text, "lib/deep/x.txt:1:") {
		t.Fatalf("grep -i = %q", r.Text)
	}
	if r := run(t, env, "grep", map[string]any{"pattern": "nothing-here"}); r.Text != "no matches" {
		t.Fatalf("grep none = %q", r.Text)
	}
	if r := run(t, env, "grep", map[string]any{"pattern": "("}); !r.IsError {
		t.Fatal("bad regexp should fail")
	}
}

func TestShell(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("uses sh syntax")
	}
	env := newEnv(t)
	env.Shell.Default = "allow"
	var live strings.Builder
	env.Output = func(s string) { live.WriteString(s) }

	r := run(t, env, "shell", map[string]any{"command": "echo out; echo err >&2; exit 3"})
	if !r.IsError || !strings.Contains(r.Text, "out\n") || !strings.Contains(r.Text, "err\n") || !strings.Contains(r.Text, "[exit code 3]") {
		t.Fatalf("shell = %+v", r)
	}
	if !strings.Contains(live.String(), "out") {
		t.Fatalf("live output = %q", live.String())
	}

	writeFixture(t, env, "sub/f", "")
	if r := run(t, env, "shell", map[string]any{"command": "ls", "workdir": "sub"}); r.IsError || !strings.HasPrefix(r.Text, "f\n") {
		t.Fatalf("workdir: %+v", r)
	}

	start := time.Now()
	r = run(t, env, "shell", map[string]any{"command": "sleep 30 & sleep 30", "timeout_seconds": 1})
	if !strings.Contains(r.Text, "timed out") || time.Since(start) > 10*time.Second {
		t.Fatalf("timeout: %+v after %s", r, time.Since(start))
	}
}

func TestShellInterrupt(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("uses sh syntax")
	}
	env := newEnv(t)
	env.Shell.Default = "allow"
	ctx, cancel := context.WithCancel(context.Background())
	time.AfterFunc(300*time.Millisecond, cancel)
	start := time.Now()
	r := Run(ctx, env, "shell", `{"command":"sleep 30"}`)
	if !strings.Contains(r.Text, "[interrupted]") || time.Since(start) > 10*time.Second {
		t.Fatalf("interrupt: %+v after %s", r, time.Since(start))
	}
}

func TestShellApproval(t *testing.T) {
	env := newEnv(t)
	env.Shell = config.Shell{Default: "ask", Allow: []string{"echo allowed*"}, Deny: []string{"rm -rf *"},
		Timeout: time.Minute, MaxTimeout: time.Minute}
	var asked []string
	answer := false
	env.Approve = func(_ context.Context, title, detail string) (bool, error) {
		asked = append(asked, detail)
		return answer, nil
	}

	if r := run(t, env, "shell", map[string]any{"command": "echo allowed"}); r.IsError || len(asked) != 0 {
		t.Fatalf("allowed command: %+v, asked %q", r, asked)
	}
	if r := run(t, env, "shell", map[string]any{"command": "echo hi"}); !r.IsError || !strings.Contains(r.Text, "denied") || len(asked) != 1 {
		t.Fatalf("denied by user: %+v, asked %q", r, asked)
	}
	answer = true
	if r := run(t, env, "shell", map[string]any{"command": "echo hi"}); r.IsError || len(asked) != 2 {
		t.Fatalf("approved: %+v", r)
	}
	if r := run(t, env, "shell", map[string]any{"command": "echo x && rm -rf /tmp/nothing"}); !r.IsError || len(asked) != 2 {
		t.Fatalf("deny rule: %+v, asked %q", r, asked)
	}
}

func TestShellDecision(t *testing.T) {
	sh := config.Shell{Allow: []string{"ls*", "go test*"}, Deny: []string{"sudo *"}, Default: "ask"}
	for cmd, want := range map[string]Decision{
		"ls -la":              Allow,
		"go test ./...":       Allow,
		"ls; rm -rf x":        Ask,
		"ls $(whoami)":        Ask,
		"ls > out":            Ask,
		"sudo reboot":         Deny,
		"ls && sudo reboot":   Deny,
		"make":                Ask,
		"  ls  ":              Allow,
		"lsof | grep x":       Ask,
		"echo hi\nsudo x":     Deny,
		"cat file | sudo tee": Deny,
	} {
		if got := ShellDecision(cmd, sh); got != want {
			t.Errorf("%q: got %v, want %v", cmd, got, want)
		}
	}
	sh.Default = "deny"
	if ShellDecision("make", sh) != Deny {
		t.Error("default deny not applied")
	}
}

func TestTruncate(t *testing.T) {
	if out, _, cut := Truncate("short", 100, 10); cut || out != "short" {
		t.Fatal("short input changed")
	}

	var lines []string
	for i := range 100 {
		lines = append(lines, strings.Repeat("x", 9)+string(rune('a'+i%26)))
	}
	s := strings.Join(lines, "\n") + "\n"

	out, omitted, cut := Truncate(s, 0, 10)
	if !cut || !strings.HasPrefix(out, lines[0]+"\n") || !strings.HasSuffix(out, lines[99]+"\n") {
		t.Fatalf("by lines: %q", out)
	}
	if strings.Count(out, "\n") > 12 || !strings.Contains(out, "90 lines omitted") || omitted != int64(90*11) {
		t.Fatalf("by lines: omitted=%d out=%q", omitted, out)
	}

	out, _, cut = Truncate(s, 200, 0)
	if !cut || len(out) > 300 || !strings.HasPrefix(out, lines[0]) || !strings.HasSuffix(out, lines[99]+"\n") {
		t.Fatalf("by bytes: %d bytes %q", len(out), out)
	}

	// Never splits a UTF-8 character.
	u := strings.Repeat("é", 1000)
	out, _, _ = Truncate(u, 101, 0)
	if !strings.HasPrefix(out, "éé") || strings.ContainsRune(out, '�') {
		t.Fatalf("utf8: %q", out[:20])
	}
	for _, r := range out {
		if r == '�' {
			t.Fatal("invalid UTF-8 in output")
		}
	}
}
