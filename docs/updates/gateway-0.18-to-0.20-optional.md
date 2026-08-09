# Optional / TODO: gateway 0.18 → 0.20 follow-ups

Non-breaking items from the same audit (see
`gateway-0.18-to-0.20-required.md` for the required ones). These are new
capabilities, polish, or roadmap candidates. Nothing here will misbehave
today — `unknown`-event fallbacks and ignored JSON keys keep the client
working — but each is a visible gap against a current gateway.

---

## 1. Streamed reasoning: `reasoning.delta` events treated as `unknown` — ✅ DONE

**Gateway** (`hermes-agent/tui_gateway/server.py:5731`, and `:5681` for the
child-mirror path): a session with extended thinking streams `reasoning.delta`
`{text, verbose?}` frames while the turn is in flight; the full reasoning also
lands on `message.complete.reasoning` (which flit already read but never
rendered).

**flit**: `gateway_event_parser.dart` had no `reasoning.delta` case — it fell
through to `unknown` and was dropped by the fold. Users never saw thinking
stream live.

**Done**: `reasoningDelta` and `reasoningAvailable` (its non-streaming sibling,
`server.py:5500`) are typed events; the fold accumulates them into
`ChatMessage.reasoning` alongside — never into — the reply text, and flips
`reasoningStreaming` off at the terminal frame. The assistant bubble grew a
collapsed-by-default disclosure ABOVE the reply: "Thinking…" while deltas
arrive (trailing the newest line in the collapsed header so a long silent
thinking phase still looks alive), settling to "Thought" once the turn ends.

Deliberate divergence from this item's original TODO, which said to *clear* on
`message.complete`: the reasoning is **kept**, collapsed. Discarding it would
throw away the only rendered copy of a thought the user may want to read after
the answer lands, and `message.complete.reasoning` was already going unrendered.

Four shape traps:
- **Absent ≠ empty.** `reasoning` is nullable and the disclosure is hidden
  entirely when null, so a non-thinking model grows no empty affordance.
- **A streamed reasoning beats `message.complete.reasoning`.** The payload copy
  can arrive clamped (`/reasoning clamp`), so the accumulated stream wins and
  the payload field only fills in when nothing streamed. Same rule makes
  `reasoning.available` a fallback: ignored once deltas exist.
- **Thinking can be a turn's FIRST frame**, before `message.start` — so the
  delta handler creates the streaming bubble defensively, exactly as
  `message.delta` does, and never merges into a finalized turn.
