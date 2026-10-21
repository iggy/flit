package agent

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/gitx"
	"github.com/iggy/flit/server/internal/store"
)

// gitRepo makes a repository with a commit, an ignored node_modules and a
// subdirectory, and returns its root.
func gitRepo(t *testing.T) string {
	t.Helper()
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	dir := t.TempDir()
	for _, args := range [][]string{
		{"init", "-q", "-b", "main"},
		{"config", "user.email", "test@example.com"},
		{"config", "user.name", "Test"},
		{"config", "commit.gpgsign", "false"},
		{"config", "core.autocrlf", "false"},
	} {
		runGit(t, dir, args...)
	}
	writeFile(t, dir, ".gitignore", "node_modules/\n")
	writeFile(t, dir, "sub/a.txt", "a\n")
	runGit(t, dir, "add", ".")
	runGit(t, dir, "commit", "-q", "-m", "first")
	writeFile(t, dir, "node_modules/dep/index.js", "dep\n")
	return dir
}

func runGit(t *testing.T, dir string, args ...string) string {
	t.Helper()
	out, err := gitx.Run(context.Background(), dir, args...)
	if err != nil {
		t.Fatal(err)
	}
	return strings.TrimSpace(out)
}

func writeFile(t *testing.T, dir, name, text string) {
	t.Helper()
	p := filepath.Join(dir, name)
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
}

// worktreeHarness is a harness with a data dir and a project for repo
// with worktrees turned on.
func worktreeHarness(t *testing.T, repo string) (*harness, store.Project) {
	t.Helper()
	h := newHarness(t)
	h.m.DataDir = t.TempDir()
	ctx := context.Background()
	p, err := h.m.CreateProject(ctx, repo, "")
	if err != nil {
		t.Fatal(err)
	}
	on := true
	if p, err = h.m.SetProjectWorktrees(ctx, p.ID, &on); err != nil {
		t.Fatal(err)
	}
	if !h.m.WorktreesEnabled(p) {
		t.Fatal("worktrees not enabled")
	}
	return h, p
}

func events(t *testing.T, h *harness, id string) []*flitv1.Event {
	t.Helper()
	evs, err := h.st.Events(context.Background(), id, 1, 1<<62)
	if err != nil {
		t.Fatal(err)
	}
	return evs
}

func TestWorktreeSession(t *testing.T) {
	repo := gitRepo(t)
	h, p := worktreeHarness(t, repo)
	ctx := context.Background()
	head := runGit(t, repo, "rev-parse", "HEAD")

	s, err := h.m.Create(ctx, CreateOptions{ProjectID: p.ID, WorkingDir: filepath.Join(repo, "sub")})
	if err != nil {
		t.Fatal(err)
	}
	wantPath := filepath.Join(h.m.DataDir, WorktreesDir, s.ID)
	if s.WorktreePath != wantPath || !strings.HasPrefix(s.WorktreeBranch, "flit/") || s.BaseCommit != head {
		t.Fatalf("session = %+v", s)
	}
	// A session in a subdirectory works in the same subdirectory of the
	// worktree.
	if s.WorkingDir != filepath.Join(wantPath, "sub") || s.SourceDir != filepath.Join(repo, "sub") {
		t.Fatalf("working dir %q, source %q", s.WorkingDir, s.SourceDir)
	}
	if b, err := os.ReadFile(filepath.Join(s.WorkingDir, "a.txt")); err != nil || string(b) != "a\n" {
		t.Fatalf("a.txt in worktree: %q, %v", b, err)
	}
	if _, err := os.Stat(filepath.Join(wantPath, "node_modules", "dep", "index.js")); err != nil {
		t.Errorf("node_modules not copied: %v", err)
	}
	// The user's checkout stays on its branch.
	if b := runGit(t, repo, "branch", "--show-current"); b != "main" {
		t.Errorf("checkout switched to %q", b)
	}
	got, err := h.st.GetSession(ctx, s.ID)
	if err != nil || got.WorktreePath != wantPath || got.WorkingDir != s.WorkingDir {
		t.Fatalf("stored = %+v, %v", got, err)
	}

	evs := events(t, h, s.ID)
	if len(evs) != 1 || evs[0].GetWorktreeCreated() == nil {
		t.Fatalf("events = %v", evs)
	}
	wc := evs[0].GetWorktreeCreated()
	if wc.Path != wantPath || wc.Branch != s.WorktreeBranch || wc.BaseCommit != head || len(wc.Copies) != 1 ||
		wc.Copies[0].Path != "node_modules" || wc.Copies[0].Error != "" {
		t.Fatalf("WorktreeCreated = %v", wc)
	}
	if m := wc.Copies[0].Method; m != string(gitx.CopyReflink) && m != string(gitx.CopyPlain) {
		t.Errorf("method %q", m)
	}

	// The Changes view looks at the worktree.
	writeFile(t, s.WorkingDir, "new.txt", "n\n")
	st, err := h.m.GitStatus(ctx, s.ID)
	if err != nil || st.Base.Kind != gitx.BaseSession || len(st.Files) != 1 || st.Files[0].Path != "sub/new.txt" {
		t.Fatalf("status = %+v, %v", st, err)
	}
}

