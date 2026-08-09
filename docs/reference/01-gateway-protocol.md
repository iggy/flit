# Reference: The gateway protocol

Everything a client must know to talk to the gateway correctly. Grounded in
`hermes-agent` source; citations are `file:line` in that repo, **re-verified
against v0.20.0 (release date `2026.8.3`)**. Note that the `tui_gateway`
refactor split the RPC handlers out of `server.py` into `methods_session.py`,
`methods_tools.py`, `methods_prompt.py`, `methods_config.py`, and
`methods_complete.py` — citations name the file explicitly.

---

## 1. Discovering a gateway: `GET /api/status`

Before connecting, hit the **public, unauthenticated** status endpoint to learn
whether the gateway is up and which auth mode it uses.

`GET <base>/api/status` (optional `?profile=<name>`). It's in
`PUBLIC_API_PATHS` (`hermes_cli/dashboard_auth/public_paths.py:44`), so no auth.

Always-present fields (`web_server.py:3022-3356`, handler `get_status`):

```jsonc
{
  "version": "0.20.0",
  "release_date": "2026.8.3",
  "gateway_running": true,
  "gateway_state": "ready",          // or null
  "gateway_busy": false,
  "active_sessions": 2,
  "active_agents": 1,
  "auth_required": false,            // ← THE decisive field (see §2)
  "auth_providers": []               // e.g. ["nous"] in OAuth mode
}
```

**Only when `auth_required == false`** (loopback/insecure) it also returns host
recon fields — `hermes_home`, `config_path`, `env_path`, `gateway_pid`,
`gateway_health_url`, `gateways` (per-gateway host ports). In OAuth mode those
are omitted (`web_server.py:3343`).

v0.20 also adds these informational fields, all modelled on
`GatewayStatusDto` / `GatewayStatus` except the health rollup (see
`../updates/gateway-0.18-to-0.20-optional.md` §8):

```jsonc
{
  "config_version": 3, "latest_config_version": 3,   // 0 = legacy config, no _config_version key
  "can_update_hermes": true,                         // false when a container/launcher owns updates
  "gateway_drainable": false,                        // live AND state == running (gateway/status.py:1140)
  "restart_drain_timeout": 300.0,                    // seconds; float on the wire
  "profiles": ["default", "research"],
  "gateway_mode": "multiplex",                       // multiplex | single | multiple | none | unknown
  "components": { /* gateway/dashboard/storage/platforms */ }, "overall": "ok",
  "fts_rebuild": {"pending": true, "total": 5000, "indexed": 1250, "percent": 25}
}
```

Two absence rules that matter:
- `fts_rebuild` is present **only while a rebuild is pending**
  (`hermes_state_search.py:83`) — the gateway omits the block rather than
  sending `pending: false`, so absent means "index healthy".
- `gateways` is grouped with the host recon fields above, **not** with
  `profiles` / `gateway_mode`: it carries host ports, so a gated gateway sends
  the profile list and topology mode with no per-gateway liveness detail. Each
  entry is `{profile, ports: {platform: port}, served_profiles?}`, and
  `served_profiles` is what tells you a multiplexing gateway is also serving
  profiles that have no entry of their own (`web_server.py:2888`).

`components` / `overall` are not modelled (flit's Health screen reads the RPC
health calls instead).

v0.20 also adds **`auth_flows`** (`web_server.py:3190-3204`), the auth
capability advertisement the client must use to pick a login flow:

```jsonc
"auth_flows": ["cookie", "native_pkce"]
```

- `[]` in loopback mode (`auth_required == false`).
- `"cookie"` is always present in gated mode.
- `"native_pkce"` is present only when at least one registered **session**
  provider is a brokerable OAuth provider (`supports_password` false) — i.e.
  when `/auth/native/authorize` has an IDP round trip to broker. A password
  provider is rejected there with 400 (`dashboard_auth/routes.py:330-338`).
- **Absent** on gateways older than 0.20 — treat missing ≠ empty and fall back
  to inferring the flow from `/api/auth/providers` `supports_password`.

flit reads it in `ConnectController.probe`: `native_pkce` + at least one
brokerable provider → OAuth mode, even when a password provider is registered
too (the password providers are offered as an explicit fallback).

- `auth_required == false` → **token mode** ("plaintext auth"): connect the WS
  with `?token=<session token>`.
- `auth_required == true` → **gated mode**: log in (user/pass, §2.2; OAuth,
  §2.3) to get session cookies, then mint a single-use WS ticket per connect.
  `auth_providers` lists the registered provider names; the interactive set
  (with `supports_password` flags) comes from `GET /api/auth/providers`.

