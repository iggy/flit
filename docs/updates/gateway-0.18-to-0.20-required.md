# Required changes: gateway 0.18 → 0.20 compatibility

Audit of the hermes-agent gateway between **v0.18.0** (`7c1a02955`, 2026-07-01)
and **v0.20.0** (`3c27eb623`, 2026-08-03), mapped against what flit currently
implements. Each item below is a **breaking or behavior-altering** gap: the
gateway changed its wire behavior and flit will misread it (or the UI will
misbehave) without the listed change.

Grounding convention: `hermes-agent` citations are `file:line` in that repo,
current as of v0.20.0. flit citations are relative to `app/` here.

---

## 1. `session.compress` result: `summary`/`aborted` not modeled — HIGHEST PRIORITY

**Gateway change** (`hermes-agent/tui_gateway/methods_session.py:2540-2620`):
the compress result now returns, alongside the fields flit already reads:

```jsonc
{
  "status": "aborted" | "compressed",
  "removed": 12, "before_messages": 24, "after_messages": 12,
  "before_tokens": 9000, "after_tokens": 3000,
  "summary": { "aborted": true, /* … more keys, opaque */ },
  "usage": { /* session usage dict */ },
  "info": { /* session.info dict */ },
  "messages": [ /* canonical message list, post-compression */ ]
}
```

The `status: "aborted"` value (compression refused because a tool was
mid-flight, or the model declined) is a real outcome the gateway explicitly
ships — the desktop surfaces it as a distinct toast (see the turn-isolation
comment at `methods_session.py:2495-2507`).

**flit gap**: `app/lib/data/dto/session_dtos.dart:484` `CompressResultDto`
reads only `status`, `removed`, `before_messages`, `after_messages`,
`before_tokens`, `after_tokens`, `compressed`, `lock_held`, `message`. It
drops `summary` (incl. its `aborted` flag), `usage`, `info`, and `messages`.

**Work to do**:
- Add `summary` (map), `usage` (map), `info` (map), and `messages` (list of
  canonical messages) to `CompressResultDto`, plus `aborted` derived from
  `summary.aborted` (or `status == "aborted"`).
- Extend the domain model (`CompressResult`) and any notifier/UI that renders
  a compress toast so an aborted compression is shown distinctly from a
  success.
- The `messages` list uses the canonical message shape (see
  `hermes-agent/tui_gateway/server.py:7045` `_history_to_messages`) — the same
  shape `session.resume` returns, so reuse the existing resume-message parsing
  rather than inventing a new one.

---

## 2. `prompt.submit` ack statuses: `steered` / `redirected` / `queued` — HIGH

**Gateway change** (`hermes-agent/tui_gateway/server.py:7501-7586`
`_handle_busy_submit`): a prompt submitted while a turn is running no longer
rejects with "session busy". Under `display.busy_input_mode` it now returns one
of:

```jsonc
{"status": "steered"}     // injected into the live turn (steer mode)
{"status": "redirected"}  // live turn redirected in place (interrupt mode)
{"status": "queued"}      // queued to run after the current turn
```

The gateway also added error codes the client can hit:
- `4028` / `4029` — truncation refused: `truncate_before_user_ordinal` now
  requires `confirm_truncate=true` (and `confirm_empty_truncate=true` to wipe
  the whole transcript) or the gateway **refuses the cut and errors**.
- `5070` — disk full on session persist ("free some disk space and try again").
- `5071` — session storage could not be written.

**flit gap**: `app/lib/data/repositories/chat_repository_impl.dart:25`
`submitPrompt` asserts (debug-only) the result is `{"status":"streaming"}`.
The assertion won't crash in release, but the UI has no way to distinguish
"accepted and streaming" from "queued behind the running turn" or "steered
into the live turn" — a mid-turn send will look like a failure or a phantom
stream.

