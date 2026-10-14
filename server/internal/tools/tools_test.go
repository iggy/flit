package tools

import (
	"context"
	"encoding/json"
	"github.com/iggy/flit/server/internal/skills"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// testSet is every tool that needs no configuration.
var testSet = append(All(), GitTools()...)

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
	return Run(context.Background(), env, testSet, name, string(b))
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
	if r := Run(context.Background(), env, testSet, "read", "{not json"); !r.IsError {
		t.Fatal("invalid JSON should fail")
	}
	if r := Run(context.Background(), env, testSet, "nope", "{}"); !r.IsError {
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
	r := Run(ctx, env, testSet, "shell", `{"command":"sleep 30"}`)
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
	env.Approve = func(_ context.Context, title, detail string, _ []string) (bool, error) {
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

func TestTodo(t *testing.T) {
	env := newEnv(t)
	var got []TodoItem
	env.Todo = func(items []TodoItem) { got = items }
	r := run(t, env, "todo", map[string]any{"items": []any{
		map[string]any{"content": " write tests ", "status": "completed"},
		map[string]any{"content": "fix bug", "status": "in_progress"},
		map[string]any{"content": "ship", "status": "pending"},
	}})
	if r.IsError || !strings.Contains(r.Text, "1 pending, 1 in progress, 1 completed") {
		t.Fatalf("todo = %+v", r)
	}
	if len(got) != 3 || got[0].Content != "write tests" || got[1].Status != "in_progress" {
		t.Fatalf("items = %+v", got)
	}
	if r := run(t, env, "todo", map[string]any{"items": []any{map[string]any{"content": "x", "status": "done"}}}); !r.IsError {
		t.Fatal("bad status accepted")
	}
	if r := run(t, env, "todo", map[string]any{"items": []any{map[string]any{"content": " ", "status": "pending"}}}); !r.IsError {
		t.Fatal("empty content accepted")
	}
}

func TestGit(t *testing.T) {
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("no git")
	}
	env := newEnv(t)
	for _, args := range [][]string{
		{"init", "-q", "-b", "main"},
		{"config", "user.email", "t@example.com"},
		{"config", "user.name", "Test"},
		{"config", "commit.gpgsign", "false"},
	} {
		if out, err := git(context.Background(), env.Dir, args...); err != nil {
			t.Fatalf("%v: %s", err, out)
		}
	}
	writeFixture(t, env, "a.txt", "one\n")

	if r := run(t, env, "git_status", map[string]any{}); r.IsError || !strings.Contains(r.Text, "?? a.txt") {
		t.Fatalf("status = %+v", r)
	}
	if r := run(t, env, "git_commit", map[string]any{"message": "first", "paths": []string{"a.txt"}}); r.IsError {
		t.Fatalf("commit = %+v", r)
	}
	writeFixture(t, env, "a.txt", "two\n")
	if r := run(t, env, "git_diff", map[string]any{}); r.IsError || !strings.Contains(r.Text, "+two") {
		t.Fatalf("diff = %+v", r)
	}
	if r := run(t, env, "git_commit", map[string]any{"message": "second", "all": true}); r.IsError {
		t.Fatalf("commit -a = %+v", r)
	}
	r := run(t, env, "git_log", map[string]any{"count": 5})
	if r.IsError || !strings.Contains(r.Text, "Test: second") || !strings.Contains(r.Text, "Test: first") {
		t.Fatalf("log = %+v", r)
	}
	if r := run(t, env, "git_diff", map[string]any{"ref": "--output=/tmp/x"}); !r.IsError {
		t.Fatal("option injection via ref accepted")
	}
	if r := run(t, env, "git_commit", map[string]any{"message": "nothing"}); !r.IsError {
		t.Fatal("empty commit succeeded")
	}
}

func TestWebFetch(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/page":
			w.Header().Set("Content-Type", "text/html; charset=utf-8")
			io.WriteString(w, `<html><head><title>T</title><style>x{}</style></head><body><nav>menu</nav>
<h1>Hello</h1><p>First <a href="https://go.dev">link</a>.</p><script>evil()</script><ul><li>one</li><li>two</li></ul></body></html>`)
		case "/data":
			w.Header().Set("Content-Type", "application/json")
			io.WriteString(w, `{"ok":true}`)
		case "/bin":
			w.Header().Set("Content-Type", "image/png")
			w.Write([]byte{0x89, 'P', 'N', 'G'})
		case "/search":
			if r.URL.Query().Get("format") != "json" {
				http.Error(w, "no", 403)
				return
			}
			io.WriteString(w, `{"results":[{"title":"Go","url":"https://go.dev","content":"The Go language"}]}`)
		}
	}))
	defer srv.Close()
	env := newEnv(t)
	set := []Tool{WebFetchTool(), WebSearchTool(srv.URL)}
	call := func(name string, args map[string]any) Result {
		b, _ := json.Marshal(args)
		return Run(context.Background(), env, set, name, string(b))
	}

	r := call("web_fetch", map[string]any{"url": srv.URL + "/page"})
	for _, want := range []string{"# Hello", "First link (https://go.dev) .", "- one", "- two"} {
		if !strings.Contains(r.Text, want) {
			t.Errorf("page text lacks %q:\n%s", want, r.Text)
		}
	}
	for _, unwanted := range []string{"evil", "menu", "x{}"} {
		if strings.Contains(r.Text, unwanted) {
			t.Errorf("page text has %q:\n%s", unwanted, r.Text)
		}
	}
	if r := call("web_fetch", map[string]any{"url": srv.URL + "/data"}); !strings.Contains(r.Text, `{"ok":true}`) {
		t.Errorf("json = %+v", r)
	}
	if r := call("web_fetch", map[string]any{"url": srv.URL + "/bin"}); !r.IsError {
		t.Error("binary fetched")
	}
	if r := call("web_fetch", map[string]any{"url": "file:///etc/passwd"}); !r.IsError {
		t.Error("file URL fetched")
	}
	if r := call("web_search", map[string]any{"query": "golang"}); r.IsError || !strings.Contains(r.Text, "1. Go\n   https://go.dev") {
		t.Errorf("search = %+v", r)
	}
}

