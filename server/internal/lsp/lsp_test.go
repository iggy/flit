package lsp

import (
	"context"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

type fixture struct {
	m   *Manager
	cfg atomic.Pointer[config.Config]
	log string // the fake server's log
}

// newFixture returns a Manager whose only server is the fake one, for .fk
// files, with root marker fake.mod.
func newFixture(t *testing.T, edit func(*config.LSP)) *fixture {
	t.Helper()
	f := &fixture{log: filepath.Join(t.TempDir(), "fake.log")}
	cfg := config.Default()
	cfg.LSP.WaitTimeout = 5 * time.Second
	cfg.LSP.Debounce = 50 * time.Millisecond
	cfg.LSP.Servers = []config.LSPServer{{
		Name: "fake", Command: os.Args[0],
		Env:         map[string]string{"FLIT_FAKE_LSP": "1", "FLIT_FAKE_LSP_LOG": f.log},
		Languages:   map[string][]string{"fake": {".fk"}},
		RootMarkers: []string{"fake.mod"},
	}}
	if edit != nil {
		edit(&cfg.LSP)
	}
	f.cfg.Store(&cfg)
	f.m = New(func() config.Config { return *f.cfg.Load() }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	t.Cleanup(f.m.Close)
	return f
}

// project makes a directory with a root marker and a file in a subdirectory.
func project(t *testing.T, name, text string) (root, file string) {
	t.Helper()
	root = t.TempDir()
	write(t, filepath.Join(root, "fake.mod"), "")
	file = filepath.Join(root, "pkg", name)
	write(t, file, text)
	return root, file
}

func write(t *testing.T, p, text string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
}

func eventually(t *testing.T, what string, cond func() bool) {
	t.Helper()
	for deadline := time.Now().Add(5 * time.Second); time.Now().Before(deadline); time.Sleep(10 * time.Millisecond) {
		if cond() {
			return
		}
	}
	t.Fatalf("timed out waiting for %s", what)
}

func TestDiagnose(t *testing.T) {
	f := newFixture(t, nil)
	root, file := project(t, "a.fk", "ok\nHINT spelling\nWARN unused x\nERR undefined: y\nmulti\nERR second\nline two\n")
	got := f.m.Checker(root)(context.Background(), file)
	want := "Diagnostics:\n" +
		"pkg/a.fk:4:1 error: undefined: y\n" +
		"pkg/a.fk:6:1 error: second\n" +
		"pkg/a.fk:3:1 warning: unused x"
	if got != want {
		t.Fatalf("got\n%s\nwant\n%s", got, want)
	}

	clean := filepath.Join(root, "pkg", "clean.fk")
	write(t, clean, "fine\n")
	if got := f.m.Checker(root)(context.Background(), clean); got != "" {
		t.Fatalf("clean file: %q", got)
	}
	// Not a language anything handles.
	other := filepath.Join(root, "notes.txt")
	write(t, other, "ERR no\n")
	if got := f.m.Checker(root)(context.Background(), other); got != "" {
		t.Fatalf("txt file: %q", got)
	}
}

func TestSeverity(t *testing.T) {
	f := newFixture(t, func(l *config.LSP) { l.Severity = "error" })
	_, file := project(t, "a.fk", "WARN w\nERR e\n")
	d := f.m.Diagnose(context.Background(), filepath.Dir(file), file)
	if len(d) != 1 || d[0].Message != "e" || d[0].Line != 2 {
		t.Fatalf("got %+v", d)
	}
}

func TestDebounceWaitsForLastPublish(t *testing.T) {
	f := newFixture(t, func(l *config.LSP) { l.Debounce = 300 * time.Millisecond })
	_, file := project(t, "a.fk", "TWICE\nERR late\n")
	d := f.m.Diagnose(context.Background(), filepath.Dir(file), file)
	if len(d) != 1 || d[0].Message != "late" {
		t.Fatalf("got %+v", d)
	}
}

// One fake process serves every session and project; each project root
// joins it as a workspace folder.
func TestOneServerPerLanguage(t *testing.T) {
	f := newFixture(t, nil)
	rootA, fileA := project(t, "a.fk", "ERR in a\n")
	rootB, fileB := project(t, "b.fk", "ERR in b\n")
	// Three sessions: two in project A (one in a subdirectory), one in B.
	sessions := []struct{ dir, file, want string }{
		{rootA, fileA, "in a"},
		{filepath.Join(rootA, "pkg"), fileA, "in a"},
		{rootB, fileB, "in b"},
	}
	var wg sync.WaitGroup
	for range 3 {
		for _, s := range sessions {
			wg.Go(func() {
				d := f.m.Diagnose(context.Background(), s.dir, s.file)
				if len(d) != 1 || d[0].Message != s.want {
					t.Errorf("%s: got %+v", s.file, d)
				}
			})
		}
	}
	wg.Wait()
	if starts := fakeLines(t, f.log, "start"); len(starts) != 1 {
		t.Fatalf("started %d servers, want 1: %v", len(starts), starts)
	}
	folders := fakeLines(t, f.log, "folder")
	if len(folders) != 2 || !containsPath(folders, rootA) || !containsPath(folders, rootB) {
		t.Fatalf("folders %v, want %s and %s", folders, rootA, rootB)
	}
	if r := f.m.Running(); len(r) != 1 || r[0] != "fake" {
		t.Fatalf("running %v", r)
	}
}

func containsPath(list []string, p string) bool {
	for _, l := range list {
		if filepath.Clean(l) == filepath.Clean(p) {
			return true
		}
	}
	return false
}

func TestIdleServerStopsAndRestarts(t *testing.T) {
	f := newFixture(t, func(l *config.LSP) { l.IdleTimeout = 200 * time.Millisecond })
	_, file := project(t, "a.fk", "ERR x\n")
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); len(d) != 1 {
		t.Fatalf("got %+v", d)
	}
	eventually(t, "the idle server to stop", func() bool { return len(f.m.Running()) == 0 })
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); len(d) != 1 {
		t.Fatalf("after restart got %+v", d)
	}
	if starts := fakeLines(t, f.log, "start"); len(starts) != 2 {
		t.Fatalf("starts %v, want 2", starts)
	}
}

