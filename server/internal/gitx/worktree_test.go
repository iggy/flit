package gitx

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// worktreeRepo makes a repository with one commit, a .gitignore and the
// given ignored directories (each holding a file).
func worktreeRepo(t *testing.T, ignored ...string) string {
	t.Helper()
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	dir := t.TempDir()
	git := func(args ...string) {
		t.Helper()
		if _, err := Run(context.Background(), dir, args...); err != nil {
			t.Fatal(err)
		}
	}
	git("init", "-q", "-b", "main")
	git("config", "user.email", "test@example.com")
	git("config", "user.name", "Test")
	git("config", "commit.gpgsign", "false")
	git("config", "core.autocrlf", "false")
	put(t, dir, ".gitignore", "node_modules/\ntarget/\n*.log\n")
	put(t, dir, "a.txt", "a\n")
	git("add", ".")
	git("commit", "-q", "-m", "first")
	for _, d := range ignored {
		put(t, dir, filepath.Join(d, "pkg", "index.js"), "module.exports = 1\n")
	}
	return dir
}

func put(t *testing.T, dir, name, text string) {
	t.Helper()
	p := filepath.Join(dir, name)
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestAddWorktree(t *testing.T) {
	ctx := context.Background()
	src := worktreeRepo(t)
	headBefore := head(ctx, src)
	put(t, src, "a.txt", "uncommitted\n") // stays in the user's checkout only

	dir := filepath.Join(t.TempDir(), "worktrees", "ses_1")
	branch, base, err := AddWorktree(ctx, src, dir, "flit/abc")
	if err != nil {
		t.Fatal(err)
	}
	if branch != "flit/abc" || base != headBefore {
		t.Fatalf("branch %q base %q", branch, base)
	}
	if b, _ := os.ReadFile(filepath.Join(dir, "a.txt")); string(b) != "a\n" {
		t.Errorf("worktree a.txt = %q", b)
	}
	// The user's checkout is untouched: same branch, change still there.
	if out, _ := Run(ctx, src, "branch", "--show-current"); strings.TrimSpace(out) != "main" {
		t.Errorf("source branch = %q", out)
	}
	if b, _ := os.ReadFile(filepath.Join(src, "a.txt")); string(b) != "uncommitted\n" {
		t.Errorf("source a.txt = %q", b)
	}

	// A taken branch name gets a suffix.
	branch2, _, err := AddWorktree(ctx, src, filepath.Join(t.TempDir(), "w2"), "flit/abc")
	if err != nil || branch2 != "flit/abc-2" {
		t.Fatalf("second branch %q, %v", branch2, err)
	}
}

func TestAddWorktreeUnborn(t *testing.T) {
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	src := t.TempDir()
	if _, err := Run(context.Background(), src, "init", "-q"); err != nil {
		t.Fatal(err)
	}
	_, _, err := AddWorktree(context.Background(), src, filepath.Join(t.TempDir(), "w"), "flit/x")
	if !errors.Is(err, ErrUnborn) {
		t.Fatalf("err = %v", err)
	}
}

func TestCopyIgnored(t *testing.T) {
	ctx := context.Background()
	src := worktreeRepo(t, "node_modules", "app/node_modules", "target")
	put(t, src, "debug.log", "x\n")
	if runtime.GOOS != "windows" {
		// A symlinked "node_modules" pointing outside the repo is skipped,
		// and a symlink inside a copied directory stays a symlink.
		outside := t.TempDir()
		put(t, outside, "secret", "s\n")
		if err := os.MkdirAll(filepath.Join(src, "lib"), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.Symlink(outside, filepath.Join(src, "lib", "node_modules")); err != nil {
			t.Fatal(err)
		}
		if err := os.Symlink(outside, filepath.Join(src, "target", "out")); err != nil {
			t.Fatal(err)
		}
	}
	dst := filepath.Join(t.TempDir(), "w")
	if _, _, err := AddWorktree(ctx, src, dst, "flit/c"); err != nil {
		t.Fatal(err)
	}

	for _, force := range []bool{false, true} {
		if force {
			// The fallback: a filesystem that can't reflink.
			orig := reflinkCopy
			reflinkCopy = func(ctx context.Context, src, dst string) error {
				if err := os.MkdirAll(dst, 0o755); err != nil { // a partial copy
					return err
				}
				return errors.ErrUnsupported
			}
			t.Cleanup(func() { reflinkCopy = orig })
			for _, d := range []string{"node_modules", "app", "target"} {
				if err := os.RemoveAll(filepath.Join(dst, d)); err != nil {
					t.Fatal(err)
				}
			}
		}
		copied, err := CopyIgnored(ctx, src, dst, []string{"node_modules", "target", ".venv"})
		if err != nil {
			t.Fatal(err)
		}
		got := map[string]CopyMethod{}
		for _, c := range copied {
			if c.Err != nil {
				t.Fatalf("%s: %v", c.Path, c.Err)
			}
			got[c.Path] = c.Method
		}
		if len(got) != 3 || got["node_modules"] == "" || got["app/node_modules"] == "" || got["target"] == "" {
			t.Fatalf("force %v: copied %v", force, copied)
		}
		if force && got["target"] != CopyPlain {
			t.Errorf("fallback method = %q", got["target"])
		}
		for _, f := range []string{"node_modules/pkg/index.js", "app/node_modules/pkg/index.js", "target/pkg/index.js"} {
			if b, err := os.ReadFile(filepath.Join(dst, f)); err != nil || string(b) != "module.exports = 1\n" {
				t.Errorf("force %v: %s = %q, %v", force, f, b, err)
			}
		}
		if _, err := os.Lstat(filepath.Join(dst, "debug.log")); err == nil {
			t.Error("an ignored file was copied")
		}
		if runtime.GOOS != "windows" {
			if _, err := os.Lstat(filepath.Join(dst, "lib", "node_modules")); err == nil {
				t.Error("a symlinked directory was copied")
			}
			if fi, err := os.Lstat(filepath.Join(dst, "target", "out")); err != nil || fi.Mode()&os.ModeSymlink == 0 {
				t.Errorf("target/out: %v, %v", fi, err)
			}
		}
	}

	// Nothing to copy, or nothing asked for.
	if copied, err := CopyIgnored(ctx, worktreeRepo(t), dst, []string{"node_modules"}); err != nil || len(copied) != 0 {
		t.Fatalf("missing dirs: %v, %v", copied, err)
	}
	if copied, err := CopyIgnored(ctx, src, dst, nil); err != nil || copied != nil {
		t.Fatalf("no names: %v, %v", copied, err)
	}
}

func TestRemoveWorktree(t *testing.T) {
	ctx := context.Background()
	src := worktreeRepo(t, "node_modules")
	newWorktree := func(name string) (string, string, string) {
		t.Helper()
		dir := filepath.Join(t.TempDir(), name)
		branch, base, err := AddWorktree(ctx, src, dir, "flit/"+name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := CopyIgnored(ctx, src, dir, []string{"node_modules"}); err != nil {
			t.Fatal(err)
		}
		return dir, branch, base
	}
	branchExists := func(branch string) bool {
		_, err := Run(ctx, src, "show-ref", "--verify", "--quiet", "refs/heads/"+branch)
		return err == nil
	}
	commit := func(dir, name string) {
		t.Helper()
		put(t, dir, name, name+"\n")
		if _, err := Run(ctx, dir, "add", name); err != nil {
			t.Fatal(err)
		}
		if _, err := Run(ctx, dir, "commit", "-q", "-m", name); err != nil {
			t.Fatal(err)
		}
	}

	// Clean, no new commits (ignored files don't count): nothing to keep.
	dir, branch, base := newWorktree("clean")
	if dirty, err := Uncommitted(ctx, dir); err != nil || dirty {
		t.Fatalf("clean worktree: dirty %v, %v", dirty, err)
	}
	if n, err := OnlyOnBranch(ctx, dir, branch, base); err != nil || n != 0 {
		t.Fatalf("clean worktree: %d new commits, %v", n, err)
	}
	if err := RemoveWorktree(ctx, dir, branch, true); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(dir); !os.IsNotExist(err) {
		t.Errorf("worktree still there: %v", err)
	}
	if branchExists(branch) {
		t.Error("branch still there")
	}

	// Untracked files are uncommitted changes, and git won't remove them.
	dir, branch, _ = newWorktree("edited")
	put(t, dir, "new.txt", "n\n")
	if dirty, err := Uncommitted(ctx, dir); err != nil || !dirty {
		t.Errorf("untracked file: dirty %v, %v", dirty, err)
	}
	if err := RemoveWorktree(ctx, dir, branch, false); err == nil {
		t.Error("removed a worktree with an untracked file")
	}

	// Commits only on the branch: the worktree can go, the branch keeps
	// them.
	dir, branch, base = newWorktree("committed")
	commit(dir, "c1.txt")
	commit(dir, "c2.txt")
	if n, err := OnlyOnBranch(ctx, dir, branch, base); err != nil || n != 2 {
		t.Fatalf("committed: %d, %v", n, err)
	}
	if err := RemoveWorktree(ctx, dir, branch, false); err != nil {
		t.Fatal(err)
	}
	if !branchExists(branch) {
		t.Fatal("the branch with the commits is gone")
	}
	if out, _ := Run(ctx, src, "log", "--format=%s", "refs/heads/"+branch); !strings.Contains(out, "c2.txt") {
		t.Errorf("history lost: %q", out)
	}

	// Once another branch has the commits, deleting this one loses nothing.
	dir, branch, base = newWorktree("merged")
	commit(dir, "m.txt")
	if _, err := Run(ctx, src, "branch", "keep", "refs/heads/"+branch); err != nil {
		t.Fatal(err)
	}
	if n, err := OnlyOnBranch(ctx, dir, branch, base); err != nil || n != 0 {
		t.Errorf("merged: %d, %v", n, err)
	}
}
