package gitx_test

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/gitx"
)

// repo makes a git repository in a temp dir with one commit holding
// a.txt, and returns its path.
func repo(t *testing.T) string {
	t.Helper()
	dir := unborn(t)
	write(t, dir, "a.txt", "one\ntwo\n")
	run(t, dir, "add", "a.txt")
	run(t, dir, "commit", "-q", "-m", "first")
	return dir
}

// unborn makes a git repository with no commits.
func unborn(t *testing.T) string {
	t.Helper()
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	dir := t.TempDir()
	run(t, dir, "init", "-q", "-b", "main")
	run(t, dir, "config", "user.email", "test@example.com")
	run(t, dir, "config", "user.name", "Test")
	run(t, dir, "config", "commit.gpgsign", "false")
	run(t, dir, "config", "core.autocrlf", "false")
	return dir
}

func run(t *testing.T, dir string, args ...string) string {
	t.Helper()
	out, err := gitx.Run(context.Background(), dir, args...)
	if err != nil {
		t.Fatal(err)
	}
	return strings.TrimSpace(out)
}

func write(t *testing.T, dir, name, text string) {
	t.Helper()
	p := filepath.Join(dir, name)
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
}

func status(t *testing.T, dir, base string) *gitx.Status {
	t.Helper()
	st, err := gitx.GetStatus(context.Background(), dir, base, 0)
	if err != nil {
		t.Fatal(err)
	}
	return st
}

func diff(t *testing.T, dir, base, path string, limit int) *gitx.Diff {
	t.Helper()
	d, err := gitx.GetDiff(context.Background(), dir, base, path, limit)
	if err != nil {
		t.Fatal(err)
	}
	return d
}

func files(st *gitx.Status) map[string]gitx.File {
	m := map[string]gitx.File{}
	for _, f := range st.Files {
		m[f.Path] = f
	}
	return m
}

func TestNotARepo(t *testing.T) {
	dir := t.TempDir()
	if h, err := gitx.Head(context.Background(), dir); h != "" || err != nil {
		t.Fatalf("Head = %q, %v", h, err)
	}
	if st := status(t, dir, ""); st.IsRepo || len(st.Files) != 0 {
		t.Fatalf("status = %+v", st)
	}
	if d := diff(t, dir, "", "", 1000); d.IsRepo || d.Text != "" {
		t.Fatalf("diff = %+v", d)
	}
}

func TestDirtyAndUntracked(t *testing.T) {
	dir := repo(t)
	base := run(t, dir, "rev-parse", "HEAD")
	write(t, dir, "a.txt", "one\nTWO\nthree\n")
	write(t, dir, "staged.txt", "s\n")
	run(t, dir, "add", "staged.txt")
	write(t, dir, "sub/new.txt", "x\ny\n")
	indexBefore, _ := os.ReadFile(filepath.Join(dir, ".git", "index"))

	st := status(t, filepath.Join(dir, "sub"), base)
	if !st.IsRepo || st.Branch != "main" || st.Head != base || st.Detached {
		t.Fatalf("status = %+v", st)
	}
	if st.Staged != 1 || st.Unstaged != 1 || st.Untracked != 1 {
		t.Fatalf("counts staged %d unstaged %d untracked %d", st.Staged, st.Unstaged, st.Untracked)
	}
	if st.Base != (gitx.Base{Rev: base, Kind: gitx.BaseSession}) {
		t.Fatalf("base = %+v", st.Base)
	}
	fs := files(st)
	if len(fs) != 3 {
		t.Fatalf("files = %+v", st.Files)
	}
	if f := fs["a.txt"]; f.Status != gitx.FileModified || f.Additions != 2 || f.Deletions != 1 || !f.Unstaged || f.Staged {
		t.Errorf("a.txt = %+v", f)
	}
	if f := fs["staged.txt"]; f.Status != gitx.FileAdded || f.Additions != 1 || !f.Staged {
		t.Errorf("staged.txt = %+v", f)
	}
	if f := fs["sub/new.txt"]; f.Status != gitx.FileAdded || f.Additions != 2 || !f.Untracked {
		t.Errorf("sub/new.txt = %+v", f)
	}

	d := diff(t, dir, base, "", 1<<20)
	for _, want := range []string{"+TWO", "-two", "+three", "new file mode", "+++ b/sub/new.txt", "+x", "+++ b/staged.txt"} {
		if !strings.Contains(d.Text, want) {
			t.Errorf("diff lacks %q:\n%s", want, d.Text)
		}
	}
	if d.Truncated {
		t.Error("diff truncated")
	}
	one := diff(t, dir, base, "sub/new.txt", 1<<20)
	if !strings.Contains(one.Text, "+++ b/sub/new.txt") || strings.Contains(one.Text, "a.txt") {
		t.Errorf("path diff:\n%s", one.Text)
	}

	// The user's index is untouched: the untracked file is still untracked.
	indexAfter, _ := os.ReadFile(filepath.Join(dir, ".git", "index"))
	if string(indexBefore) != string(indexAfter) {
		t.Error("the index changed")
	}
	if out := run(t, dir, "status", "--porcelain"); !strings.Contains(out, "?? sub/") {
		t.Errorf("git status = %q", out)
	}
}