---

## 2. Authentication

> **Critical:** WebSocket auth is **query-string only**. Browsers/clients can't
> set custom headers on a WS upgrade, so there is **no** `Authorization` /
> cookie header check on `/api/ws`. REST is the opposite: it uses headers
> (session-token header in loopback mode, cookies in gated mode). Do not try
> to auth the WS via headers.

There are **three** auth shapes, detected from `GET /api/status`:

| Shape | Detect | REST credential | WS credential |
|---|---|---|---|
| **Loopback token** | `auth_required == false` | `X-Hermes-Session-Token: <token>` | `?token=<token>` |
| **Gated user/pass** | `auth_required == true` + provider with `supports_password` | session **Cookie** header | `?ticket=<single-use>` |
| **Gated OAuth** | `auth_required == true`, password-less providers (Phase 8) | session Cookie | `?ticket=<single-use>` |

### 2.1 Token mode ("plaintext auth") — loopback / `--insecure`

The gateway holds a session token in `_SESSION_TOKEN`
(`web_server.py` — `HERMES_DASHBOARD_SESSION_TOKEN` env, else a random
`secrets.token_urlsafe(32)`). Auth is a constant-time compare against it.

- **WebSocket:** append `?token=<urlencoded token>` to the `/api/ws` URL.
  Scheme `ws` for `http:` / `wss` for `https:`; preserve any path prefix.
- **REST (sensitive routes):** send header `X-Hermes-Session-Token: <token>`
  (legacy `Authorization: Bearer <token>` also accepted). Public routes
  (`/api/status`, `/api/auth/providers`) need nothing.
- **Where does the token come from?** The dashboard injects it into the
  served HTML and prints/logs it. In the app, the user pastes it.

### 2.2 Gated mode: username/password login (implemented post-MVP)

When `auth_required == true`, the dashboard-auth gate
(`hermes_cli/dashboard_auth/`) protects every non-public route, and the
legacy `?token=` WS path is **unconditionally rejected**
(`web_server.py` `_ws_auth_reason`: "The legacy ``?token=`` path is
unconditionally rejected in gated mode").

The flow, grounded in `dashboard_auth/routes.py` + `middleware.py` +
`cookies.py` + `ws_tickets.py`:

1. **Discover providers** (public): `GET <base>/api/auth/providers` →
   `{"providers":[{"name","display_name","supports_password"}]}`
   (`routes.py:153`; 503 when none registered).
2. **Log in:** `POST <base>/auth/password-login` with JSON body
   `{provider, username, password, next}` (`routes.py:651`,
   `_PasswordLoginBody` at `routes.py:643`). Success → `200
   {"ok":true,"next":<path>}` and the response **sets the session cookies**.
   Failures are deliberately generic: 401 invalid credentials, 404
   unknown/password-less provider, 429 rate limited, 500 provider
   misconfigured, 503 provider unreachable (`routes.py:675-717`).
3. **Session cookies** (`cookies.py`): `hermes_session_at` (access token),
   `hermes_session_rt` (refresh token, when the provider issues one),
   `hermes_session_provider`. The exact cookie **names vary by deploy** —
   `__Host-`/`__Secure-`/bare prefixes depending on HTTPS + path prefix
   (`cookies.py:107` `_resolved_name`, variants at `cookies.py:87`) — so a
   client must capture them **verbatim from `Set-Cookie`**, never reconstruct
   names.
4. **REST auth:** send the captured cookies as a `Cookie` header on every
   gated request. The gate middleware verifies the access token and, when
   expired, **refreshes it via the refresh token and re-sets rotated cookies
   on the response** (`middleware.py`) — the client must update its cookie
   store from `Set-Cookie` on **every** response.
5. **WS auth — single-use ticket:** `POST <base>/api/auth/ws-ticket`
   (cookie-authed, `routes.py:799`) → `{ticket, ttl_seconds: 30}`. Connect
   `/api/ws?ticket=<ticket>`; the ticket is **consumed** on the upgrade
   (`web_server.py:14756` `_ws_auth_reason` → `consume_ticket`). **Mint a fresh
   ticket for every connect and every reconnect attempt.**
6. **Identity (optional):** `GET <base>/api/auth/me` (cookie-authed) →
   `{user_id, email, display_name, org_id, provider, expires_at}`
   (`routes.py:778`).
7. **Logout:** `POST <base>/auth/logout` (cookie-authed) revokes the
   refresh token best-effort and clears cookies (`routes.py:742`).

### 2.3 Gated mode: OAuth (Phase 8)

OAuth providers round-trip through `GET /auth/login?provider=N` (PKCE) and
land on the same session cookies; from then on §2.2 steps 3–7 apply
verbatim. The login redirect dance needs a browser view — deferred to
Phase 8. The app detects OAuth-only gateways via
`GET /api/auth/providers` (no `supports_password` provider) and should
signal "not supported yet" rather than failing mysteriously.

### 2.4 WS upgrade rejection close codes

Rejected upgrades close with app-specific codes (`web_server.py` `gateway_ws`
@15924, checks in order):

| Code | Meaning |
|------|---------|
| 4403 | embedded chat disabled, **or** host/origin/peer not allowed |
| 4401 | bad/missing credential (`_ws_auth_ok` failed) |
| 4400 | (pub/events only) bad or missing channel id |

A normal accepted socket then immediately receives the `gateway.ready` event
(§4). Treat a close during connect as a hard auth/reachability failure and
surface it (don't silently retry a 4401).

---

## 3. Framing: JSON-RPC 2.0, newline-delimited

The wire is **newline-delimited JSON-RPC 2.0** in both directions, identical to
the stdio transport (`tui_gateway/ws.py:8-12`). Three frame kinds:

**a) Client → server: request**
```json
{"jsonrpc":"2.0","id":"r1","method":"session.create","params":{}}
```
- `id` is a **client-generated string**, e.g. `r1`, `r2`, monotonic per client
  (`ui-tui/src/gatewayClient.ts:696,748`). Not required to be numeric.

**b) Server → client: response** (echoes the `id`)
```json
{"jsonrpc":"2.0","id":"r1","result":{...}}
```
```json
{"jsonrpc":"2.0","id":"r1","error":{"code":5001,"message":"..."}}
```
(`server.py:1890` for `_ok`, `1894` for `_err`.)