**Work to do**:
- Model the ack: return the actual status (`streaming` | `steered` |
  `redirected` | `queued`) from `submitPrompt` instead of discarding it, and
  surface it in the composer/send flow (e.g. "Queued — will run after the
  current turn").
- If flit ever re-sends an interrupted turn with `truncate_before_user_ordinal`
  (rewind/regenerate/edit), it must now send `confirm_truncate: true` (and
  `confirm_empty_truncate: true` for ordinal 0) or the gateway will reject with
  4028/4029.
- Map `5070`/`5071` to a visible "disk full / storage write failed" message.

---

## 3. `session.create` params: `fast`, `reasoning_effort`, `provider`, `parent_session_id` (contract v4) — HIGH

**Gateway change** (`hermes-agent/tui_gateway/methods_session.py:14-160`): the
gateway now honors per-session overrides on `session.create`:

| Param | Effect |
|---|---|
| `model` | per-session model override (already sent by flit) |
| `provider` | optional provider for the override |
| `reasoning_effort` | per-session effort, parsed via `parse_reasoning_effort` |
| `fast` | **presence is the contract**: `true` pins priority tier, `false` pins normal, omitted = inherit profile (added as desktop contract v4, `tui_gateway/server.py:5067` comment) |
| `parent_session_id` | branch: copies parent history, links back for sidebar nesting |
| `source` | session source label |

**flit gap**: `app/lib/data/repositories/session_repository_impl.dart:16-21`
`create()` sends only `profile` / `cwd` / `model`. The composer's sticky
model/effort/fast picks (whatever UI exists today) silently reset to profile
defaults on each new chat.

**Work to do**:
- Add `provider`, `reasoningEffort`, `fast` (bool? — must distinguish "not
  sent" from `false`), and optionally `parentSessionId` / `source` to the
  `create()` signature in the domain repository interface
  (`app/lib/domain/repositories/session_repository.dart:15-22`) and impl.
- Send `fast` explicitly whenever the UI has a sticky fast/normal pick —
  omitting it means "inherit profile".
- Note the new `session.create` result also includes `info.lazy: true` and
  `info.desktop_contract` — no action needed, but see optional doc item on
  desktop_contract.

---

## 4. `session.resume`: `omit_messages` + `lazy` params unused — MEDIUM

**Gateway change** (`hermes-agent/tui_gateway/methods_session.py:306-600`):
resume now supports:
- `omit_messages: true` — skip the WS transcript (desktop hydrates via the
  authenticated REST route instead); response carries `messages_omitted: true`
  and `message_count` from the raw history.
- `lazy: true` — subagent watch windows: register a live session with no agent
  build; `info.lazy` stays, `running`/`status` reflect the child-run registry.
- Response additions: `resumed` (durable id), `session_key`, `started_at`,
  `messages_omitted`, `auto_continue` (optional), and for lazy resumes
  `status: "streaming" | "idle"`.

**flit gap**: `resume()` sends only `session_id` and the resume DTO
(`session_dtos.dart:252-316`) already tolerates the extra fields. Not breaking
today, but flit cannot open subagent watch windows or offload transcript
hydration.

**Work to do** (only if these features are wanted):
- Add `omitMessages` and `lazy` params to the resume call.
- Parse `messages_omitted` and `auto_continue` in `SessionResumeResultDto`.

---

## 5. `session.interrupt` queue semantics — LOW (but related to #2)

**Gateway change** (`hermes-agent/tui_gateway/methods_session.py:2899-2970`):
interrupt now explicitly clears `queued_prompt` / `queued_prompts` and bumps
the queue generation, and `_clear_pending` is session-scoped (a global clear
would cancel clarify/sudo/secret prompts on unrelated sessions). Response shape
unchanged (`{"status":"interrupted"}`).

**flit gap**: none functionally — flit's interrupt call (`session_repository_impl.dart:68`)
is already correct (live id as `session_id`). **But** if flit gains queued
submits (item #2), it must know the queue is dropped on interrupt. Document
this in the submit/queue notifier when #2 lands.

---

## 6. `/api/status` new fields: `auth_flows` (native PKCE signal) — MEDIUM

**Gateway change** (`hermes-agent/hermes_cli/web_server.py:3023-3360`): the
status payload gained:

```jsonc
{
  "auth_required": true,
  "auth_providers": ["nous"],
  "auth_flows": ["cookie", "native_pkce"],   // native_pkce = RFC 8252 loopback flow available
  "profiles": [/* names */], "gateway_mode": "multiplexed",
  "gateways": [/* per-gateway detail — gated only */],
  "config_version": 3, "latest_config_version": 3,
  "can_update_hermes": true,
  "gateway_drainable": false, "restart_drain_timeout": 300,
  "fts_rebuild": { /* progress, when pending */ }
}
```

Host recon fields (`hermes_home`, `config_path`, `env_path`, `gateway_pid`,
`gateway_health_url`, `gateways`) are now emitted **only when
`auth_required == false`** — flit already handles that. Unknown keys are
ignored by JSON parsing, so nothing breaks today.

**flit gap**: `app/lib/data/dto/gateway_status_dto.dart` doesn't model
`auth_flows`; the OAuth-vs-password decision in
`app/lib/application/connection/connect_controller.dart:108-130` infers from
`supports_password` alone. That matches current providers, but the
`native_pkce` capability flag is the explicit contract going forward — a
gateway with only brokerable OAuth providers advertises it via `auth_flows`,
not by the absence of password providers.

**Work to do**:
- Add `auth_flows` (`List<String>?`), `profiles`, `gateway_mode` to
  `GatewayStatusDto` + `GatewayStatus` domain model.
- When `auth_flows` contains `native_pkce`, prefer the native PKCE loopback
  flow (`OAuthClient`) even if a password provider is also registered; fall
  back to the current `supports_password` inference when `auth_flows` is
  absent (older gateways).

---

## 7. Kanban: task/board fields dropped by the model — LOW/MEDIUM

**Gateway change** (`hermes-agent/hermes_cli/kanban_db.py:905-980` Task
dataclass; `plugins/kanban/dashboard/plugin_api.py`):
- `Task` now carries: `project_id`, `session_id`, `block_kind`,
  `block_recurrences`, `consecutive_failures`, `model_override`,
  `provider_override`, `reasoning_effort`, `goal_mode`, `goal_max_turns`,
  `skills`, `workflow_template_id`, `current_step_key`, `max_retries`,
  `max_runtime_seconds`, `current_run_id`, `claim_lock`/`claim_expires`,
  `last_failure_error`, `last_heartbeat_at`, `worker_pid`.
- Boards can be project-scoped (`CreateBoardBody.project_id`,
  `RenameBoardBody.project_id`); `GET /boards` entries now include
  `project_id` and `project_name` (`plugin_api.py:2357-2430`).

**flit gap**: `KanbanTask` (`app/lib/domain/models/kanban.dart:206-256`) and
`KanbanBoardMeta` (`app/lib/data/repositories/kanban_fleet_repository.dart:383`)
don't model any of these. Non-breaking (unknown keys ignored) but the board UI
can't render per-task model/reasoning badges or project-scoped boards, and
task creation can't set them.

**Work to do**:
- Add the fields above to `KanbanTask` (at minimum `modelOverride`,
  `providerOverride`, `reasoningEffort`, `projectId`, `blockKind`,
  `goalMode`, `consecutiveFailures`) and `KanbanBoardMeta` (`projectId`,
  `projectName`).
- Extend create/update task request bodies to set the new fields if the UI
  wants to control them.

---

## 8. Kanban `/tasks/{id}/estimate` — new endpoint, no client — LOW

**Gateway change** (`hermes-agent/plugins/kanban/dashboard/plugin_api.py:1812-1850`):
`POST /tasks/{id}/estimate` returns
`{ok, est_tokens, complexity, rationale, model}` (a non-OK result is a 200
with `ok: false` + `reason`, not an HTTP error). Runs several seconds
(auxiliary LLM call).

**flit gap**: no client method.

**Work to do**: add a `estimateTask(taskId, {board})` call to the kanban
repository and a domain model for the result. New capability — wire into the
task drawer only if desired.

---

## Suggested order

1. Item #1 (compress aborted) — behavior misread today.
2. Item #2 (busy-submit acks) — behavior misread today on mid-turn sends.
3. Item #3 (create params) — composer picks silently lost.
4. Item #6 (auth_flows) — future-proofing the auth decision.
5. Item #4/#5 (resume/interrupt) — feature-gated, do alongside #2.
6. Item #7/#8 (kanban) — non-breaking, low risk.
