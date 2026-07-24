# Phase 1 — MVP (the demo target)

**Goal:** the app you can show potential coworkers. Connect to a token-auth
gateway and do real work: chat with streaming + tool calls, answer approvals/
clarifications, pick a model, see profiles, list plugins, and open a live kanban
board.

**Exit criteria:** on a real gateway you can — connect; create a session; send a
prompt and watch it stream with tool cards; approve a tool and answer a clarify;
switch the model; see the profile dropdown (with the honest "new-launch" note);
list plugins; open the kanban board and move a card. `flutter analyze` clean;
the event-fold and RPC tests pass.

**Reference inputs:** all of `reference/` — especially
`03-mvp-wire-shapes.md`, `01-gateway-protocol.md` §6–9, `06-kanban-rest.md`.

Tickets are grouped; within a group they're ordered. Groups A–B are the spine;
C–F build on it.

---

## Group A — Domain models & DTOs

### P1-01 — Core domain models
**Goal:** the clean types the UI speaks.
**Deliverables:** `domain/models/`: `ChatMessage` (role, text, rendered?,
streaming flag, `List<ToolCall>`, terminal status), `ToolCall` (id, name,
context, status running/done/error, result (dynamic), summary?, inlineDiff?,
durationS?), `InteractivePrompt` (sealed: `ApprovalPrompt`, `ClarifyPrompt`),
`SessionSummary` (durable id, title, preview, messageCount, startedAt, source),
`ActiveSession` (short id, status enum, model, title), `ModelProvider` +
`ModelOption`, `PluginInfo`, `Usage`.
**Acceptance:** pure Dart, immutable, no imports outside `domain/`. Compile +
trivial construction test.
**Notes:** `ToolCall.result` is `dynamic` (dict or string per protocol §7).
`SessionStatus` enum should tolerate unknown strings (map unknown→`working`;
see roadmap open question #4).

### P1-02 — Wire DTOs + JSON
**Goal:** wire ↔ Dart translation isolated in the data layer.
**Deliverables:** `data/dto/`: DTOs with `json_serializable` for every §0–13
shape in `03-mvp-wire-shapes.md` (status, session create/list/active/resume,
prompt result, each event payload, model.options, config.set result,
plugins.list). Mappers DTO→domain.
**Acceptance:** round-trip tests decode each example frame from
`03-mvp-wire-shapes.md` without loss; snake_case handled via `@JsonKey`.
**Notes:** absorb the two-session-id quirk here — expose `liveId` and
`durableId` cleanly. Do **not** rely on `gatewayTypes.ts` shapes where
`00-overview.md` flags a divergence.

### P1-03 — Typed `GatewayEvent` union
**Goal:** pattern-matchable events.
**Deliverables:** `data/dto/events/`: a `freezed` sealed union over the event
`type` strings the MVP consumes (`gateway.ready`, `session.info`,
`message.start/delta/complete`, `error`, `tool.start/progress/complete`,
`approval.request`, `clarify.request`, `status.update`). A factory that parses a
raw event frame (`params.type` → variant), with an `UnknownEvent` fallback.
**Acceptance:** parsing each §7/§10/§11 example yields the right variant with
fields populated; unknown types → `UnknownEvent` (never throws).

---

## Group B — Chat spine (the heart of the demo)

### P1-04 — Session repository
**Goal:** intent-level session ops.
**Deliverables:** `data/repositories/session_repository.dart` +
`domain/repositories` interface: `create()`, `list()`, `activeList(currentId)`,
`resume(durableId)`, `interrupt(liveId)`. Uses `GatewayRpcClient.request`.
**Acceptance:** unit tests with a fake RPC client assert correct method names
+ params + result mapping (esp. create → returns live+durable ids; resume →
new live id + messages).

### P1-05 — Chat repository + turn-event stream
**Goal:** submit prompts and expose the turn event stream.
**Deliverables:** `data/repositories/chat_repository.dart`: `submitPrompt(liveId,
text)` (→ `config`-free `prompt.submit`, expects `{status:"streaming"}`),
`Stream<GatewayEvent> turnEvents(liveId)` (filter of the client event stream by
`session_id`), `respondApproval(...)`, `respondClarify(...)`.
**Acceptance:** fake-client tests: submit sends the right frame; `turnEvents`
filters by session id; approval/clarify send the right params (approval by
session, clarify by request_id — protocol §8).

### P1-06 — The event fold (message-list notifier) ⭐
**Goal:** fold turn events into an ordered `List<ChatMessage>`. **Highest-value,
most bug-prone code — test it hard.**
**Deliverables:** `application/chat/message_list_notifier.dart`: a Riverpod
notifier keyed by active session that subscribes to `turnEvents` and folds per
`04-app-architecture.md` "Event → state folding": start→append streaming msg;
delta→append text; tool.start→attach running ToolCall; tool.complete→resolve by
tool_id; complete/error→finalize; approval/clarify→surface `InteractivePrompt`.
**Acceptance:** unit tests feed the **exact** frame sequence from
`03-mvp-wire-shapes.md` §7 (incl. multiple deltas, an interleaved tool call, and
a terminal complete) and assert the resulting `List<ChatMessage>` (text
accumulation, tool card resolution, terminal status). Add cases: `error` instead
of complete; interrupt mid-stream → status `interrupted`; approval appearing
mid-turn.
**Notes:** keep the fold a pure function `(List<ChatMessage>, GatewayEvent) →
List<ChatMessage>` so it's trivially testable; the notifier is a thin wrapper.

### P1-07 — Chat screen UI
**Goal:** render the conversation.
**Deliverables:** `presentation/chat/`: message list (user/assistant bubbles;
assistant renders markdown from `rendered`/`text`), a live "typing" indicator
while streaming, tool cards (name + context; expandable result; monospace
`inline_diff`), and a composer (multiline text field + send + a stop button that
calls `interrupt` while running).
**Acceptance:** with the notifier fed fixture frames (widget test), the screen
shows accumulating text, a tool card that flips running→done, and a final
message. Manual: real prompt streams smoothly.
**Notes:** honor coalescing — the UI just reacts to notifier state; don't try to
animate per-token.

### P1-08 — Inline interactive prompts (approval + clarify)
**Goal:** unblock tool-using turns.
**Deliverables:** `presentation/chat/` widgets for `ApprovalPrompt` (command,
description, Approve/Deny, and "always allow" when `allow_permanent`) and
`ClarifyPrompt` (question + choice chips or free text). Wire answers through the
chat repository.
**Acceptance:** a fixture approval event renders the card; tapping Approve sends
`approval.respond{session_id,choice:"approve"}`; a clarify with choices renders
chips and sends `clarify.respond{request_id,answer}`. Manual: a `rm`-style tool
call actually proceeds after approval on a real gateway.
**Notes:** approval is correlated by **session**, clarify by **request_id** —
don't cross them (protocol §8).

### P1-09 — Session bootstrap flow
**Goal:** tie connect → session → chat.
**Deliverables:** after `gateway.ready`, auto-create (or resume most-recent) a
session and route to the chat screen; `activeSessionProvider` holds the live id;
all chat/prompt calls use it.
**Acceptance:** connecting lands you in a ready-to-type chat within one screen
transition.

---

## Group C — Sessions (minimum multi-session)

### P1-10 — Session drawer (list + switch + new + interrupt)
**Goal:** manage more than one conversation.
**Deliverables:** `presentation/sessions/`: a drawer/sheet listing sessions
(`session.list` for history + `session.active_list` for live status badges), a
"New session" action (`session.create`), tap-to-switch (`session.activate` /
`session.resume` as appropriate), and a per-row/global interrupt.
**Acceptance:** creating, listing, and switching sessions works on a real
gateway; the active session's live status badge reflects idle/working.
**Notes:** the "current" session is client-side state — pass `current_session_id`
into `active_list` (protocol §9). Switching to a durable-only session goes
through `resume` (new live id); switching to an already-live one uses its live
id.

---

## Group D — Model selection

### P1-11 — Model repository + picker controller
**Goal:** read options, set the model.
**Deliverables:** `data/repositories/model_repository.dart`: `options()` →
`model.options`; `setModel(model, provider)` → `config.set{key:"model",
value:"<model> --provider <slug>"}`, handling the `confirm_required` re-send
(protocol/wire §9). `application/models/model_picker_controller.dart`.
**Acceptance:** fake-client tests assert the exact `config.set` value string and
the confirm re-send path (`confirm_expensive_model:true`).

### P1-12 — Model picker UI
**Goal:** pick a model.
**Deliverables:** `presentation/models/`: a sheet grouping models by provider
(from `model.options`), showing auth state (authenticated / needs key /
current), and an expensive-model confirm dialog. On select, call the controller;
reflect the new model from the subsequent `session.info` event.
**Acceptance:** picker lists providers+models with correct current/auth badges;
selecting switches the model (confirm dialog appears for flagged models). A
provider with no key is shown disabled with a "needs key" hint (key entry is
Phase 4 — just signal it here).

---

## Group E — Profiles (dropdown, with the honest caveat)

### P1-13 — Profile repository (REST) + dropdown
**Goal:** satisfy "a dropdown that lists agent profiles."
**Deliverables:** `data/repositories/profile_repository.dart` (REST):
`list()` → `GET /api/profiles`, `active()` → `GET /api/profiles/active`,
`setActive(name)` → `POST /api/profiles/active`. A dropdown in the app bar / a
menu showing profiles with the active one checked.
**Acceptance:** the dropdown shows real profiles and the active one; picking one
persists via `POST /api/profiles/active` and shows a clear, honest note that it
affects **new gateway launches**, not the current live session (roadmap "profiles
caveat"). No pretense of hot-swapping.
**Notes:** REST auth = `X-Hermes-Session-Token`. If `/api/profiles` 404s (older
gateway), degrade to a disabled dropdown with a tooltip — don't crash.

---

## Group F — Plugins & kanban

### P1-14 — Plugins list
**Goal:** discover plugins.
**Deliverables:** `data/repositories/plugin_repository.dart`: `list()` →
`plugins.list` (`{name,version,enabled}`). A simple plugins screen listing them;
kanban gets an "Open board" affordance when present+enabled.
**Acceptance:** the list renders real plugins; version falls back to "?" cleanly
(protocol/wire §13).

### P1-15 — Kanban board (read + detail + move)
**Goal:** the flagship plugin surface.
**Deliverables:** `data/repositories/kanban_repository.dart` (REST):
`board({board?})` → `GET /api/plugins/kanban/board`, `task(id)` →
`GET /tasks/{id}`, `updateTask(id, {status})` → `PATCH /tasks/{id}`. UI in
`presentation/plugins/kanban/`: horizontally-scrollable columns
(triage/todo/scheduled/ready/running/blocked/review/done) with task cards; tap a
card → detail drawer (body, comments, latest_summary); move a card between
columns via a menu or drag → `PATCH` the new status.
**Acceptance:** the board renders columns+cards from a real gateway; tapping a
card opens details; changing a card's column persists (re-fetch or optimistic
update reflects it).
**Notes:** column order is fixed (see `06-kanban-rest.md`). Live `/events` WS is
a nice-to-have here — if time-boxed, poll `GET /board` on focus and defer the
live feed to Phase 5.

---

## Group G — Demo polish

### P1-16 — Connection UX + errors
**Goal:** a demo that never mystifies.
**Deliverables:** loading/reconnecting chips; friendly messages for 4401 (bad
token), unreachable host, and `gateway_running:false`; a visible gateway
version/build somewhere; empty-states for chat/sessions/board.
**Acceptance:** each failure mode shows a clear, actionable message; reconnect
after a dropped socket recovers and resumes the active session.

### P1-17 — MVP integration pass + demo script
**Goal:** verified end-to-end + a script to run the demo.
**Deliverables:** a short `docs/phases/phase-1-demo-script.md` walking the demo
(connect → chat with a tool → approve → switch model → show profiles → open
kanban). Fix whatever the pass surfaces.
**Acceptance:** the full script runs on a real gateway on at least one desktop
target and one mobile target/emulator.

---

## What's deliberately NOT in the MVP

Slash commands, subagent visualization, config/provider-key editing, cron, full
kanban fleet ops, memory/learning, voice, attachments beyond text, billing,
OAuth. All are later phases — see the roadmap. Keeping them out is what makes
the MVP demoable quickly.