func TestCrashedServerIsReaped(t *testing.T) {
	f := newFixture(t, nil)
	_, bad := project(t, "a.fk", "CRASH\n")
	if d := f.m.Diagnose(context.Background(), filepath.Dir(bad), bad); d != nil {
		t.Fatalf("got %+v", d)
	}
	eventually(t, "the crashed server to be forgotten", func() bool { return len(f.m.Running()) == 0 })
	_, good := project(t, "b.fk", "ERR fine\n")
	if d := f.m.Diagnose(context.Background(), filepath.Dir(good), good); len(d) != 1 {
		t.Fatalf("after crash got %+v", d)
	}
}

func TestSlowServerDoesNotBlock(t *testing.T) {
	f := newFixture(t, func(l *config.LSP) { l.WaitTimeout = 300 * time.Millisecond })
	_, file := project(t, "a.fk", "SLOW\nERR x\n")
	start := time.Now()
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); d != nil {
		t.Fatalf("got %+v", d)
	}
	if el := time.Since(start); el > 2*time.Second {
		t.Fatalf("took %v", el)
	}
}

func TestMissingServerAndDisabled(t *testing.T) {
	f := newFixture(t, func(l *config.LSP) { l.Servers[0].Command = "flit-no-such-language-server" })
	_, file := project(t, "a.fk", "ERR x\n")
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); d != nil {
		t.Fatalf("got %+v", d)
	}
	f = newFixture(t, func(l *config.LSP) { l.Enabled = new(false) })
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); d != nil || len(f.m.Running()) != 0 {
		t.Fatalf("disabled: got %+v", d)
	}
}

