package tools

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestReadBeforeWrite(t *testing.T) {
	env := newEnv(t)
	env.Files = NewFileTracker()
	writeFixture(t, env, "a.txt", "one\ntwo\n")
	patch := func(old, new string) Result {
		return run(t, env, "patch", map[string]any{"path": "a.txt", "edits": []map[string]any{{"old_string": old, "new_string": new}}})
	}

	// Not read yet: patch and overwriting are refused, the file untouched.
	if r := patch("one", "uno"); !r.IsError || !strings.Contains(r.Text, "read the file first") {
		t.Fatalf("patch unread = %+v", r)
	}
	if r := run(t, env, "write", map[string]any{"path": "a.txt", "content": "x"}); !r.IsError || !strings.Contains(r.Text, "read the file first") {
		t.Fatalf("write unread = %+v", r)
	}
	if b, _ := os.ReadFile(filepath.Join(env.Dir, "a.txt")); string(b) != "one\ntwo\n" {
		t.Fatalf("file changed: %q", b)
	}

	// A new file needs no read.
	if r := run(t, env, "write", map[string]any{"path": "new/b.txt", "content": "b"}); r.IsError {
		t.Fatal(r.Text)
	}
	// ...and the agent's own write counts as knowing it.
	if r := run(t, env, "patch", map[string]any{"path": "new/b.txt", "edits": []map[string]any{{"old_string": "b", "new_string": "c"}}}); r.IsError {
		t.Fatal(r.Text)
	}

	// Read, then consecutive edits work (even a partial read counts).
	if r := run(t, env, "read", map[string]any{"path": "a.txt", "limit": 1}); r.IsError {
		t.Fatal(r.Text)
	}
	if r := patch("one", "uno"); r.IsError {
		t.Fatal(r.Text)
	}
	if r := patch("two", "dos"); r.IsError {
		t.Fatal(r.Text)
	}
	if r := run(t, env, "write", map[string]any{"path": "a.txt", "content": "uno\ndos\ntres\n"}); r.IsError {
		t.Fatal(r.Text)
	}

	// Changed behind the agent's back: read it again.
	time.Sleep(10 * time.Millisecond)
	writeFixture(t, env, "a.txt", "changed\n")
	if r := patch("changed", "x"); !r.IsError || !strings.Contains(r.Text, "changed since you last read it") {
		t.Fatalf("patch stale = %+v", r)
	}
	if r := run(t, env, "write", map[string]any{"path": "a.txt", "content": "x"}); !r.IsError || !strings.Contains(r.Text, "read it again") {
		t.Fatalf("write stale = %+v", r)
	}
	run(t, env, "read", map[string]any{"path": "a.txt"})
	if r := patch("changed", "x"); r.IsError {
		t.Fatal(r.Text)
	}

	// Without a tracker (agent.read_before_write: false) nothing is checked.
	env.Files = nil
	writeFixture(t, env, "c.txt", "c")
	if r := run(t, env, "patch", map[string]any{"path": "c.txt", "edits": []map[string]any{{"old_string": "c", "new_string": "d"}}}); r.IsError {
		t.Fatal(r.Text)
	}
}

func TestReadDirs(t *testing.T) {
	env := newEnv(t)
	extra := t.TempDir()
	saved := filepath.Join(extra, "out.txt")
	if err := os.WriteFile(saved, []byte("alpha\nbeta\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	other := filepath.Join(t.TempDir(), "secret.txt")
	if err := os.WriteFile(other, []byte("no"), 0o600); err != nil {
		t.Fatal(err)
	}

	if r := run(t, env, "read", map[string]any{"path": saved}); !r.IsError {
		t.Fatalf("read outside without ReadDirs = %+v", r)
	}
	env.ReadDirs = []string{extra}
	if r := run(t, env, "read", map[string]any{"path": saved, "offset": 2}); r.IsError || !strings.Contains(r.Text, "beta") {
		t.Fatalf("read saved = %+v", r)
	}
	if r := run(t, env, "grep", map[string]any{"pattern": "alp", "path": saved}); r.IsError || !strings.Contains(r.Text, saved+":1: alpha") {
		t.Fatalf("grep saved = %+v", r)
	}
	if r := run(t, env, "read", map[string]any{"path": other}); !r.IsError {
		t.Fatalf("read elsewhere = %+v", r)
	}
	if r := run(t, env, "read", map[string]any{"path": filepath.Join(extra, "..", filepath.Base(filepath.Dir(other)), "secret.txt")}); !r.IsError {
		t.Fatalf("read via .. = %+v", r)
	}
	// Writing there is still refused.
	if r := run(t, env, "write", map[string]any{"path": filepath.Join(extra, "x.txt"), "content": "x"}); !r.IsError {
		t.Fatalf("write to ReadDirs = %+v", r)
	}
}

func TestTruncateSaved(t *testing.T) {
	s := strings.Repeat("line\n", 100)
	out, _, cut := TruncateSaved(s, 0, 10, "/data/x.txt")
	if !cut || !strings.Contains(out, "full output is saved in /data/x.txt") {
		t.Fatalf("out = %q", out)
	}
	if out, _, cut := TruncateSaved("short", 0, 10, "/data/x.txt"); cut || out != "short" {
		t.Fatalf("short = %q", out)
	}
}
