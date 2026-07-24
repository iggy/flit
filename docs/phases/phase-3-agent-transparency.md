# Phase 3 — Agent transparency & control

**Goal:** expose what the agent is *doing* and let the user drive it the way the
TUI/desktop power-users do — slash commands, subagent visibility, steering, and
the remaining interactive prompts.

**Reference:** `reference/02-rpc-index.md` §Slash, §Subagents, §Interactive;
`gatewayTypes.ts` `SubagentEventPayload` (:539), `DelegationStatusResponse`
(:568).

## Slash commands (parity with the TUI launcher)

### P3-01 — Command catalog & launcher
`commands.catalog` → categories + pairs; a slash launcher UI (searchable list of
commands with descriptions). `command.resolve` to resolve aliases.

### P3-02 — Autocomplete
`complete.slash` (slash grammar) and `complete.path` (`@`-tokens, file paths) to
power inline autocomplete in the composer.

### P3-03 — Dispatch & exec
`command.dispatch` (structured: interpret the typed result — exec/plugin/alias/
skill/send/prefill) and `slash.exec` (subprocess, returns rendered text). Per the
map, a client can mostly call `slash.exec` and only needs `command.dispatch` for
skill/pending-input commands. Render `slash.exec` output; handle the
`prefill`/`send` result types by populating/submitting the composer.

## Subagents & delegation (the "starmap"/"agents" surface)

### P3-04 — Subagent event stream → tree model
Fold `subagent.spawn_requested/start/thinking/tool/progress/complete` events
(payload `SubagentEventPayload`: goal, model, depth, parent_id, tokens, status,
tool info) into a live spawn-tree model keyed by `subagent_id`/`parent_id`.

### P3-05 — Delegation dashboard
`delegation.status` (active subagents, spawn limits, paused flag) rendered as a
live tree/list; `delegation.pause` (pause/resume spawning); `subagent.interrupt`
(kill one). `agents.list` for background agent processes.

### P3-06 — Spawn-tree snapshots (/replay)
`spawn_tree.list` / `spawn_tree.load` / `spawn_tree.save` — browse and replay
saved subagent trees.

## Steering & remaining prompts

### P3-07 — Steer a running turn
`session.steer` — inject guidance mid-turn (queued/rejected result); a "steer"
affordance while the agent is working.

### P3-08 — sudo / secret / terminal.read prompts
Complete the interactive set from Phase 1: `sudo.request`→`sudo.respond`
(password), `secret.request`→`secret.respond` (value, e.g. an API key the agent
needs), terminal read→`terminal.read.respond`. All correlated by `request_id`
(protocol §8.1). Secure text entry for sudo/secret.

**Exit criteria:** the user can invoke slash commands with autocomplete, watch
subagents spawn/work/finish in a live tree, pause/interrupt delegation, steer a
running turn, and answer every interactive prompt type.
