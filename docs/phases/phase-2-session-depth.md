# Phase 2 — Session depth

**Goal:** turn the MVP's minimal session handling into full, resilient session
management — the backbone of a daily-driver client.

**Reference:** `reference/02-rpc-index.md` §Sessions; `01-gateway-protocol.md`
§9 (two ids) & §10 (reconnect).

## Tickets

### P2-01 — Full session list & metadata
`session.list` with rich rows: title, preview, message_count, started_at,
source; pull-to-refresh; search/filter. `session.most_recent` for a "continue"
entry point.

### P2-02 — Message history on resume
Render the `messages[]` returned by `session.resume` as the scrollback so
switching into an old session shows its transcript. Reconcile with any live turn
already in flight (`inflight` field).

### P2-03 — Rename / delete / save
`session.title` (rename), `session.delete`, `session.save`. Confirm-destructive
UX for delete.

### P2-04 — Branch a session
`session.branch` → new session from a point; navigate into the branch. Surface
the returned title.

### P2-05 — Usage & context breakdown
`session.usage` (tokens, cost, cache, context %) shown in a session-info sheet;
`session.context_breakdown` as a detail view. Live-update from `session.info`
events after each turn.

### P2-06 — Compress context
`session.compress` (long handler) with before/after token/message summary; show
the summary payload; reflect the new state.

### P2-07 — Undo
`session.undo` (remove last turn) with a confirm and a re-render.

### P2-08 — Working directory
`session.cwd.set` — set/display the session cwd (matters for tool context and
projects); a small cwd chip.

### P2-09 — Reconnect resilience ⭐
Harden the reconnect path from Phase 0: on socket drop → backoff reconnect →
`gateway.ready` → `session.resume` the active durable id (before the server's
orphan reaper finalizes it, protocol §10). Show a non-alarming "reconnecting"
state; never lose the user's place. Test with a gateway restart.

### P2-10 — Multi-session live status
Poll/subscribe `session.active_list` to show live status badges
(idle/starting/waiting/working) across sessions; reflect the roadmap open
question #4 (status enum superset) — tolerate unknown status strings.

**Exit criteria:** you can live in the app across many sessions, resume old ones
with full history, rename/delete/branch/compress/undo, and survive a gateway
restart without losing your place.
