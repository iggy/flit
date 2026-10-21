package agent

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/gitx"
	"github.com/iggy/flit/server/internal/store"
)

// WorktreesDir is where per-session worktrees live, inside the data dir.
const WorktreesDir = "worktrees"

// worktreesFor says whether new sessions in p get their own worktree.
func (m *Manager) worktreesFor(p store.Project) bool {
	if p.Worktrees != nil {
		return *p.Worktrees
	}
	return m.cfg().Git.Worktrees.Default
}

// WorktreesEnabled is worktreesFor for callers outside the package.
func (m *Manager) WorktreesEnabled(p store.Project) bool { return m.worktreesFor(p) }

// shortID is the random tail of a session id, for branch names.
func shortID(id string) string {
	if i := strings.IndexByte(id, '_'); i >= 0 && len(id) >= i+1+12+8 {
		return id[i+1+12 : i+1+12+8]
	}
	return id
}

// addWorktree gives a new session (not stored yet) its own worktree of the
// repository containing info.WorkingDir: <data dir>/worktrees/<id>, on
// branch flit/<short id>, starting at the checkout's HEAD. On success the
// session works in the same place inside the worktree. It returns the
// event to log first: WorktreeCreated, or WorktreeSkipped when the
// session has to work in its directory directly.
func (m *Manager) addWorktree(ctx context.Context, info *store.Session) *flitv1.Event {
	skipped := func(format string, args ...any) *flitv1.Event {
		return &flitv1.Event{Payload: &flitv1.Event_WorktreeSkipped{WorktreeSkipped: &flitv1.WorktreeSkipped{
			Reason: fmt.Sprintf(format, args...),
		}}}
	}
	if m.DataDir == "" {
		return skipped("flit has no data directory to put worktrees in")
	}
	dir := info.WorkingDir
	root, err := gitx.Root(ctx, dir)
	if err != nil {
		return skipped("%v", err)
	}
	if root == "" {
		return skipped("%s is not in a git repository", dir)
	}
	root = filepath.Clean(filepath.FromSlash(root))
	// git reports the root with symlinks resolved (/private/var on macOS).
	rel := "."
	if real, err := filepath.EvalSymlinks(dir); err == nil {
		if r, err := filepath.Rel(root, real); err == nil && (r == "." || filepath.IsLocal(r)) {
			rel = r
		}
	}
	path := filepath.Join(m.DataDir, WorktreesDir, info.ID)
	branch, base, err := gitx.AddWorktree(ctx, root, path, "flit/"+shortID(info.ID))
	if errors.Is(err, gitx.ErrUnborn) {
		return skipped("%s has no commits yet", root)
	}
	if err != nil {
		return skipped("creating the worktree failed: %v", err)
	}
	created := &flitv1.WorktreeCreated{Path: path, Branch: branch, BaseCommit: base, SourceRoot: root}
	copies, err := gitx.CopyIgnored(ctx, root, path, m.cfg().Git.Worktrees.CopyIgnoredDirs())
	if err != nil {
		created.Copies = append(created.Copies, &flitv1.WorktreeCopy{Error: fmt.Sprintf("listing ignored directories: %v", err)})
	}
	for _, c := range copies {
		wc := &flitv1.WorktreeCopy{Path: c.Path, Method: string(c.Method)}
		if c.Err != nil {
			wc.Error = c.Err.Error()
		}
		created.Copies = append(created.Copies, wc)
	}
	info.SourceDir = dir
	info.WorkingDir = filepath.Join(path, rel)
	info.WorktreePath, info.WorktreeBranch, info.BaseCommit = path, branch, base
	return &flitv1.Event{Payload: &flitv1.Event_WorktreeCreated{WorktreeCreated: created}}
}

// WorktreeRemoval is what RemoveWorktree did.
type WorktreeRemoval struct {
	Session store.Session
	// BranchKept says the branch stayed because it holds Commits commits
	// that no other ref has.
	BranchKept bool
	Commits    int
}

// RemoveWorktree deletes session id's worktree without losing history:
// never while it has uncommitted changes (ErrWorktreeDirty), and its branch
// only when every commit on it is also on another branch, a tag or a
// remote. Afterwards the session can't run turns.
func (m *Manager) RemoveWorktree(ctx context.Context, id string) (WorktreeRemoval, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return WorktreeRemoval{}, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	info := s.info
	switch {
	case info.WorktreePath == "":
		return WorktreeRemoval{}, ErrNoWorktree
	case info.WorktreeRemoved:
		return WorktreeRemoval{}, ErrWorktreeGone
	case info.State == flitv1.TaskState_TASK_STATE_WORKING || info.State == flitv1.TaskState_TASK_STATE_WAITING:
		return WorktreeRemoval{}, ErrBusy
	}
	r := WorktreeRemoval{}
	if _, err := os.Stat(info.WorktreePath); err == nil {
		dirty, err := gitx.Uncommitted(ctx, info.WorktreePath)
		if err != nil {
			return WorktreeRemoval{}, err
		}
		if dirty {
			return WorktreeRemoval{}, ErrWorktreeDirty
		}
		if r.Commits, err = gitx.OnlyOnBranch(ctx, info.WorktreePath, info.WorktreeBranch, info.BaseCommit); err != nil {
			return WorktreeRemoval{}, err
		}
		r.BranchKept = r.Commits > 0
		if err := gitx.RemoveWorktree(ctx, info.WorktreePath, info.WorktreeBranch, !r.BranchKept); err != nil {
			return WorktreeRemoval{}, err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return WorktreeRemoval{}, err
	} else {
		// Deleted by hand: record it, and leave the branch alone.
		r.BranchKept = true
	}
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_WorktreeRemoved{WorktreeRemoved: &flitv1.WorktreeRemoved{
		Path: info.WorktreePath, Branch: info.WorktreeBranch, BranchKept: r.BranchKept, Commits: int32(r.Commits),
	}}}); err != nil {
		return WorktreeRemoval{}, err
	}
	r.Session = s.info
	return r, nil
}

// cleanUpWorktree is RemoveWorktree for an archived session: a worktree
// that can't go is left, and the log says why (WorktreeKept), once.
func (m *Manager) cleanUpWorktree(ctx context.Context, id string) error {
	_, err := m.RemoveWorktree(ctx, id)
	switch {
	case err == nil, errors.Is(err, ErrNoWorktree), errors.Is(err, ErrWorktreeGone):
		return nil
	case errors.Is(err, ErrWorktreeDirty):
		return m.keptWorktree(ctx, id, "it has uncommitted changes")
	case errors.Is(err, ErrBusy):
		return m.keptWorktree(ctx, id, "a turn is running")
	default:
		return m.keptWorktree(ctx, id, fmt.Sprintf("removing it failed: %v", err))
	}
}

func (m *Manager) keptWorktree(ctx context.Context, id, reason string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	info := s.snapshot()
	_, err = s.append(&flitv1.Event{Payload: &flitv1.Event_WorktreeKept{WorktreeKept: &flitv1.WorktreeKept{
		Path: info.WorktreePath, Branch: info.WorktreeBranch, Reason: reason,
	}}})
	return err
}