- **The accumulation needs a cap.** Every delta rebuilds the string and a long
  extended-thinking turn runs to hundreds of KB, so it is trimmed to the newest
  60k past 80k (the reference TUI's numbers) — the tail is what's being watched.

Resumed history keeps its thinking too: `_history_to_messages` forwards
`reasoning` on assistant entries (`server.py:7118`) and specifically retains
text-less thinking-only turns for exactly this disclosure, so `ResumeMessageDto`
now reads the field instead of replaying such a turn as a blank bubble. The
three sibling keys it can send instead (`reasoning_content`,
`reasoning_details`, `codex_reasoning_items`) are still ignored — they are
documented as opaque pass-through and are not plain strings.

Not done: reasoning renders as prose, not markdown (half-streamed markdown
renders as noise).

---

## 2. New event types worth explicit handling (currently `unknown`)

All emitted by a current gateway, none consumed by flit:

| Event | Emitted from | What it carries |
|---|---|---|
| `message.interim` | `server.py:5800` | interim assistant commentary (gated by `display.interim_assistant_messages`, default on) |
| `notification.show` / `notification.clear` | `server.py:5740-5752` | transient notices `{text, level, kind, ttl_ms, key, id}` |
| `tool.generating` | `server.py:5726` | model-generating indicator `{name}` |
| `tool.output_risk` | `server.py:5487-5498` | dangerous-output warning (mirrors messaging gateway) |
| `status.update` | `server.py:1861` | `{kind, text}` — already parsed by flit (fine) |

`message.interim` is the highest-value one: it's the "assistant comment while
calling tools" stream the desktop renders inline.

**TODO**: parse `message.interim` into the streaming pipeline, `tool.generating`
into the tool card (spinner state), `notification.show/clear` into a snackbar
system.

---

## 3. `desktop_contract` version handshake — ✅ DONE

**Gateway** (`hermes-agent/tui_gateway/server.py:5067`): every
`session.create`/`session.resume`/`session.info` carries
`info.desktop_contract` — currently `5` (raised uvicorn WS frame cap so
`file.attach` base64 frames >16 MiB survive). History: v1 baseline, v2
file.attach, v3 approvals.mode + session.info reconciliation, v4 create
`fast=false` explicit-normal, v5 ws_max_size.

**flit**: never checked it. `file.attach` already speaks the v5 wire shape, so
it worked against v0.20, but there was no guard: against an older gateway a
large attach silently died on the 16 MiB frame cap.

**Done**: `DesktopContract` (domain) holds the reported version and pins the
minimum flit needs at **5** — v4 for the explicit `fast: false` in
`session.create`, v5 because attachments go out as base64 in a single WS frame
with no size negotiation. `desktopContractProvider` learns the version from
`info.desktop_contract` on every `session.create` / `session.resume` result and
keeps it current from `session.info` events, and forgets it on sign-out.

Two visible consequences:
- The About screen grew a **Client Contract** row: the version alone when
  current, and when behind, "update your Hermes gateway" naming what will
  actually break (large attachments) — the remedy is host-side, so there's no
  in-app button to offer.
- The composer refuses an attachment that cannot fit a pre-v5 frame *before*
  sending it, naming the limit. This is the failure the item is about: an
  oversized frame doesn't error, uvicorn drops the socket, and the user sees a
  random disconnect.

The traps here are all about *unknown*:
- **`desktop_contract` is not queryable.** It only rides on session payloads,
  so the version is unknown until a session is bootstrapped — and unknown must
  read as "not told", never as "old". Nothing warns and nothing is blocked
  while the version is null; the About row hides entirely.
- **A minimal info dict must not un-learn a version.** A lazy resume answers
  with `{cwd, branch, project, lazy}` and no contract key, so `recordInfo`
  ignores an absent key rather than clearing state — otherwise the warning
  would flicker off mid-connection.
- **A NEWER contract than the pin is fine**, not a mismatch: the comparison is
  `version < minimum`, so flit keeps working against a gateway ahead of it.
- **The frame budget isn't the whole 16 MiB.** The JSON-RPC envelope shares the
  frame, so the client-side cap subtracts an allowance. Erring generous is
  right: a refusal names a real limit, a blown frame kills the socket silently.

---

## 4. `close_on_disconnect` is now opt-in

**Gateway** (`hermes-agent/tui_gateway/methods_session.py:83`): default changed
to `False` — sessions survive client disconnect and are later reclaimed by the
idle/session-cap reaper instead of dying with the WS.

**flit**: doesn't send the param, so chats persist after disconnect by default
(probably desired). If flit ever wants "close this chat when I disconnect",
it must send `close_on_disconnect: true` on create/resume explicitly.

**TODO**: none unless the app wants disconnect-close semantics; if so, add the
param to the create/resume call sites.

---

## 5. Gateway RPC methods flit doesn't call (roadmap candidates)

Added to the gateway since 0.18; flit has no client method for any of them:

| Method | Purpose |
|---|---|
| `session.history` | full transcript by live id (LONG) |
| `session.status` | pre-formatted status block |
| `session.activate` | bring a session to the foreground |
| `session.redirect` | move session to another transport |
| `session.cwd.set` / `session.workspace.move` | workspace control |
| `subagent.steer` | mid-run steering of a delegated child |
| `message.react` | emoji reactions on persisted messages (feeds the gateway's `message_reactions` display feature) |
| `handoff.request` / `handoff.state` / `handoff.fail` | cross-platform handoff |
| `subscription.state/change/preview/resume/upgrade` | billing plan management (flit has billing.state/charge already) |
| `usage.bars` | two-bar dollar usage model |
| `llm.oneshot` | single model call (preview utilities) |
| `cli.exec` | run a CLI command through the gateway |
| `pet.*` (15 methods) | desktop pet feature |
| `system.battery` | battery status for the status bar |
| `terminal.resize` / `terminal.read.respond` / `preview.read.respond` | GUI terminal/preview bridge |
| `projects.record_repos` / `projects.tree` | project repo tracking |
| `preview.restart` companion events | `preview.restart.progress` / `.complete` (flit already parses these) |

**TODO**: triage onto the roadmap/phase tickets when the corresponding UI
feature is planned. `session.history` is the most useful standalone (it's the
replay path for the transcript view).

---

## 6. Kanban: `workflow_template_id` / `current_step_key` board filters — ✅ DONE

**Gateway** (`hermes-agent/plugins/kanban/dashboard/plugin_api.py:379-408`):
`GET /board` accepts `workflow_template_id` and `current_step_key` filters
alongside `tenant`/`include_archived`/`board`.

**flit**: `kanban_repository.dart` fetched `/board` without these query
params.

**Done**: `KanbanRepository.board` takes both as optional params;
`kanbanBoardFilterProvider` holds the active pair and `kanbanBoardProvider`
watches it, so applying a filter re-fetches (the narrowing is SQL server-side,
not a client-side list filter — `kanban_db.list_tasks`). The board screen grew
a filter action opening a sheet of two pickers, plus a banner naming the active
predicates with a Clear button.

Both filters are pickers, not text fields: a template id is an opaque string
and a typo would come back as an empty board indistinguishable from a correct
filter that matches nothing. The choices are harvested from the tasks on the
board (`kanbanWorkflowOptionsProvider`), which is also how the feature
self-hides against an older gateway — it sends neither field on a task, FastAPI
would ignore both query params, so with no workflow tasks anywhere the filter
action never renders.

The traps are all about not stranding the user on their own filter:
- **The options must come from an UNFILTERED board.** A filtered fetch no
  longer contains the sibling templates' tasks, so harvesting off one would
  shrink the picker to the choice just made, with no way back. The options
  notifier ignores loads made while a filter is active.
- **A filtered board looks exactly like a board whose tasks vanished**, hence
  the banner. Without it the honest server behaviour reads as data loss.
- **The two predicates are INDEPENDENT** — they're separate `AND` clauses, so a
  step key with no template matches that step across every workflow. Picking a
  template does narrow the step picker to that template's steps and drops a
  step that isn't one of them, since that pair can only ever return nothing.
- **Switching boards drops the filter.** Template ids belong to one board's
  tasks; carrying one across would silently empty the new board.
- **Absent ≠ empty on the wire.** A present param is an equality predicate, so
  an unset filter is omitted from the query entirely; `''` would filter for
  tasks whose value IS empty. Null is the only "no filter".

Not wired: the `tenant` and `include_archived` params of the same endpoint —
`tenants` already rides on the board envelope but nothing filters by it, and
archived tasks are a separate column-visibility question.

---

## 7. Docs are stale — ✅ DONE

`docs/reference/01-gateway-protocol.md`, `03-mvp-wire-shapes.md`,
`07-session-depth-wire-shapes.md` cited:
- `version: "0.17.0"` / `2026-06-30` examples (now `0.20.0` / `2026.8.3`).
- `server.py:5909` / `server.py:6472` / `server.py:9298`-style line numbers
  that had drifted thousands of lines (the tui_gateway refactor split
  handlers into `methods_*.py`; e.g. `_history_to_messages` is now
  `tui_gateway/server.py:7045`).

**Done**: swept `00`, `01`, `02`, `03`, `06`, `07`, `08`, `09` — version strings
updated and all 154 `file:line` citations re-verified against v0.20.0 source
(the sweep covered five more docs than this item named, since `00`, `02`, `06`,
`08`, and `09` had drifted too). Notable corrections beyond line numbers:

- **`gateway.ready` payload changed shape and flit is behind.** It is now
  `{"skin": {...}, "change_events": true}` (`ws.py:313-327`); it used to *be*
  the skin dict, which is still what `skin.changed` sends. `gateway_event_parser.dart:256`
  passes the whole payload to `parseGatewaySkinPayload`, so the skin is dropped
  on connect and only lands on the next `skin.changed`. **New gap — needs a fix
  ticket** (nest-aware parse, accepting both shapes).
- **`tool.progress` is never emitted** by this gateway — `_on_tool_progress`
  has no branch for it and the `tool.started` progress row is deliberately
  suppressed (`server.py:5482`). flit's `toolProgress` parse + fold branch is
  dead code.
- **`approval.respond` returns `{resolved: <int>}`**, not `{status:"ok"}` —
  the count of queue entries unblocked, `0` when nothing was pending. flit
  ignores the result, so it is unaffected.
- **`credits.view` was never a registered RPC** — removed from the `02` index.
- **`/api/profiles/active` gained `current`** alongside `active` (sticky
  default vs the profile the running gateway is actually scoped to).
- Method count is **145**, not 128; the profiles REST router moved to
  `hermes_cli/web_routers/profiles.py`. Added the previously-undocumented
  `session.redirect`, `session.workspace.move`, `subagent.steer`,
  `message.react`, `system.battery`, `usage.bars`, `subscription.*`,
  `preview.read.respond`, `projects.tree`/`record_repos`/`discover_repos`/
  `project_sessions`, and the six `wake.*` methods.
- Blocking prompts now emit `<name>.expire` on timeout and accept a late reply
  as `{status:"expired"}`; `preview.read` is a fifth blocking bridge (45s).
- `desktop_contract` is **5**, not 4 (`07` said 4).

---

## 8. Status endpoint fields (non-breaking follow-through) — ✅ DONE

From the required-doc item #6 — the DTO additions are required, but the
following are purely informational once the DTO is extended:
- `gateway_drainable` + `restart_drain_timeout` (NAS lifecycle — could drive a
  "restarting, wait…" UX).
- `fts_rebuild` (search-index rebuild progress → "searching is slower while the
  index rebuilds" indicator).
- `profiles` / `gateway_mode` / `gateways` (multi-profile gateway topology —
  useful for a profile switcher UI).
- `config_version` / `latest_config_version` / `can_update_hermes` (an
  "update available / config migration needed" banner).

**Done**: all four groups are on `GatewayStatusDto` + `GatewayStatus`, with two
nested models (`GatewayTopologyEntry`, `FtsRebuild`) and the derived
`configMigrationNeeded` / `ftsRebuildPending` / `liveGatewayProfiles`. Every
field is nullable — a pre-0.20 gateway sends none of them.

Surfaced modestly, since none of this is actionable in-app (the remedies are
host-side CLI):
- The About screen grew a **Gateway host** section: config schema version (and
  "run `hermes config migrate` on the host" when behind), whether the host owns
  its own updates, drain readiness + the resolved timeout, a search-index
  rebuild progress bar with the "search is slower and incomplete" caveat, and
  the profile/gateway topology in words. Each row renders only when the gateway
  sent its field, so the whole section disappears against an older gateway.
- The profile menu marks the profiles a live gateway is serving and notes when
  one gateway multiplexes several.

Four things the shapes make easy to get wrong:
- **Absent ≠ false for `fts_rebuild`.** The gateway omits the block when no
  rebuild is pending rather than sending `pending: false`, so null is the
  HEALTHY state and the row is hidden. A refresh must be able to clear it.
- **`gateways` is recon, `profiles`/`gateway_mode` are product.** The gateway
  withholds `gateways` (it carries host ports) unless `auth_required == false`,
  so on a gated gateway the profile list arrives with no liveness detail. An
  un-annotated profile row therefore means "not told", never "not running".
- **`config_version: 0` is a value** — a legacy config with no
  `_config_version` key at all (`config.py:1783`), not a missing field. And
  `configMigrationNeeded` is false whenever EITHER version is unknown, so an
  older gateway can never provoke a migration banner.
- **A multiplexing gateway serves profiles that have no `gateways[]` entry of
  their own**, so liveness reads `profile` + `served_profiles` from every entry
  rather than just the keys.

The status is probed ONCE on connect and there is no status event on the WS, so
these fields go stale (a rebuild's percent above all). `GatewayStatusNotifier
.refresh()` re-probes on demand behind the About screen's refresh action —
deliberately not a poll, and a failed re-probe keeps the last readout instead of
blanking it.

Not wired: `components` / `overall` (the health rollup — `HealthScreen` already
covers provider/runtime/verification health from the RPC side, and mixing a
second, differently-shaped source into it is its own ticket).
