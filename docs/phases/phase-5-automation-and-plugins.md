# Phase 5 — Automation & full plugins

**Goal:** the "runs unattended / fleet of workers" story — cron, background
tasks, process control, the full kanban surface, and the plugins hub.

**Reference:** `reference/02-rpc-index.md` §Automation, §Plugins, §Processes;
`reference/06-kanban-rest.md` (full endpoint catalog).

## Cron / scheduled automations

### P5-01 — Cron list & manage
`cron.manage` (action: list/add/remove/pause/resume) — a scheduler UI: list
jobs, create a natural-language schedule, pause/resume/delete. Mirrors the
desktop `cron` page.

## Background & processes

### P5-02 — Background tasks
`prompt.background` (detached agent run) + the `background.complete` event — fire
a task and get notified when done.

### P5-03 — Process control
`process.list` (session-scoped registry with output tails), `process.kill` (one),
`process.stop` (all). `shell.exec` for a quick ad-hoc command surface.

## Full kanban (beyond MVP read+move)

### P5-04 — Live board feed
Subscribe `WS /api/plugins/kanban/events` with a `since` cursor seeded from
`latest_event_id` — real-time board updates (replaces MVP polling).

### P5-05 — Task authoring & flow
Create (`POST /tasks`), full edit (`PATCH`), comments, links (parent/child),
bulk ops (`/tasks/bulk`), attachments (upload/download), specify/decompose
(LLM), reassign/reclaim.

### P5-06 — Boards & fleet ops
Multiple boards (`/boards` CRUD + switch); fleet views: `/stats` HUD,
`/workers/active`, `/diagnostics`, `/runs/{id}`(+inspect/terminate),
`/dispatch` nudge, `/tasks/{id}/log`.

### P5-07 — Orchestration & assignees
`/orchestration` knobs (orchestrator profile, auto-decompose/promote),
`/assignees` + `/profiles` roster, home-channel subscriptions.

## Plugins hub

### P5-08 — Plugins management
`plugins.manage` (action=list rich metadata: description/source/status/
user_count; action=toggle enable/disable). A hub to browse and toggle plugins.

### P5-09 — Skills
`skills.manage` (multiplexer) + `skills.reload` — browse/enable skills (the
self-improving-agent surface).

**Exit criteria:** schedule automations, run and monitor background tasks and
worker fleets, drive a full kanban board in real time, and manage plugins/skills.