**c) Server → client: event** (unsolicited, **no `id`**)
```json
{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta","session_id":"a1b2c3d4","payload":{"text":"Hel"}}}
```
Built by `_event_frame` / `_emit` at `server.py:1566-1575`.

### Routing rule for the client

For every inbound frame:
- If it has an `id` that matches a pending request → resolve/reject that request.
- Else if `method == "event"` → dispatch by `params.type` (+ `params.session_id`).
- Else (unknown/no match) → drop (a stray response id is ignored).

### Framing gotchas

- **Multiple frames per WS message.** Because of token coalescing (§5), a single
  WS text message can contain **several** newline-separated JSON frames. Split
  on `\n` and parse each line. Do **not** assume one message == one frame.
- **Parse errors** get a JSON-RPC error reply
  `{error:{code:-32700,message:"parse error"},id:null}` and the connection stays
  open (`ws.py:360-382`).
- **Unknown method** → `-32601` (`handle_request`, `server.py:1933`).
- **Handler crash** → `-32603` "internal error", connection stays open
  (`ws.py:392-410`; the reply echoes the request's `id` when it had one).

---

## 4. Connect handshake

1. Client opens the WS (`/api/ws?token=…`).
2. Server calls `ws.accept()`, disables Nagle (`ws.py:299`), resolves the skin
   off-loop, then pushes exactly one unsolicited event:
   ```json
   {"jsonrpc":"2.0","method":"event","params":{"type":"gateway.ready","payload":{"skin":{ /* skin dict */ },"change_events":true}}}
   ```
   (`ws.py:313-327`.) There is **no `session_id`** on this frame.
3. Client treats receipt of `gateway.ready` as **connected/ready** and only then
   starts sending requests (`gatewayClient.ts:161`).

> **⚠️ Changed since 0.18 — flit is behind here.** The payload used to *be* the
> skin dict; as of v0.20 it is `{"skin": <skin dict>, "change_events": true}`.
> `resolve_skin()` (`server.py:3263`) supplies the inner dict: keys `name`,
> `colors`, `light_colors`, `dark_colors`, `branding`, `banner_logo`,
> `banner_hero`, `tool_prefix`, `help_header`; `{}` on failure.
> `change_events: true` advertises that this backend broadcasts
> `pet.changed` / `cron.changed` / `sessions.changed`, so a client can demote
> its polling to a slow backstop.
>
> The `skin.changed` broadcast payload is **still the bare skin dict**
> (`_broadcast_global_event("skin.changed", resolve_skin())`,
> `server.py:3333`) — the two frames no longer carry the same shape.
> `gateway_event_parser.dart` currently treats `gateway.ready`'s payload as the
> skin, so the skin is silently dropped on connect and only picked up on the
> next `skin.changed`. Not tracked in the required/optional gap docs — fix
> alongside them.

There is no separate login RPC — auth already happened on the upgrade query
string. After `gateway.ready`, immediately do `session.create` (or
`session.resume`) to get a session to talk to.

---

## 5. Streaming & token coalescing (must-handle)

High-frequency delta frames — `message.delta`, `reasoning.delta`,
`thinking.delta` — are **buffered and flushed as a batch on a ~33ms timer
(~30fps)** by the WS transport, not sent one-per-token (`_STREAMING_EVENT_TYPES`
+ `_TOKEN_COALESCE_S=0.033`, `ws.py:53-60`). Consequences for the client:

- You receive **bursts** of deltas, possibly several in one WS message.
- **Ordering is preserved**: any non-streaming frame (RPC responses, `tool.*`,
  `message.complete`, `status.update`) **flushes the pending delta buffer ahead
  of itself** (`ws.py:129-160`), so a `tool.start` can never overtake the text
  that preceded it. You can rely on arrival order.
- Accumulate `message.delta.text` into the current bubble; the terminal
  `message.complete.text` carries the full final text (you may render from the
  accumulation and reconcile with `complete`, or just trust `complete`).
- `reasoning.delta` accumulates SEPARATELY from the reply text — never into it.
  flit folds it into `ChatMessage.reasoning` and renders a collapsed
  "Thinking…" disclosure above the bubble. `reasoning.available` `{text}` is
  the non-streaming sibling for providers that return reasoning whole
  (`server.py:5500`): treat it as a fallback and ignore it once deltas have
  arrived. `message.complete.reasoning` is the same text again and can be
  clamped, so prefer what streamed. `thinking.delta` is a different signal —
  a spinner caption (`"🤔 pondering..."`), not model reasoning — and flit does
  not consume it.

---

## 6. The assistant turn lifecycle (events)

You **send** `prompt.submit` (returns `{status:"streaming"}` immediately —
fire-and-forget for content; `methods_prompt.py:67` handler, ack at
`methods_prompt.py:367`). The reply arrives entirely as **events** keyed by
`session_id`. Canonical order for one turn (`server.py` `_run_prompt_submit`
@9482 and `_emit` call sites):

```
message.start                         (no payload)                server.py:9516
  ↕ interleaved, zero or more of:
    thinking.delta      {text}                                    server.py:5727
    reasoning.delta     {text, verbose?}                          server.py:5732
    reasoning.available {text, verbose?}                          server.py:5504
    message.delta       {text, rendered?}                         server.py:9758
    message.interim     {text, already_streamed}                  server.py:9767
    status.update       {kind, text}                              server.py:1861
    moa.reference       {label, text, index?, count?} (mixture-of-agents) server.py:5519
    moa.aggregating     {aggregator}                              server.py:5522
    moa.progress / moa.phase                                      server.py:5532,5559
    reaction            {kind}   (ily/<3/good bot → hearts)       server.py:5730
    notification.show   {text, level, kind, ttl_ms, key, id}      server.py:5743
    notification.clear  {key}                                     server.py:5755
    tool.start / tool.generating / tool.complete / tool.output_risk (see §7)
    approval.request / clarify.request / sudo.request / secret.request (see §8)
message.complete  {text, rendered?, reasoning?, usage, status}    server.py:10006
                  status ∈ {complete, interrupted, error}
                  status=="error" adds {error, recoverable:true}
session.info      {model, provider, usage, tools, ...}            server.py:10248
                  (via _emit_settled_session_info, server.py:2644)
```

- On a fatal turn error, the terminal frame may be `error` (`{message}`,
  `server.py:10186`) **instead of** `message.complete`. Treat **both**
  `message.complete` (any status) and `error` as **turn-terminal**. A turn
  cancelled before the agent was ready also lands on a bare `error`
  (`methods_prompt.py:350`).
- After every turn the session emits a fresh `session.info` event as it releases
  the `running` flag — use it to refresh model/usage/tools display.

### `prompt.submit` while a turn is running

Not rejected — it is **queued** and may interrupt the live turn
(`_handle_busy_submit`, `server.py:7501`, called from `methods_prompt.py:142`).
The busy ack carries its own status (`steered` / `redirected` / `queued`) —
see `../updates/gateway-0.18-to-0.20-required.md` §2. The client should still
reflect a "working" state and let the user queue/steer.

---

## 7. Tool calls (display-only events)

The agent's tool activity streams as events with **no client reply required**
(`_on_tool_start` @`server.py:5398`, `_on_tool_complete` @`server.py:5425`,
`_on_tool_progress` @`server.py:5472`; gated by `_tool_progress_enabled(sid)`
@`server.py:4321`, default on — a `tool.*` frame is also forced through when the
tool is UI-required or the payload carries an `inline_diff`):

| Event | Payload (key fields) | Notes |
|-------|----------------------|-------|
| `tool.start` | `{tool_id, name, context, args_text?, todos?}` | `args_text` only in verbose mode |
| `tool.generating` | `{name}` | args being generated |
| `tool.complete` | `{tool_id, name, args, result, duration_s?, summary?, result_text?, inline_diff?, todos?, error?}` | correlate to `tool.start` by `tool_id` |
| `tool.output_risk` | `{tool_id, name, risk, findings[], redacted}` | dangerous-output warning; `risk` defaults `"low"` |

- **`tool.complete.result` is polymorphic**: it is parsed JSON (a `dict`/`list`)
  when the tool result was valid JSON, else a raw string (`server.py:5437-5439`).
  Handle both.
- `inline_diff` (when present) is a unified diff for file-edit tools — render
  monospace.

> **`tool.progress` is not emitted by this gateway.** `_on_tool_progress` is a
> multiplexer on an internal `event_type`, and none of its branches emit a
> literal `tool.progress` — a `tool.started` progress row is deliberately
> suppressed (`server.py:5482`) because `_on_tool_start` already sent the
> authoritative `tool.start`. `tool.progress` survives only in
> `ui-tui/src/gatewayTypes.ts:674` and the messaging `api_server.py` path.
> Don't build UI that waits for it. flit parses it
> (`gateway_event_parser.dart:293`) and folds it in `message_fold.dart:179` —
> harmless dead code, but don't rely on that branch for progress display.

---

## 8. Interactive prompts (request → respond)

Mid-turn, the agent can block waiting for the user. There are **two correlation
models** — get this right or answers won't match.

### 8.1 Correlated by `request_id` (clarify / sudo / secret / terminal.read)

A generic `_block()` factory (`server.py:3186`) mints an 8-hex `request_id`,
emits an event carrying it, and **blocks the agent thread** (default 300s) until
a matching `*.respond` RPC arrives (shared `_respond` helper, `server.py:10606`).

| Event (server→client) | Payload | Answer RPC (client→server) | Answer key |
|---|---|---|---|
| `clarify.request` | `{question, choices: string[]\|null, multi_select?, request_id}` | `clarify.respond` | `answer` |
| `sudo.request` | `{request_id}` | `sudo.respond` | `password` |
| `secret.request` | `{env_var, prompt, request_id}` | `secret.respond` | `value` |
| `terminal.read.request` | `{request_id, start?, count?}` | `terminal.read.respond` | `text` |
| `preview.read.request` | `{request_id, start?, count?}` | `preview.read.respond` | `text` |

`multi_select` is present only when `true` (`server.py:5758`) — a pass-through
hint that the renderer may offer checkboxes; a single answer still parses.

Response example:
```json
{"jsonrpc":"2.0","id":"r9","method":"clarify.respond","params":{"request_id":"<the id>","answer":"option A"}}
```
Result is `{status:"ok"}`. If no pending request matches, you get an error
(`code 4009`, "no pending `<answer key>` request" — e.g. "no pending answer
request" for clarify, "no pending value request" for secret). If the client never answers, the
answer defaults to empty after the timeout **and the gateway emits a
`<name>.expire` `{request_id}`** event (`server.py:3216-3226`) for all five
blocking bridges; a late `*.respond` then returns `{status:"expired"}` rather
than erroring (`server.py:10611`). See `08-agent-transparency-wire-shapes.md`
for per-prompt timeouts.

### 8.2 Correlated by `session` (approvals — DIFFERENT)

`approval.request` carries **NO `request_id`**. It is correlated by
`session_id`/`session_key` against a FIFO queue (`tools/approval.py:2461`,
`_gateway_queues`; enqueued in `_await_gateway_decision`, `approval.py:3630`).
Answer resolves the oldest (or all) pending entries for that session via
`approval.respond` (`methods_prompt.py:949`).

- Event `approval.request` payload:
  `{command, description, pattern_key, pattern_keys[], allow_permanent,
  choices[]}` (command is credential-redacted).
  `_emit_approval_request`, `server.py:1826`.
- `choices` is **derived server-side when the emitter omits it**
  (`server.py:1834-1840`): `["once","session","always","deny"]` normally,
  `["once","session","deny"]` when `allow_permanent` is false, and
  `["once","deny"]` for a smart-denied command. Prefer rendering `choices`
  verbatim over inferring buttons from `allow_permanent`.
- Answer:
  ```json
  {"jsonrpc":"2.0","id":"r8","method":"approval.respond","params":{"session_id":"a1b2c3d4","choice":"approve"}}
  ```
  `choice` ∈ approve / deny / (approve-and-remember when `allow_permanent`);
  it defaults to `"deny"` when omitted. Optional `all: true` resolves every
  queued approval for the session instead of just the oldest.
- Result is `{"resolved": <int>}` — the **count** of queue entries unblocked,
  `0` when nothing was pending (`resolve_gateway_approval`, `approval.py:2490`).
  Not `{status:"ok"}`, and `0` is not an error. Errors: `5004`.

> `input.request` is **not** a real emitted event — it's only a fallback label
> string in `_session_pending_kind` (`server.py:7884`). Don't wait for it.
> `approvals.mode` and `approvals.mcp_reload_confirm` are **not** RPCs — yolo /
> global-approval toggling goes through `config.set{key:"yolo"}`; the MCP-reload
> confirm is a `status:"confirm_required"` result of the `reload.mcp` RPC.

---

## 9. Two kinds of session id

This trips up every client. The session slice (now `methods_session.py`, with
the registry + helpers still in `server.py`) tracks:

- **Live `session_id`** — `uuid4().hex[:8]` (8 hex chars). Keys the in-memory
  `_sessions` map. **This is what you pass to `prompt.submit`, `session.interrupt`,
  and what appears on every event's `params.session_id`.** Route all live
  traffic by this.
- **Durable stored id** — the DB row id, surfaced as `session_key` / `id` /
  `resumed`. This is what `session.list`, `session.delete`, and `session.resume`
  operate on.

Flow:
- `session.create` → returns a **new short `session_id`** (+ a `stored_session_id`
  / `session_key`).
- `session.list` → returns **durable** ids.
- `session.resume` → takes a **durable** id as `session_id` param, returns a
  **new short `session_id`** (with the durable one echoed as `resumed`/
  `session_key`).

The "current" session is tracked **entirely client-side** — the gateway doesn't
hold a notion of "the" active session for you (the TUI writes it to a file and
passes `current_session_id` into `session.active_list`).

---

## 10. Reconnect & session continuity

There is **no protocol-level auto-replay**. Reconnect is client-driven:

- On WS disconnect the server reaps `close_on_disconnect` sessions and
  **grace-detaches** the rest to an orphan reaper (`ws.py:441-458` →
  `_close_sessions_for_transport`, `server.py:1074`). The grace window is
  `_WS_ORPHAN_REAP_GRACE_S`, default 20s (`server.py:175-180`).
- **`close_on_disconnect` now defaults to `False`** (`methods_session.py:83`) —
  sessions survive a client disconnect and are reclaimed later by the
  idle/session-cap reaper. Send `close_on_disconnect: true` on create/resume if
  you want the old die-with-the-socket behavior.
- A quick reconnect + `session.resume` re-binds a detached live session before
  the reaper finalizes it (the fast path re-checks the live registry under
  `_session_resume_lock`, `methods_session.py:404`, with double-checked locking
  after a build at `methods_session.py:644`).
- Practical client policy (see architecture doc): exponential-backoff reconnect;
  on reconnect, wait for `gateway.ready`, then `session.resume` the durable id
  of the session the user was in. Any turn that was streaming when the socket
  dropped will **not** be replayed — reconcile from the resumed session's
  history.

---

## 11. Long handlers

Some methods are "long" (`_LONG_HANDLERS` frozenset, `server.py:193-284`) — e.g.
`prompt.submit`, `slash.exec`, `session.compress`, most `pool-run` methods.
`dispatch()` (`server.py:1962`) schedules them on a thread pool and the worker
writes its own response later (`server.py:1982-1998`, returning `None` inline);
the WS layer still preserves frame ordering. **Client impact: none beyond
honoring your per-request timeout** — just don't assume a fast round-trip for
these. Use a generous RPC timeout (the TUI uses ≥120s, `gatewayClient.ts:18`).