func TestSkillTool(t *testing.T) {
	dir := t.TempDir()
	os.MkdirAll(filepath.Join(dir, "demo", "references"), 0o755)
	os.WriteFile(filepath.Join(dir, "demo", "SKILL.md"), []byte("---\nname: demo\ndescription: Demo skill.\n---\nDo the demo."), 0o644)
	os.WriteFile(filepath.Join(dir, "demo", "references", "REF.md"), []byte("deep detail"), 0o644)
	list, problems := skills.Load([]skills.Dir{{Path: dir, Source: "test"}})
	if len(problems) > 0 {
		t.Fatal(problems)
	}
	env := newEnv(t)
	set := []Tool{SkillTool(list)}
	call := func(args string) Result { return Run(context.Background(), env, set, "skill", args) }

	if r := call(`{"name":"demo"}`); r.IsError || !strings.Contains(r.Text, "Do the demo.") || !strings.Contains(r.Text, "- references/REF.md") {
		t.Fatalf("load = %+v", r)
	}
	if r := call(`{"name":"demo","file":"references/REF.md"}`); r.Text != "deep detail" {
		t.Fatalf("file = %+v", r)
	}
	if r := call(`{"name":"demo","file":"../../etc/passwd"}`); !r.IsError {
		t.Fatal("escaped the skill dir")
	}
	if r := call(`{"name":"nope"}`); !r.IsError {
		t.Fatal("unknown skill loaded")
	}
}

func TestSessionPatterns(t *testing.T) {
	for cmd, want := range map[string][]string{
		"go test ./...":                       {"go test *"},
		"cd /src/app && go test ./... -run X": {"go test *"},
		"CGO_ENABLED=0 go build ./cmd/flit":   {"go build *"},
		"git status":                          {"git status *"},
		"ls -la":                              {"ls *"},
		"./run.sh --fast":                     {"./run.sh *"},
		"npm run build && npm run test":       {"npm run *"},
		"go test ./... | tail -20":            {"go test *", "tail *"},
		"python3 script.py":                   {"python3 *"},
	} {
		got, ok := SessionPatterns(cmd)
		if !ok || strings.Join(got, ",") != strings.Join(want, ",") {
			t.Errorf("%q: got %v, %v; want %v", cmd, got, ok, want)
		}
	}
	for _, cmd := range []string{"go test > out.txt", "echo $(whoami)", "cat `x`", "cd /tmp", "FOO=1"} {
		if got, ok := SessionPatterns(cmd); ok {
			t.Errorf("%q: offered %v", cmd, got)
		}
	}

	sh := config.Shell{Default: "ask", Deny: []string{"git push*"}}
	session := []string{"go test *", "tail *", "git push *"}
	for cmd, want := range map[string]Decision{
		"go test ./...":             Allow,
		"cd x && go test ./pkg":     Allow,
		"go test ./... | tail -5":   Allow,
		"go test ./... | grep FAIL": Ask, // grep isn't allowed
		"go build ./...":            Ask,
		"go test ./... > log.txt":   Ask,  // redirection is never session-allowed
		"git push origin main":      Deny, // deny rules win
	} {
		if got := ShellDecisionWith(cmd, sh, session); got != want {
			t.Errorf("%q: got %v, want %v", cmd, got, want)
		}
	}
}
