package tools

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// grepImpls runs f once with ripgrep (skipped when rg isn't installed) and
// once with the pure-Go search.
func grepImpls(t *testing.T, f func(t *testing.T)) {
	t.Helper()
	orig := rgPath
	t.Cleanup(func() { rgPath = orig })
	t.Run("ripgrep", func(t *testing.T) {
		p, err := exec.LookPath("rg")
		if err != nil {
			t.Skip("rg not installed")
		}
		rgPath = func() string { return p }
		f(t)
	})
	t.Run("go", func(t *testing.T) {
		rgPath = func() string { return "" }
		f(t)
	})
}

func TestGrep(t *testing.T) {
	grepImpls(t, func(t *testing.T) {
		env := newEnv(t)
		writeFixture(t, env, "main.go", "package main\nfunc main() { Hello() }\n")
		writeFixture(t, env, "lib/hello.go", "package lib\nfunc Hello() {}\n")
		writeFixture(t, env, "lib/deep/x.txt", "hello world\r\n")
		writeFixture(t, env, ".git/config", "Hello\n")
		writeFixture(t, env, "node_modules/m/index.go", "Hello\n")
		writeFixture(t, env, ".hidden.go", "// Hello\n")
		writeFixture(t, env, "bin.go", "Hello\x00\n")
		writeFixture(t, env, "long.txt", "Hello "+strings.Repeat("x", 400)+"\n")

		r := run(t, env, "grep", map[string]any{"pattern": "Hello", "glob": "*.go"})
		want := ".hidden.go:1: // Hello\nlib/hello.go:2: func Hello() {}\nmain.go:2: func main() { Hello() }\n"
		if r.IsError || r.Text != want {
			t.Fatalf("grep = %q, want %q", r.Text, want)
		}
		r = run(t, env, "grep", map[string]any{"pattern": "HELLO WORLD", "ignore_case": true})
		if r.Text != "lib/deep/x.txt:1: hello world\n" {
			t.Fatalf("grep -i = %q", r.Text)
		}
		r = run(t, env, "grep", map[string]any{"pattern": "Hello", "path": "lib/hello.go"})
		if r.Text != "lib/hello.go:2: func Hello() {}\n" {
			t.Fatalf("grep one file = %q", r.Text)
		}
		r = run(t, env, "grep", map[string]any{"pattern": "Hello x", "path": "long.txt"})
		if !strings.HasPrefix(r.Text, "long.txt:1: Hello xxx") || !strings.HasSuffix(r.Text, "x…\n") {
			t.Fatalf("long line = %q", r.Text)
		}
		if r := run(t, env, "grep", map[string]any{"pattern": "nothing-here"}); r.Text != "no matches" {
			t.Fatalf("grep none = %q", r.Text)
		}
		if r := run(t, env, "grep", map[string]any{"pattern": "("}); !r.IsError {
			t.Fatal("bad regexp should fail")
		}
		if r := run(t, env, "grep", map[string]any{"pattern": "x", "path": "../"}); !r.IsError {
			t.Fatal("path outside the working directory should fail")
		}
	})
}

func TestGrepStopsAtLimit(t *testing.T) {
	grepImpls(t, func(t *testing.T) {
		env := newEnv(t)
		var b strings.Builder
		for i := range grepMaxMatches + 50 {
			fmt.Fprintf(&b, "match %d\n", i)
		}
		writeFixture(t, env, "many.txt", b.String())
		r := run(t, env, "grep", map[string]any{"pattern": "match"})
		lines := strings.Split(strings.TrimSuffix(r.Text, "\n"), "\n")
		if len(lines) != grepMaxMatches+1 || !strings.HasPrefix(lines[grepMaxMatches], "[stopped after") {
			t.Fatalf("got %d lines, last %q", len(lines), lines[len(lines)-1])
		}
	})
}

// Only ripgrep reads .gitignore; the fallback searches everything.
func TestGrepGitignore(t *testing.T) {
	p, err := exec.LookPath("rg")
	if err != nil {
		t.Skip("rg not installed")
	}
	orig := rgPath
	t.Cleanup(func() { rgPath = orig })
	rgPath = func() string { return p }
	env := newEnv(t)
	if out, err := exec.Command("git", "init", "-q", env.Dir).CombinedOutput(); err != nil {
		t.Skipf("git init: %v %s", err, out)
	}
	writeFixture(t, env, ".gitignore", "build/\n")
	writeFixture(t, env, "src.txt", "needle\n")
	writeFixture(t, env, "build/out.txt", "needle\n")
	if r := run(t, env, "grep", map[string]any{"pattern": "needle"}); r.Text != "src.txt:1: needle\n" {
		t.Fatalf("grep = %q", r.Text)
	}
}

// A pattern RE2 accepts but ripgrep rejects falls back to the Go search.
func TestGrepFallsBackWhenRipgrepFails(t *testing.T) {
	orig := rgPath
	t.Cleanup(func() { rgPath = orig })
	if runtime.GOOS == "windows" {
		t.Skip("uses a shell script as a fake rg")
	}
	fake := filepath.Join(t.TempDir(), "rg")
	if err := os.WriteFile(fake, []byte("#!/bin/sh\necho 'regex parse error' >&2\nexit 2\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	rgPath = func() string { return fake }
	env := newEnv(t)
	writeFixture(t, env, "a.txt", "needle\n")
	if r := run(t, env, "grep", map[string]any{"pattern": "needle"}); r.Text != "a.txt:1: needle\n" {
		t.Fatalf("grep = %q", r.Text)
	}
}
