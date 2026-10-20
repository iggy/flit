# Conversation branches

On any of your earlier messages in a flit session you can:

- **Retry from here**: keep the message and have the agent answer it again
  (with the session's current model). The original answer stays.
- **Edit and resend**: send different text in its place. The original
  message and everything after it stay.

Either one starts a new **branch** of the conversation and switches the
session to it. The message where the branches part shows **‹ 2 / 3 ›**:
the arrows switch between the alternatives, and the chat shows the whole
conversation of the branch you pick. The next message you send continues
the branch on screen, and the model only ever sees that branch's history.

Every client on the session sees new branches and switches as they
happen.

## Limits

- Forking and switching need the session idle: stop a running turn first.
- Forking needs an empty message queue: send or cancel queued messages
  first. They were written as follow-ups to the conversation as it was, so
  flit doesn't guess which branch they belong on. Switching branches with
  messages queued is allowed; they go to the active branch when sent.
- **Files are not rewound.** A branch forks the conversation, not the
  working directory: changes the agent made on another branch are still
  on disk.

## How it's stored

Branches live in the session's single event log; nothing is copied.

- Every event carries `branch_id`, the session's active branch when it
  was recorded (empty: the root branch, which is all there is in a session
  that never forked).
- `BranchCreated` gives a new branch its parent and `fork_seq`: the
  branch includes its parent's events with `seq <= fork_seq` (and,
  through the parent, its ancestors' up to their fork points), then its
  own. A retry forks right after the user message; an edit forks just
  before it and records the new text as a new message on the branch.
- `BranchSwitched` changes the active branch (also stored on the session,
  `Session.branch_id`).
- Session-wide events (task state, model, effort, yolo, MCP servers,
  project, the queue, branches themselves) apply on every branch.

Branches that share a parent and `fork_seq` are alternatives at the same
point. The graph view planned for later reads the same records.

On the server, `internal/branches` turns the log into a tree and a branch
into its path; the agent rebuilds the model's context, ratings resolve
turns, and `flit export` writes conversations, all through it.

## Compaction

A compaction (automatic near the context limit, or `/compact`) is
recorded on the branch it ran on and only affects branches whose path
includes it: branches forked before it keep their full history, branches
forked after it start from its summary. Compacting a branch drops only
that branch's saved llama.cpp cache.

## llama.cpp prompt caches

With `llamacpp.kv_cache` on, each branch's cache is saved under its own
name (the session, plus the branch for branches other than the root), so a
switch never restores another branch's conversation. A branch with no save
of its own yet starts from its nearest ancestor's: they share everything
up to the fork, and llama.cpp reuses only the tokens a prompt has in
common with a cache. Once a branch's path has a compaction, only its own
save is used.

## Ratings and export

A rating belongs to the reply it rates, on the branch that reply was
written on. See [export.md](export.md) for how branches appear in
`flit export`.
