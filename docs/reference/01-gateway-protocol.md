# Reference: The gateway protocol

Everything a client must know to talk to the gateway correctly. Grounded in
`hermes-agent` source; citations are `file:line` in that repo.

---

## 1. Discovering a gateway: `GET /api/status`

Before connecting, hit the **public, unauthenticated** status endpoint to learn
whether the gateway is up and which auth mode it uses.

`GET <base>/api/status` (optional `?profile=<name>`). It's in
`PUBLIC_API_PATHS` (`hermes_cli/dashboard_auth/public_paths.py:39`), so no auth.

Always-present fields (`web_server.py:2077-2264`):

```jsonc
{
  "version": "0.17.0",
  "release_date": "2026-06-30",
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
`gateway_health_url`. In OAuth mode those are omitted.

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
   (`routes.py:152`; 503 when none registered).
2. **Log in:** `POST <base>/auth/password-login` with JSON body
   `{provider, username, password, next}` (`routes.py:466`,
   `_PasswordLoginBody`). Success → `200 {"ok":true,"next":<path>}` and the
   response **sets the session cookies**. Failures are deliberately generic:
   401 invalid credentials, 404 unknown/password-less provider, 429 rate
   limited, 503 provider unreachable (`routes.py:468-533`).
3. **Session cookies** (`cookies.py`): `hermes_session_at` (access token),
   `hermes_session_rt` (refresh token, when the provider issues one),
   `hermes_session_provider`. The exact cookie **names vary by deploy** —
   `__Host-`/`__Secure-`/bare prefixes depending on HTTPS + path prefix
   (`cookies.py:107` `_resolved_name`) — so a client must capture them
   **verbatim from `Set-Cookie`**, never reconstruct names.
4. **REST auth:** send the captured cookies as a `Cookie` header on every
   gated request. The gate middleware verifies the access token and, when
   expired, **refreshes it via the refresh token and re-sets rotated cookies
   on the response** (`middleware.py`) — the client must update its cookie
   store from `Set-Cookie` on **every** response.
5. **WS auth — single-use ticket:** `POST <base>/api/auth/ws-ticket`
   (cookie-authed, `routes.py:615`) → `{ticket, ttl_seconds: 30}`. Connect
   `/api/ws?ticket=<ticket>`; the ticket is **consumed** on the upgrade
   (`web_server.py` `_ws_auth_reason` → `consume_ticket`). **Mint a fresh
   ticket for every connect and every reconnect attempt.**
6. **Identity (optional):** `GET <base>/api/auth/me` (cookie-authed) →
   `{user_id, email, display_name, org_id, provider, expires_at}`
   (`routes.py:594`).
7. **Logout:** `POST <base>/auth/logout` (cookie-authed) revokes the
   refresh token best-effort and clears cookies (`routes.py:558`).

### 2.3 Gated mode: OAuth (Phase 8)

OAuth providers round-trip through `GET /auth/login?provider=N` (PKCE) and
land on the same session cookies; from then on §2.2 steps 3–7 apply
verbatim. The login redirect dance needs a browser view — deferred to
Phase 8. The app detects OAuth-only gateways via
`GET /api/auth/providers` (no `supports_password` provider) and should
signal "not supported yet" rather than failing mysteriously.

### 2.4 WS upgrade rejection close codes

Rejected upgrades close with app-specific codes (`web_server.py` `gateway_ws`
@12711, checks in order):

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
(`server.py:1052` for `_ok`, `1056` for `_err`.)

**c) Server → client: event** (unsolicited, **no `id`**)
```json
{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta","session_id":"a1b2c3d4","payload":{"text":"Hel"}}}
```
Built by `_emit` at `server.py:988-992`.

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
  open (`ws.py:366-378`).
- **Unknown method** → `-32601` (`server.py:1094`).
- **Handler crash** → `-32603` "internal error", connection stays open
  (`ws.py:397-403`).

---

## 4. Connect handshake

1. Client opens the WS (`/api/ws?token=…`).
2. Server calls `ws.accept()`, disables Nagle (`ws.py:298`), starts background
   MCP discovery, then pushes exactly one unsolicited event:
   ```json
   {"jsonrpc":"2.0","method":"event","params":{"type":"gateway.ready","payload":{ /* skin dict */ }}}
   ```
   (`ws.py:319-328`.) **`params.payload` IS the skin dict** (keys: `name`,
   `colors`, `branding`, `banner_logo`, `banner_hero`, `tool_prefix`,
   `help_header`; `{}` on failure) — despite the TS type nesting it under
   `payload.skin`. There is **no `session_id`** on this frame.
3. Client treats receipt of `gateway.ready` as **connected/ready** and only then
   starts sending requests (`gatewayClient.ts:161`).

There is no separate login RPC — auth already happened on the upgrade query
string. After `gateway.ready`, immediately do `session.create` (or
`session.resume`) to get a session to talk to.

---

## 5. Streaming & token coalescing (must-handle)

High-frequency delta frames — `message.delta`, `reasoning.delta`,
`thinking.delta` — are **buffered and flushed as a batch on a ~33ms timer
(~30fps)** by the WS transport, not sent one-per-token (`ws.py:53-60`,
`_TOKEN_COALESCE_S=0.033`). Consequences for the client:

- You receive **bursts** of deltas, possibly several in one WS message.
- **Ordering is preserved**: any non-streaming frame (RPC responses, `tool.*`,
  `message.complete`, `status.update`) **flushes the pending delta buffer ahead
  of itself** (`ws.py:130-159`), so a `tool.start` can never overtake the text
  that preceded it. You can rely on arrival order.
- Accumulate `message.delta.text` into the current bubble; the terminal
  `message.complete.text` carries the full final text (you may render from the
  accumulation and reconcile with `complete`, or just trust `complete`).

---

## 6. The assistant turn lifecycle (events)

You **send** `prompt.submit` (returns `{status:"streaming"}` immediately —
fire-and-forget for content; `server.py:8091`). The reply arrives entirely as
**events** keyed by `session_id`. Canonical order for one turn
(`server.py` `_run_prompt_submit` @8419 and `_emit` call sites):

```
message.start                         (no payload)                server.py:8433
  ↕ interleaved, zero or more of:
    thinking.delta      {text}                                    server.py:3400
    reasoning.delta     {text, verbose?}                          server.py:3540
    reasoning.available {text, verbose?}                          server.py:3588
    message.delta       {text, rendered?}                         server.py:8553
    status.update       {kind, text}                              server.py:1023
    moa.reference       {index, count, label, text}   (mixture-of-agents)
    moa.aggregating     {aggregator}
    notification.show / notification.clear
    tool.start / tool.progress / tool.generating / tool.complete  (see §7)
    approval.request / clarify.request / sudo.request / secret.request (see §8)
message.complete  {text, rendered?, reasoning?, usage, status}    server.py:8674
                  status ∈ {complete, interrupted, error}
session.info      {model, provider, usage, tools, ...}            server.py:8838
```

- On a fatal turn error, the terminal frame may be `error` (`{message?}`,
  `server.py:8149`) **instead of** `message.complete`. Treat **both**
  `message.complete` (any status) and `error` as **turn-terminal**.
- After every turn the session emits a fresh `session.info` event as it releases
  the `running` flag — use it to refresh model/usage/tools display.

### `prompt.submit` while a turn is running

Not rejected — it is **queued** and may interrupt the live turn
(`_handle_busy_submit`, `server.py:8109`). The client should still reflect a
"working" state and let the user queue/steer.

---

## 7. Tool calls (display-only events)

The agent's tool activity streams as events with **no client reply required**
(`server.py:3307-3482`, gated by `_tool_progress_enabled(sid)`, default on):

| Event | Payload (key fields) | Notes |
|-------|----------------------|-------|
| `tool.start` | `{tool_id, name, context, args_text?, todos?}` | `args_text` only in verbose mode |
| `tool.progress` | `{name, preview}` | incremental progress line |
| `tool.generating` | `{name}` | args being generated |
| `tool.complete` | `{tool_id, name, args, result, duration_s?, summary?, result_text?, inline_diff?, todos?, error?}` | correlate to `tool.start` by `tool_id` |

- **`tool.complete.result` is polymorphic**: it is parsed JSON (a `dict`/`list`)
  when the tool result was valid JSON, else a raw string (`server.py:3345-3348`).
  Handle both.
- `inline_diff` (when present) is a unified diff for file-edit tools — render
  monospace.

---

## 8. Interactive prompts (request → respond)

Mid-turn, the agent can block waiting for the user. There are **two correlation
models** — get this right or answers won't match.

### 8.1 Correlated by `request_id` (clarify / sudo / secret / terminal.read)

A generic `_block()` factory (`server.py:1859`) mints an 8-hex `request_id`,
emits an event carrying it, and **blocks the agent thread** (default 300s) until
a matching `*.respond` RPC arrives (shared `_respond` helper, `server.py:9682`).

| Event (server→client) | Payload | Answer RPC (client→server) | Answer key |
|---|---|---|---|
| `clarify.request` | `{question, choices: string[]\|null, request_id}` | `clarify.respond` | `answer` |
| `sudo.request` | `{request_id}` | `sudo.respond` | `password` |
| `secret.request` | `{env_var, prompt, request_id}` | `secret.respond` | `value` |
| (terminal read) | `{request_id, ...}` | `terminal.read.respond` | `text` |

Response example:
```json
{"jsonrpc":"2.0","id":"r9","method":"clarify.respond","params":{"request_id":"<the id>","answer":"option A"}}
```
Result is `{status:"ok"}`. If no pending request matches, you get an error
(`code 4009`, "no pending answer request"). If the client never answers, the
answer defaults to empty after the timeout.

### 8.2 Correlated by `session` (approvals — DIFFERENT)

`approval.request` carries **NO `request_id`**. It is correlated by
`session_id`/`session_key` against a FIFO queue (`tools/approval.py`,
`_gateway_queues`). Answer resolves the oldest (or all) pending entries for that
session via `approval.respond` (`server.py:9715`).

- Event `approval.request` payload:
  `{command, description, pattern_key, pattern_keys[], allow_permanent}`
  (command is credential-redacted). `server.py:1007`, `approval.py:1803`.
- Answer:
  ```json
  {"jsonrpc":"2.0","id":"r8","method":"approval.respond","params":{"session_id":"a1b2c3d4","choice":"approve"}}
  ```
  `choice` ∈ approve / deny / (approve-and-remember when `allow_permanent`).

> `input.request` is **not** a real emitted event — it's only a label string in
> `_session_pending_kind` (`server.py:5625`). Don't wait for it.
> `approvals.mode` and `approvals.mcp_reload_confirm` are **not** RPCs — yolo /
> global-approval toggling goes through `config.set{key:"yolo"}`; the MCP-reload
> confirm is a `status:"confirm_required"` result of the `reload.mcp` RPC.

---

## 9. Two kinds of session id

This trips up every client. `server.py` (session slice) tracks:

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
  **grace-detaches** the rest to an orphan reaper (`ws.py:425-450`).
- A quick reconnect + `session.resume` re-binds a detached live session before
  the reaper finalizes it (`session.resume` cancels the reap under
  `_session_resume_lock`, `server.py:5238`).
- Practical client policy (see architecture doc): exponential-backoff reconnect;
  on reconnect, wait for `gateway.ready`, then `session.resume` the durable id
  of the session the user was in. Any turn that was streaming when the socket
  dropped will **not** be replayed — reconcile from the resumed session's
  history.

---

## 11. Long handlers

Some methods are "long" (`_LONG_HANDLERS` frozenset, `server.py:178-223`) — e.g.
`prompt.submit`, `slash.exec`, `session.compress`, most `pool-run` methods.
`dispatch()` schedules them on a thread pool and the worker writes its own
response later (`server.py:1099-1135`); the WS layer still preserves frame
ordering. **Client impact: none beyond honoring your per-request timeout** —
just don't assume a fast round-trip for these. Use a generous RPC timeout
(the TUI uses ≥120s, `gatewayClient.ts:18`).
