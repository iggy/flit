# Reference: MVP wire shapes (copy-paste-ready)

Concrete JSON-RPC frames for every interaction the MVP needs, grounded in the
gateway handlers. Values marked `// GUESS` are illustrative content only —
field **names/types** are from source; example **values** are made up.

Envelope reminders (`server.py:988,1052,1056`):
- request: `{"jsonrpc":"2.0","id":"<str>","method":"<str>","params":{...}}`
- response: `{"jsonrpc":"2.0","id":"<str>","result":{...}}` or `{...,"error":{"code":int,"message":str}}`
- event (no id): `{"jsonrpc":"2.0","method":"event","params":{"type":"<str>","session_id":"<str>","payload":{...}}}`

Trust these Python shapes over `ui-tui/src/gatewayTypes.ts` where they differ.

---

## 0. `GET /api/status` (REST, pre-connect)

```jsonc
// GET http://127.0.0.1:8765/api/status
{
  "version": "0.17.0",
  "gateway_running": true,
  "gateway_state": "ready",
  "active_sessions": 1,
  "auth_required": false,      // false → token mode; connect ?token=…
  "auth_providers": []         // gated mode: registered provider names, e.g. ["local"]
}
```

## 0.1 Gated-mode auth (user/pass; protocol §2.2)

```jsonc
// GET https://gw.example.com/api/auth/providers   (public)
{"providers":[{"name":"local","display_name":"Username & password","supports_password":true}]}
```
```jsonc
// POST https://gw.example.com/auth/password-login
// {"provider":"local","username":"iggy","password":"…","next":""}
// → 200 {"ok":true,"next":"/"} + Set-Cookie: hermes_session_at=…; hermes_session_rt=…
//   (names may carry __Host-/__Secure- prefixes — capture verbatim)
// → 401 {"detail":"Invalid credentials"} | 429 | 404 | 503 (see protocol §2.2)
```
```jsonc
// POST https://gw.example.com/api/auth/ws-ticket   (Cookie: hermes_session_at=…)
// → 200 {"ticket":"…","ttl_seconds":30}   →  WS wss://gw.example.com/api/ws?ticket=…
// single-use; mint a fresh one per (re)connect
```
```jsonc
// GET https://gw.example.com/api/auth/me   (Cookie: …) — optional identity probe
{"user_id":"…","email":"…","display_name":"…","org_id":"…","provider":"local","expires_at":1783200000}
```

## 1. `gateway.ready` (first frame after connect)

```json
{"jsonrpc":"2.0","method":"event","params":{"type":"gateway.ready","payload":{"name":"hermes","colors":{},"branding":{},"tool_prefix":""}}}
```
`payload` IS the skin dict (may be `{}`). No `session_id`. Client → "connected".

## 2. `session.create`