func TestIgnoredFilesAreLeftOut(t *testing.T) {
	dir := repo(t)
	write(t, dir, ".gitignore", "build/\n")
	write(t, dir, "build/out.bin", "junk\n")
	st := status(t, dir, "")
	fs := files(st)
	if _, ok := fs["build/out.bin"]; ok || len(fs) != 1 {
		t.Fatalf("files = %+v", st.Files)
	}
}

func TestUnborn(t *testing.T) {
	dir := unborn(t)
	if h, err := gitx.Head(context.Background(), dir); h != "" || err != nil {
		t.Fatalf("Head = %q, %v", h, err)
	}
	write(t, dir, "new.txt", "hello\n")
	st := status(t, dir, "")
	if !st.IsRepo || st.Branch != "main" || st.Head != "" || st.Base.Kind != gitx.BaseEmpty {
		t.Fatalf("status = %+v", st)
	}
	if len(st.Files) != 1 || st.Files[0].Status != gitx.FileAdded || st.Files[0].Additions != 1 {
		t.Fatalf("files = %+v", st.Files)
	}
	if d := diff(t, dir, "", "", 1<<20); !strings.Contains(d.Text, "+hello") {
		t.Fatalf("diff:\n%s", d.Text)
	}
}

func TestDetached(t *testing.T) {
	dir := repo(t)
	h := run(t, dir, "rev-parse", "HEAD")
	run(t, dir, "checkout", "-q", "--detach")
	st := status(t, dir, h)
	if !st.Detached || st.Branch != "" || st.Head != h || len(st.Files) != 0 {
		t.Fatalf("status = %+v", st)
	}
}

func TestBaseMovedByCommit(t *testing.T) {
	dir := repo(t)
	base := run(t, dir, "rev-parse", "HEAD")
	// The session commits a change, then makes another without committing.
	write(t, dir, "committed.txt", "c\n")
	run(t, dir, "add", "committed.txt")
	run(t, dir, "commit", "-q", "-m", "second")
	write(t, dir, "a.txt", "one\ntwo\nthree\n")

	fs := files(status(t, dir, base))
	if f, ok := fs["committed.txt"]; !ok || f.Status != gitx.FileAdded || f.Staged || f.Unstaged || f.Untracked {
		t.Errorf("committed.txt = %+v (ok %v)", f, ok)
	}
	if f := fs["a.txt"]; f.Status != gitx.FileModified || !f.Unstaged {
		t.Errorf("a.txt = %+v", f)
	}
	d := diff(t, dir, base, "", 1<<20)
	if !strings.Contains(d.Text, "+++ b/committed.txt") || !strings.Contains(d.Text, "+three") {
		t.Errorf("diff:\n%s", d.Text)
	}

	// Without a base only the uncommitted change shows.
	st := status(t, dir, "")
	if st.Base.Kind != gitx.BaseHeadNoBase || len(st.Files) != 1 {
		t.Errorf("no base: %+v", st)
	}
}

func TestMissingBaseFallsBackToHead(t *testing.T) {
	dir := repo(t)
	write(t, dir, "a.txt", "changed\n")
	gone := strings.Repeat("ab", 20)
	st := status(t, dir, gone)
	if st.Base.Kind != gitx.BaseHeadMissing || st.Base.Rev != st.Head || st.BaseCommit != gone || len(st.Files) != 1 {
		t.Fatalf("status = %+v", st)
	}
	if d := diff(t, dir, gone, "", 1<<20); d.Base.Kind != gitx.BaseHeadMissing || !strings.Contains(d.Text, "+changed") {
		t.Fatalf("diff = %+v", d)
	}
}

