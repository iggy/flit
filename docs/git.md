# Git changes

When a flit session works in a git repository, the app shows what the
session has changed.

- **The session header** shows the branch (or the short commit when HEAD
  is detached), how many files changed, and, when the branch has an
  upstream, how far ahead (↑) and behind (↓) of it you are. Outside a
  repository it shows nothing.
- **Tap it** for the Changes view: every changed file with its status
  (M modified, A added, D deleted, R renamed, ...), `+`/`−` line counts and
  whether the change is staged, unstaged, untracked or already committed.
  Tap a file for its diff, added lines in green and removed lines in red.
  On a wide window the list and the diff sit side by side; on a phone the
  diff opens on its own page.

The view refreshes by itself when a tool that may change files (`write`,
`patch`, `shell`, `git_commit`) finishes and when a turn ends; the refresh
button in the Changes view fetches it on demand.

## What "changed" means

When a session is created, flit records the commit HEAD is on as the
session's **base commit** (`Session.base_commit`). The Changes view diffs
the base commit against the working tree, so it covers everything since
the session started: commits the agent made, staged and unstaged edits,
and new untracked files (ignored files are left out). The counts in
`GitStatus` (`staged_count`, `unstaged_count`, `untracked_count`) are
relative to HEAD, like `git status`.

There may be no usable base:

| Situation | Compared against | `diff_base_kind` |
| --- | --- | --- |
| The base commit exists | the base commit | `SESSION_START` |
| The session has no base (its directory wasn't a repository with commits when it started, or it predates this feature) | HEAD | `HEAD_NO_BASE` |
| The base commit is gone (e.g. history rewritten and garbage collected) | HEAD | `HEAD_BASE_MISSING` |
| No base and no commits yet | the empty tree: every file is new | `EMPTY_TREE` |

The Changes view says which one applies.

## Notes

- flit only reads the repository for this. Untracked files are diffed
  through a scratch copy of the index (`GIT_INDEX_FILE`), with
  `GIT_OPTIONAL_LOCKS=0`, so your index and staging are never touched.
- The status lists at most 2000 files (`files_truncated` says when there
  were more), and a diff is cut at 1 MiB by default (8 MiB at most,
  `GitDiffRequest.max_bytes`), at a line end, with `truncated` set.
- It needs the `git` binary on the server's `PATH`, like the agent's git
  tools. `git.enabled: false` in the config turns off those tools but not
  this view.
- Switching conversation branches ([branches.md](branches.md)) doesn't
  rewind files, so the Changes view shows the working tree as it is.

## API

`SessionService.GitStatus` and `SessionService.GitDiff` (see
`proto/flit/v1/session.proto`). Both work on the repository containing
the session's working directory (the whole work tree, even when the
session started in a subdirectory); paths are relative to its root.

## Worktrees

A project can give each new session its **own git worktree**, so the
agent works on a branch of its own and your checkout is never switched or
modified. It's off by default.

- Turn it on for a project from the project menu in the app ("A git
  worktree per session"), or with `ProjectService.SetProjectWorktrees`.
  Projects that haven't chosen follow the config:

  ```yaml
  git:
    worktrees:
      default: false
      copy_ignored: [node_modules, .venv, venv, target, build, dist, .dart_tool, .gradle, Pods, .next]
  ```

- When a session starts in such a project and its directory is in a git
  repository with commits, flit runs `git worktree add` to create
  `<data dir>/worktrees/<session id>` on a new branch `flit/<8 characters
  of the session id>` (with `-2`, `-3`, ... if that name is taken),
  starting at the commit your checkout's HEAD is on. Your uncommitted
  changes stay in your checkout and aren't carried over.
- The session works in the same place inside the worktree: a session
  started in `repo/server` works in `<worktree>/server`. The session keeps
  the directory it was started in as `source_dir` and the worktree as
  `worktree_path` / `worktree_branch`. The app shows a worktree icon by the
  working directory, with the branch and source in its tooltip.
- The worktree's starting commit is the session's base commit, so the
  Changes view shows exactly what the session did on its branch.
- **Ignored directories** named in `copy_ignored` (dependencies, build
  output; matched by name anywhere in the tree) are copied from your
  checkout into the worktree, so builds and tests don't start from
  nothing. flit uses a reflink copy (copy-on-write: `cp --reflink=always`
  on Linux, `cp -c` on macOS) and falls back to a plain copy where the
  filesystem can't reflink (e.g. ext4) or on Windows. Directories that
  don't exist are skipped. A directory that is itself a symlink is
  skipped, and symlinks inside are copied as symlinks, so nothing outside
  the repository is read. `copy_ignored: []` copies nothing.
- The session log starts with `WorktreeCreated`: the path, branch, base
  commit and each copied directory with the method used (`reflink` or
  `copy`). If no worktree could be made (not a git repository, no commits
  yet, git failed), the log starts with `WorktreeSkipped` and the reason,
  and the session works in its directory as before.
- Sessions in projects without worktrees behave exactly as before.
- flit never pushes the branch.

### Cleanup

Sessions can't be deleted yet. When a session is **archived** (today:
old runs of a cron job, see [cron.md](cron.md)), flit removes its
worktree and branch, but only if nothing would be lost: no uncommitted
changes (untracked files count, ignored ones don't) and no commits that
aren't on a remote. Otherwise the worktree stays and the session log gets
`WorktreeKept` with the reason; flit doesn't try again. When cleanup
succeeds, the log gets `WorktreeRemoved`.

To finish a session's work, merge or push its branch from your checkout
(`git merge flit/abcd1234`), or remove the worktree yourself with
`git worktree remove <path>` and `git branch -D flit/abcd1234`.
