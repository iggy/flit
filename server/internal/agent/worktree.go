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

// removeWorktree deletes session id's worktree and branch if nothing in it
// would be lost: no uncommitted changes and no commits that aren't on a
// remote. Otherwise it leaves it and logs why (WorktreeKept). Sessions
// without a worktree, or whose worktree is already gone, are left alone.
func (m *Manager) removeWorktree(ctx context.Context, id string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	info := s.snapshot()
	if info.WorktreePath == "" {
		return nil
	}
	if _, err := os.Stat(info.WorktreePath); errors.Is(err, os.ErrNotExist) {
		return nil
	}
	kept := func(reason string) error {
		_, err := s.append(&flitv1.Event{Payload: &flitv1.Event_WorktreeKept{WorktreeKept: &flitv1.WorktreeKept{
			Path: info.WorktreePath, Branch: info.WorktreeBranch, Reason: reason,
		}}})
		return err
	}
	why, err := gitx.WorktreeDirty(ctx, info.WorktreePath, info.BaseCommit)
	if err != nil {
		return kept(fmt.Sprintf("checking it failed: %v", err))
	}
	if why != "" {
		return kept(why)
	}
	if err := gitx.RemoveWorktree(ctx, info.WorktreePath, info.WorktreeBranch); err != nil {
		return kept(fmt.Sprintf("removing it failed: %v", err))
	}
	_, err = s.append(&flitv1.Event{Payload: &flitv1.Event_WorktreeRemoved{WorktreeRemoved: &flitv1.WorktreeRemoved{
		Path: info.WorktreePath, Branch: info.WorktreeBranch,
	}}})
	return err
}