Request:
```json
{"jsonrpc":"2.0","id":"r1","method":"session.create","params":{}}
```
Optional params: `{"profile":"<name>","cwd":"/path","model":"..."}` (profile
scopes this call's HERMES_HOME; `server.py:4882`).

Response (lightweight/lazy first; a fuller `session.info` **event** follows):
```jsonc
{
  "jsonrpc":"2.0","id":"r1",
  "result":{
    "session_id":"a1b2c3d4",              // SHORT live id — use for prompt/interrupt
    "stored_session_id":"2026...-uuid",   // durable id — use for list/resume/delete
    "session_key":"2026...-uuid",
    "info":{ "model":"...", "provider":"...", "lazy":true }  // GUESS values
  }
}
```

## 3. `session.list`

```json
{"jsonrpc":"2.0","id":"r2","method":"session.list","params":{}}
```
```jsonc
{
  "jsonrpc":"2.0","id":"r2",
  "result":{
    "sessions":[
      {"id":"2026..-uuid","title":"Fix the parser","preview":"last message…",
       "message_count":12,"started_at":1783200000,"source":"cli"}  // durable ids
    ]
  }
}
```

## 4. `session.active_list` (live sessions for a switcher)

```json
{"jsonrpc":"2.0","id":"r3","method":"session.active_list","params":{"current_session_id":"a1b2c3d4"}}
```
```jsonc
{
  "jsonrpc":"2.0","id":"r3",
  "result":{"sessions":[
    {"id":"a1b2c3d4","status":"working","current":true,"model":"...",
     "title":"…","preview":"…","last_active":1783200500,"message_count":12}
  ]}
}
```
`status` ∈ `idle|starting|waiting|working` (`_session_live_status`). "current"
is passed IN by the client — the gateway doesn't own it.

## 5. `session.resume` (durable id → new short id)

```json
{"jsonrpc":"2.0","id":"r4","method":"session.resume","params":{"session_id":"2026..-uuid"}}
```
```jsonc
{
  "jsonrpc":"2.0","id":"r4",
  "result":{
    "session_id":"e5f6a7b8",          // NEW short live id
    "resumed":"2026..-uuid",          // the durable id you passed
    "session_key":"2026..-uuid",
    "messages":[ {"role":"user","text":"…"}, {"role":"assistant","text":"…"} ],
    "message_count":12,
    "running":false,
    "status":"idle",
    "info":{ ... }
  }
}
```

## 6. `prompt.submit` (fire-and-forget for content)

```json
{"jsonrpc":"2.0","id":"r5","method":"prompt.submit","params":{"session_id":"a1b2c3d4","text":"List the files in the repo."}}
```
```json
{"jsonrpc":"2.0","id":"r5","result":{"status":"streaming"}}
```
The reply arrives as events (next section). `{"status":"streaming"}` — NOT
`{ok:true}`.

## 7. One streaming turn (sequence of event frames)

```json
{"jsonrpc":"2.0","method":"event","params":{"type":"message.start","session_id":"a1b2c3d4"}}
{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta","session_id":"a1b2c3d4","payload":{"text":"I'll "}}}
{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta","session_id":"a1b2c3d4","payload":{"text":"list them."}}}
{"jsonrpc":"2.0","method":"event","params":{"type":"tool.start","session_id":"a1b2c3d4","payload":{"tool_id":"t1","name":"shell","context":"ls -la"}}}
{"jsonrpc":"2.0","method":"event","params":{"type":"tool.complete","session_id":"a1b2c3d4","payload":{"tool_id":"t1","name":"shell","result":{"stdout":"README.md\n","code":0},"duration_s":0.12,"summary":"1 file"}}}
{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta","session_id":"a1b2c3d4","payload":{"text":" There is 1 file."}}}
{"jsonrpc":"2.0","method":"event","params":{"type":"message.complete","session_id":"a1b2c3d4","payload":{"text":"I'll list them. There is 1 file.","status":"complete","usage":{"input":1200,"output":42,"cost_usd":0.003}}}}
{"jsonrpc":"2.0","method":"event","params":{"type":"session.info","session_id":"a1b2c3d4","payload":{"model":"...","usage":{...},"running":false}}}
```
Remember: deltas arrive coalesced (~30fps bursts, multiple frames per WS
message); `tool.*` / `message.complete` flush pending deltas ahead of themselves
so order holds. `message.complete.result`/`tool.complete.result` can be a dict
or a string.

## 8. `model.options` (populate the model picker)

```json
{"jsonrpc":"2.0","id":"r6","method":"model.options","params":{}}
```
```jsonc
{
  "jsonrpc":"2.0","id":"r6",
  "result":{
    "model":"hermes-4-405b",         // current
    "provider":"nous",               // current
    "providers":[
      {"name":"Nous Portal","slug":"nous","authenticated":true,"is_current":true,
       "auth_type":"oauth","key_env":"NOUS_API_KEY","models":["hermes-4-405b","hermes-4-70b"],
       "total_models":2},
      {"name":"OpenRouter","slug":"openrouter","authenticated":false,
       "key_env":"OPENROUTER_API_KEY","models":[],"warning":"no key"}
    ]
  }
}
```

## 9. Set the active model — `config.set` (NOT `model.default`)

```json
{"jsonrpc":"2.0","id":"r7","method":"config.set","params":{"key":"model","value":"hermes-4-70b --provider nous"}}
```
```jsonc
// normal:
{"jsonrpc":"2.0","id":"r7","result":{"value":"hermes-4-70b","info":{...}}}
// expensive model → must re-send with confirm:
{"jsonrpc":"2.0","id":"r7","result":{"confirm_required":true,"confirm_message":"This model is $X/Mtok. Continue?"}}
```
Re-send with `"confirm_expensive_model":true` in params to proceed. After a
successful switch a `session.info` event reflects the new model. Related keys:
`config.set{key:"reasoning",value:"high"}`, `config.set{key:"fast",value:true}`.

## 10. Approval (event → respond, correlated by session)

Event (no `request_id`):
```json
{"jsonrpc":"2.0","method":"event","params":{"type":"approval.request","session_id":"a1b2c3d4","payload":{"command":"rm -rf build/","description":"Delete build dir","allow_permanent":true,"pattern_key":"rm","pattern_keys":["rm"]}}}
```
Respond:
```json
{"jsonrpc":"2.0","id":"r8","method":"approval.respond","params":{"session_id":"a1b2c3d4","choice":"approve"}}
```
`choice` ∈ `approve` / `deny` / (approve-and-remember when `allow_permanent`).

## 11. Clarify (event → respond, correlated by request_id)

```json
{"jsonrpc":"2.0","method":"event","params":{"type":"clarify.request","session_id":"a1b2c3d4","payload":{"question":"Which environment?","choices":["staging","prod"],"request_id":"9f3a1c2b"}}}
```
```json
{"jsonrpc":"2.0","id":"r9","method":"clarify.respond","params":{"request_id":"9f3a1c2b","answer":"staging"}}
```
Result `{"status":"ok"}`. Error `{"code":4009,"message":"no pending answer request"}` if it already resolved/timed out.

## 12. `session.interrupt`

```json
{"jsonrpc":"2.0","id":"r10","method":"session.interrupt","params":{"session_id":"a1b2c3d4"}}
```
```json
{"jsonrpc":"2.0","id":"r10","result":{"status":"interrupted"}}
```
Also denies pending approvals and clears pending clarify/sudo/secret for the
session. The turn's `message.complete` then carries `payload.status:"interrupted"`.

## 13. `plugins.list`

```json
{"jsonrpc":"2.0","id":"r11","method":"plugins.list","params":{}}
```
```jsonc
{
  "jsonrpc":"2.0","id":"r11",
  "result":{"plugins":[
    {"name":"kanban","version":"1.0.0","enabled":true},   // GUESS values
    {"name":"spotify","version":"?","enabled":false}      // version → "?" if missing
  ]}
}
```

## 14. Profiles (REST, for the dropdown)

Not JSON-RPC. `GET <base>/api/profiles` (header `X-Hermes-Session-Token`):
```jsonc
{"profiles":[
  {"name":"default","is_default":true,"model":"...","provider":"...","description":"…","skill_count":12},
  {"name":"research","is_default":false,"model":"...","description":"…"}
]}
```
Active: `GET /api/profiles/active` → `{"active":"default"}`;
set: `POST /api/profiles/active {"name":"research"}` (writes the sticky pointer —
does **not** retarget a running gateway; see `01` §profiles).
