package memory

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestItems(t *testing.T) {
	content := "# Memory\n\nIntro text.\n\n- one\n  more of one\n\n- two\n* three\nnot an item\n- four\n"
	got := Items(content)
	want := []string{"- one\n  more of one", "- two", "* three", "- four"}
	if len(got) != len(want) {
		t.Fatalf("items = %q", got)
	}
	for i := range want {
		if got[i].Text != want[i] {
			t.Errorf("item %d = %q, want %q", i, got[i].Text, want[i])
		}
	}
}

func TestRender(t *testing.T) {
	e := Entry{Cue: "When running tests:", Lesson: "use  go test\n./...", Evidence: "ses_1 T2"}
	if got, want := e.Render(), "- **When running tests:** use go test ./... _(evidence: ses_1 T2)_"; got != want {
		t.Fatalf("Render = %q, want %q", got, want)
	}
	if got := (Entry{Lesson: "x"}).Render(); got != "- x" {
		t.Fatalf("Render = %q", got)
	}
}

func TestApply(t *testing.T) {
	path := filepath.Join(t.TempDir(), "memory", "user.md")
	read := func() string {
		b, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		return string(b)
	}
	if err := Apply(path, Change{Action: "add", New: "- a", Header: Header(User, "")}); err != nil {
		t.Fatal(err)
	}
	if got := read(); !strings.HasPrefix(got, "# User memory") || !strings.HasSuffix(got, ".\n\n- a\n") {
		t.Fatalf("after first add:\n%s", got)
	}
	if err := Apply(path, Change{Action: "add", New: "- b"}); err != nil {
		t.Fatal(err)
	}
	if got := read(); !strings.HasSuffix(got, "\n- a\n- b\n") {
		t.Fatalf("after second add:\n%s", got)
	}
	if err := Apply(path, Change{Action: "update", Old: "- a", New: "- A"}); err != nil {
		t.Fatal(err)
	}
	if err := Apply(path, Change{Action: "remove", Old: "- b"}); err != nil {
		t.Fatal(err)
	}
	if got := read(); !strings.HasSuffix(got, "\n- A\n") || strings.Contains(got, "- b") {
		t.Fatalf("after update and remove:\n%s", got)
	}
	if err := Apply(path, Change{Action: "remove", Old: "- gone"}); !errors.Is(err, ErrChanged) {
		t.Fatalf("remove of a missing entry: %v", err)
	}
}

func TestReadCapped(t *testing.T) {
	path := filepath.Join(t.TempDir(), "m.md")
	if got, cut, err := ReadCapped(path, 10); got != "" || cut != 0 || err != nil {
		t.Fatalf("missing file: %q %d %v", got, cut, err)
	}
	content := "- first line\n- second line\n- third line\n"
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	got, cut, err := ReadCapped(path, 30)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(got, "- first line\n- second line\n[... ") || cut != len("\n- third line") {
		t.Fatalf("capped = %q (cut %d)", got, cut)
	}
	if got, _, _ := ReadCapped(path, 0); got != strings.TrimSpace(content) {
		t.Fatalf("uncapped = %q", got)
	}
}

func TestProjectPathIsSafe(t *testing.T) {
	if got := ProjectPath("/data", "../../etc/passwd"); filepath.Dir(got) != "/data/memory/projects" {
		t.Fatalf("ProjectPath = %s", got)
	}
}
