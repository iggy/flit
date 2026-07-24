# Phase 6 — Memory, learning & history

**Goal:** surface Hermes's distinctive "closed learning loop" — the self-curated
memory, skills-from-experience, and the git-checkpoint safety net.

**Reference:** `reference/02-rpc-index.md` §Memory/learning, §Rollback;
`gatewayTypes.ts` `Rollback*` (:511).

## Learning timeline (/journey)

### P6-01 — Journey view
`learning.frames` (pre-rendered timeline of skills created / memories curated
over time). Render as a scrollable timeline; the desktop calls this the
"journey".

### P6-02 — Journey node detail & edit
`learning.detail` (one node's content), `learning.edit` (rewrite a SKILL.md or
memory chunk), `learning.delete` (archive a skill / remove a memory). A detail
sheet with edit/delete.

## Insights & facts

### P6-03 — Insights dashboard
`insights.get` (aggregate session/message counts over a window) — a small
analytics view.

### P6-04 — Project facts
`project.facts` (structured facts for a cwd: manifests, package manager, verify
commands, context files) shown in a project-info panel (ties to Phase 4 projects).

## Rollback / checkpoints (git safety net)

### P6-05 — Checkpoint list & diff
`rollback.list` (git checkpoints for the session cwd), `rollback.diff` (rendered
diff vs a checkpoint).

### P6-06 — Restore
`rollback.restore` (full or file-scoped restore to a hash) with a strong confirm
and a clear result (restored_to, history_removed).

**Exit criteria:** browse and edit the agent's learning journey, view insights
and project facts, and use git checkpoints to diff/restore work the agent did.