func TestRenameAndBinary(t *testing.T) {
	dir := repo(t)
	write(t, dir, "img.bin", "\x00\x01\x02")
	run(t, dir, "add", "img.bin")
	run(t, dir, "commit", "-q", "-m", "bin")
	base := run(t, dir, "rev-parse", "HEAD")
	run(t, dir, "mv", "a.txt", "b.txt")
	write(t, dir, "img.bin", "\x00\x03")
	fs := files(status(t, dir, base))
	if f := fs["b.txt"]; f.Status != gitx.FileRenamed || f.OldPath != "a.txt" || !f.Staged {
		t.Errorf("b.txt = %+v", f)
	}
	if f := fs["img.bin"]; !f.Binary || f.Additions != 0 {
		t.Errorf("img.bin = %+v", f)
	}
}

func TestUpstreamAheadBehind(t *testing.T) {
	up := repo(t)
	dir := filepath.Join(t.TempDir(), "clone")
	run(t, up, "clone", "-q", up, dir)
	run(t, dir, "config", "user.email", "test@example.com")
	run(t, dir, "config", "user.name", "Test")
	write(t, up, "u.txt", "u\n")
	run(t, up, "add", "u.txt")
	run(t, up, "commit", "-q", "-m", "upstream")
	run(t, dir, "fetch", "-q")
	write(t, dir, "l.txt", "l\n")
	run(t, dir, "add", "l.txt")
	run(t, dir, "commit", "-q", "-m", "local")
	st := status(t, dir, "")
	if st.Upstream != "origin/main" || st.Ahead != 1 || st.Behind != 1 {
		t.Fatalf("upstream %q ahead %d behind %d", st.Upstream, st.Ahead, st.Behind)
	}
}

func TestDiffTruncatesAtLineEnd(t *testing.T) {
	dir := repo(t)
	write(t, dir, "big.txt", strings.Repeat("line of text\n", 1000))
	d := diff(t, dir, "", "", 500)
	if !d.Truncated || len(d.Text) > 500 || !strings.HasSuffix(d.Text, "\n") {
		t.Fatalf("truncated %v, %d bytes", d.Truncated, len(d.Text))
	}
	if full := diff(t, dir, "", "", 1<<20); full.Truncated {
		t.Fatal("full diff truncated")
	}
}

func TestFileLimit(t *testing.T) {
	dir := repo(t)
	for _, n := range []string{"x1", "x2", "x3"} {
		write(t, dir, n, "x\n")
	}
	st, err := gitx.GetStatus(context.Background(), dir, "", 2)
	if err != nil {
		t.Fatal(err)
	}
	if len(st.Files) != 2 || !st.FilesTruncated || st.Untracked != 3 {
		t.Fatalf("status = %+v", st)
	}
}

func TestSameSizeEditInTheSameSecondIsSeen(t *testing.T) {
	dir := repo(t)
	// A same-size edit whose mtime equals the index's: only git's "racy"
	// recheck notices it, which needs the scratch index to keep the
	// index's mtime.
	at := time.Now().Add(-time.Hour).Truncate(time.Second)
	touch := func(p string) {
		t.Helper()
		if err := os.Chtimes(p, at, at); err != nil {
			t.Fatal(err)
		}
	}
	a, index := filepath.Join(dir, "a.txt"), filepath.Join(dir, ".git", "index")
	write(t, dir, "a.txt", "uno\ndos\n")
	touch(a)
	run(t, dir, "add", "a.txt") // the index caches a.txt's size and mtime
	run(t, dir, "commit", "-q", "-m", "uno")
	touch(index)
	write(t, dir, "a.txt", "ONE\nTWO\n")
	touch(a) // same size, same mtime as cached
	if st := status(t, dir, ""); len(st.Files) != 1 || st.Files[0].Path != "a.txt" {
		t.Fatalf("files = %+v", st.Files)
	}
	if d := diff(t, dir, "", "", 1<<20); !strings.Contains(d.Text, "+ONE") {
		t.Fatalf("diff:\n%s", d.Text)
	}
}