func TestConfigChangeRestarts(t *testing.T) {
	f := newFixture(t, nil)
	_, file := project(t, "a.fk", "ERR x\n")
	f.m.Diagnose(context.Background(), filepath.Dir(file), file)
	next := *f.cfg.Load()
	next.LSP.Servers = []config.LSPServer{next.LSP.Servers[0]}
	next.LSP.Servers[0].Args = []string{"-test.run=none"}
	f.cfg.Store(&next)
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); len(d) != 1 {
		t.Fatalf("got %+v", d)
	}
	pids := fakeLines(t, f.log, "start")
	if len(pids) != 2 {
		t.Fatalf("starts %v, want 2", pids)
	}
	eventually(t, "the old server to exit", func() bool { return !alive(pids[0]) })
}

func TestCloseStopsServers(t *testing.T) {
	f := newFixture(t, nil)
	_, file := project(t, "a.fk", "SPAWN\nERR x\n")
	f.m.Diagnose(context.Background(), filepath.Dir(file), file)
	pids := append(fakeLines(t, f.log, "start"), fakeLines(t, f.log, "child")...)
	if len(pids) != 2 {
		t.Fatalf("pids %v", pids)
	}
	if runtime.GOOS == "windows" {
		pids = pids[:1] // no process groups there; see proc_windows.go
	}
	f.m.Close()
	for _, p := range pids {
		eventually(t, "process "+p+" to exit", func() bool { return !alive(p) })
	}
	if d := f.m.Diagnose(context.Background(), filepath.Dir(file), file); d != nil {
		t.Fatal("diagnosed after Close")
	}
}

func TestFormat(t *testing.T) {
	if Format("a.go", nil, 10) != "" {
		t.Fatal("no diagnostics should format to nothing")
	}
	var ds []Diagnostic
	for i := range 13 {
		ds = append(ds, Diagnostic{Line: i + 1, Col: 2, Severity: SeverityError, Message: "bad\n  detail"})
	}
	got := Format("a.go", ds, 10)
	lines := strings.Split(got, "\n")
	if len(lines) != 12 || lines[1] != "a.go:1:2 error: bad" || lines[11] != "(+3 more)" {
		t.Fatalf("got\n%s", got)
	}
}

func TestPick(t *testing.T) {
	found := func(cmds ...string) func(string) (string, error) {
		return func(c string) (string, error) {
			for _, x := range cmds {
				if x == c {
					return "/bin/" + c, nil
				}
			}
			return "", exec.ErrNotFound
		}
	}
	cfg := config.Default().LSP
	if s, lang, ok := pick(cfg, "/x/main.go", found("gopls")); !ok || s.Name != "gopls" || lang != "go" {
		t.Fatalf("go: %v %v %v", s.Name, lang, ok)
	}
	if _, _, ok := pick(cfg, "/x/main.go", found()); ok {
		t.Fatal("picked a server that isn't installed")
	}
	if s, _, _ := pick(cfg, "/x/a.py", found("pyright-langserver")); s.Name != "pyright" {
		t.Fatalf("python fell back to %q", s.Name)
	}
	if s, _, _ := pick(cfg, "/x/a.py", found("pyright-langserver", "basedpyright-langserver")); s.Name != "basedpyright" {
		t.Fatalf("python picked %q", s.Name)
	}
	if _, lang, _ := pick(cfg, "/x/App.TSX", found("typescript-language-server")); lang != "typescriptreact" {
		t.Fatalf("tsx language %q", lang)
	}
	cfg.Servers = []config.LSPServer{{Name: "gopls", Enabled: new(false)}}
	if _, _, ok := pick(cfg, "/x/main.go", found("gopls")); ok {
		t.Fatal("picked a server turned off")
	}
}

func TestFindRoot(t *testing.T) {
	root, file := project(t, "a.fk", "")
	if got := findRoot(file, "/elsewhere", []string{"fake.mod"}); got != root {
		t.Fatalf("got %s, want %s", got, root)
	}
	if got := findRoot(file, "/fallback", []string{"no.such.marker"}); got != "/fallback" {
		t.Fatalf("got %s", got)
	}
}

func TestURIRoundTrip(t *testing.T) {
	p := filepath.Join(t.TempDir(), "a dir", "ü#.go")
	if got, ok := uriPath(pathURI(p)); !ok || got != p {
		t.Fatalf("%s -> %s -> %s", p, pathURI(p), got)
	}
}
