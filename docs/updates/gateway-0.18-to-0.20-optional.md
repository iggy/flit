# Optional / TODO: gateway 0.18 → 0.20 follow-ups

Non-breaking items from the same audit (see
`gateway-0.18-to-0.20-required.md` for the required ones). These are new
capabilities, polish, or roadmap candidates. Nothing here will misbehave
today — `unknown`-event fallbacks and ignored JSON keys keep the client
working — but each is a visible gap against a current gateway.

---

## 1. Streamed reasoning: `reasoning.delta` events treated as `unknown`

**Gateway** (`hermes-agent/tui_gateway/server.py:5681`): a child/session with
extended thinking streams `reasoning.delta` `{text}` frames while the turn is
in flight; the full reasoning also lands on `message.complete.reasoning` (which
flit already reads).

**flit**: `app/lib/data/dto/events/gateway_event_parser.dart` has no
`reasoning.delta` case — it falls through to `unknown` and is dropped by the
fold. Users never see thinking stream in live.

**TODO**: add a `reasoningDelta` event (sessionId, text), accumulate it in the
streaming bubble next to the text (a "Thinking…" disclosure like the
`message.complete.reasoning` path already uses), and clear on
`message.complete`.

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

## 3. `desktop_contract` version handshake

**Gateway** (`hermes-agent/tui_gateway/server.py:5067`): every
`session.create`/`session.resume`/`session.info` carries
`info.desktop_contract` — currently `5` (raised uvicorn WS frame cap so
`file.attach` base64 frames >16 MiB survive). History: v1 baseline, v2
file.attach, v3 approvals.mode + session.info reconciliation, v4 create
`fast=false` explicit-normal, v5 ws_max_size.

**flit**: never checks it. `file.attach` already speaks the v5 wire shape, so
today it works against v0.20, but there's no guard: against an older gateway a
large attach silently dies on the 16 MiB frame cap.

**TODO**: read `desktop_contract` from the session bootstrap payload; when
below a pinned minimum, show "update your Hermes gateway" instead of failing
mysteriously. Keep the pin aligned with whatever contract version flit
actually requires.

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

## 6. Kanban: `workflow_template_id` / `current_step_key` board filters

**Gateway** (`hermes-agent/plugins/kanban/dashboard/plugin_api.py:378-410`):
`GET /board` accepts `workflow_template_id` and `current_step_key` filters
alongside `tenant`/`include_archived`/`board`.

**flit**: `kanban_repository.dart:33` fetches `/board` without these query
params.

**TODO**: add optional filter params to the board fetch when the UI needs
workflow-filtered views.

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

## 8. Status endpoint fields (non-breaking follow-through)

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

**TODO**: wire whichever of these the app actually wants to display.