func TestWorktreeOffOrNotARepo(t *testing.T) {
	repo := gitRepo(t)
	h := newHarness(t)
	h.m.DataDir = t.TempDir()
	ctx := context.Background()

	// Worktrees off (the default): exactly as before.
	p, err := h.m.CreateProject(ctx, repo, "")
	if err != nil {
		t.Fatal(err)
	}
	s, err := h.m.Create(ctx, CreateOptions{ProjectID: p.ID})
	if err != nil {
		t.Fatal(err)
	}
	if s.WorkingDir != repo || s.WorktreePath != "" || s.SourceDir != "" || len(events(t, h, s.ID)) != 0 {
		t.Fatalf("session = %+v", s)
	}
	if _, err := os.Stat(filepath.Join(h.m.DataDir, WorktreesDir)); !os.IsNotExist(err) {
		t.Errorf("worktrees dir made: %v", err)
	}

	// On, but the directory isn't a repository: works there, says why.
	plain := t.TempDir()
	np, err := h.m.CreateProject(ctx, plain, "plain")
	if err != nil {
		t.Fatal(err)
	}
	on := true
	if _, err := h.m.SetProjectWorktrees(ctx, np.ID, &on); err != nil {
		t.Fatal(err)
	}
	s, err = h.m.Create(ctx, CreateOptions{ProjectID: np.ID})
	if err != nil {
		t.Fatal(err)
	}
	evs := events(t, h, s.ID)
	if s.WorkingDir != plain || s.WorktreePath != "" || len(evs) != 1 ||
		!strings.Contains(evs[0].GetWorktreeSkipped().GetReason(), "not in a git repository") {
		t.Fatalf("session %+v, events %v", s, evs)
	}

	// The config default applies to projects that haven't chosen; a
	// project's own choice wins.
	h.mu.Lock()
	h.cfg.Git.Worktrees.Default = true
	h.mu.Unlock()
	if p, _ = h.st.GetProject(ctx, p.ID); !h.m.WorktreesEnabled(p) {
		t.Error("config default not applied")
	}
	off := false
	if p, err = h.m.SetProjectWorktrees(ctx, p.ID, &off); err != nil || h.m.WorktreesEnabled(p) {
		t.Errorf("project choice: %v", err)
	}
	if p, err = h.m.SetProjectWorktrees(ctx, p.ID, nil); err != nil || p.Worktrees != nil || !h.m.WorktreesEnabled(p) {
		t.Errorf("cleared choice: %+v, %v", p.Worktrees, err)
	}
}

func TestArchivedWorktreeCleanup(t *testing.T) {
	repo := gitRepo(t)
	h, p := worktreeHarness(t, repo)
	ctx := context.Background()
	newRun := func() store.Session {
		t.Helper()
		s, err := h.m.Create(ctx, CreateOptions{ProjectID: p.ID, CronID: "nightly"})
		if err != nil {
			t.Fatal(err)
		}
		return s
	}
	clean, dirty, committed, keep := newRun(), newRun(), newRun(), newRun()
	writeFile(t, dirty.WorkingDir, "wip.txt", "w\n")
	writeFile(t, committed.WorkingDir, "done.txt", "d\n")
	runGit(t, committed.WorkingDir, "add", "done.txt")
	runGit(t, committed.WorkingDir, "commit", "-q", "-m", "done")

	if n, err := h.m.ArchiveCronSessions(ctx, "nightly", 1); err != nil || n != 3 {
		t.Fatalf("archived %d, %v", n, err)
	}
	last := func(s store.Session) *flitv1.Event {
		evs := events(t, h, s.ID)
		return evs[len(evs)-1]
	}
	if _, err := os.Stat(clean.WorktreePath); !os.IsNotExist(err) {
		t.Errorf("clean worktree still there: %v", err)
	}
	if last(clean).GetWorktreeRemoved() == nil {
		t.Errorf("clean: %v", last(clean))
	}
	if out := runGit(t, repo, "branch", "--list", clean.WorktreeBranch); out != "" {
		t.Errorf("clean branch still there: %q", out)
	}
	for _, s := range []store.Session{dirty, committed} {
		if _, err := os.Stat(s.WorktreePath); err != nil {
			t.Errorf("%s removed: %v", s.WorkingDir, err)
		}
		if k := last(s).GetWorktreeKept(); k == nil || k.Reason == "" {
			t.Errorf("kept: %v", last(s))
		}
	}
	if !strings.Contains(last(committed).GetWorktreeKept().GetReason(), "pushed") {
		t.Errorf("committed reason: %v", last(committed))
	}
	if _, err := os.Stat(keep.WorktreePath); err != nil {
		t.Errorf("newest run's worktree removed: %v", err)
	}
}
