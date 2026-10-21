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
