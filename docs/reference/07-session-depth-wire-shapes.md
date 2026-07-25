# Reference: Phase 2 session-depth wire shapes

Concrete JSON-RPC frames for the Phase 2 session methods, grounded in
`hermes-agent/tui_gateway/server.py` (verified against source 2026-07). Same
rules as `03-mvp-wire-shapes.md`: field **names/types** are from source, example
**values** are illustrative. Where Python and TS disagree, Python wins.

Envelope reminders: request `{jsonrpc,id,method,params}`; response
`{jsonrpc,id,result}` or `{...,error:{code,message}}`; event (no id)
`{jsonrpc,method:"event",params:{type,session_id,payload}}`.

**Two ids (protocol §9), per method — get this right:**

| Method | `session_id` param is… | Notes |
|---|---|---|
| `session.most_recent` | *(no id param)* | queries DB; returns a DURABLE id |
| `session.status` | LIVE short id | `_sess_nowait` |
| `session.history` | LIVE short id | `_sess_nowait` |
| `session.title` | LIVE short id | `_sess_nowait` |
| `session.usage` | LIVE short id | `_sess_nowait` (LONG handler) |
| `session.context_breakdown` | LIVE short id | `_sess_nowait` |
| `session.cwd.set` | LIVE short id | `_sess_nowait` |
| `session.undo` | LIVE short id | `_sess` (builds/awaits agent) |
| `session.compress` | LIVE short id | `_sess` (LONG handler) |
| `session.save` | LIVE short id | `_sess` |
| `session.close` | LIVE short id | `_pop_session_by_id`; unknown → `closed:false` |
| `session.branch` | LIVE short id (parent) | `_sess`; returns a NEW live id (LONG) |
| `session.delete` | DURABLE id | DB delete; refuses active sessions |

---

## Canonical message shape (`_history_to_messages`, server.py:5909)

Used by `session.history`, `session.compress`, and `session.resume` — identical
per-entry shape:

```jsonc
// regular message
{"role":"user|assistant|tool|system","text":"…"}
// assistant may additionally carry (values opaque — pass through raw):
//   "reasoning", "reasoning_content", "reasoning_details", "codex_reasoning_items"
// any message may carry: "display_kind":str, "display_metadata":{…}
// TOOL entries have name+context, NOT text:
{"role":"tool","name":"shell","context":"ls -la"}   // context capped ~80 chars, may be ""
```
Empty/hidden entries and text-less assistant tool-call turns are dropped.

---

## `session.most_recent` (server.py:6472) — the "continue" entry point

```json
{"jsonrpc":"2.0","id":"r1","method":"session.most_recent","params":{}}
```
Optional param: `profile` (string) — which profile's DB to query. **No session
id.** Result, when an eligible durable session exists (source not `"tool"`):
```jsonc
{"jsonrpc":"2.0","id":"r1","result":{
  "session_id":"2026-uuid",   // DURABLE id
  "title":"Fix the parser",
  "started_at":1783200000,    // epoch SECONDS
  "source":"cli"
}}
```
None found / DB unavailable / any error → `{"session_id":null}`. **Never errors.**

---

## `session.status` (server.py:9298)

Params: `session_id` (LIVE, required), `profile` (optional). Result is a single
pre-formatted human block — NOT structured:
```jsonc
{"jsonrpc":"2.0","id":"r2","result":{"output":"Hermes TUI Status\nSession ID: …\n…"}}
```
Errors: `4001` session not found.

---

## `session.history` (server.py:9374)

Params: `session_id` (LIVE, required). Result:
```jsonc
{"jsonrpc":"2.0","id":"r3","result":{
  "count":12,                       // int — NOTE: "count", not "message_count"
  "messages":[ {"role":"user","text":"…"}, … ]   // canonical shape above
}}
```
Errors: `4001`.

---

## `session.title` (server.py:7418) — rename OR read

`session_id` (LIVE, required). The presence of the `title` key selects mode.

GET (omit `title`):
```json
{"jsonrpc":"2.0","id":"r4","method":"session.title","params":{"session_id":"a1b2c3d4"}}
```
```jsonc
{"jsonrpc":"2.0","id":"r4","result":{"title":"Fix the parser","session_key":"2026-uuid"}}
```
SET (include `title`, non-empty):
```json
{"jsonrpc":"2.0","id":"r4","method":"session.title","params":{"session_id":"a1b2c3d4","title":"New name"}}
```
```jsonc
{"jsonrpc":"2.0","id":"r4","result":{"pending":false,"title":"New name"}}
// pending:true only when the row could not yet be persisted (rare deferred path)
```
Errors: `4001` not found; `5007` DB unavailable / generic; `4021` title required
(empty in SET); `4022` invalid title.

---

## `session.usage` (server.py:7720) — LONG handler

`session_id` (LIVE, required). Result IS the usage dict directly:
```jsonc
{"jsonrpc":"2.0","id":"r5","result":{
  "model":"hermes-4-405b",
  "input":1200,"output":420,"reasoning":0,
  "prompt":1200,"completion":420,"total":1620,"calls":3,
  // CONDITIONAL (only when a context compressor + real occupancy exist):
  "context_used":48000,"context_max":128000,"context_percent":38,
  "compressions":0,             // only when a compressor exists
  "active_subagents":0,         // usually present
  // "dev_credits_spent_micros": int   — only when HERMES_DEV_CREDITS
  // "credits_lines": [...]            — only when logged into Nous (opaque list)
}}
```
Lazy session with no usage mirror → `{calls:0,input:0,output:0,total:0}`.
**There is NO `cost_usd` key** in this handler. Errors: `4001`.

---

## `session.context_breakdown` (server.py:7744)

`session_id` (LIVE, required). Result:
```jsonc
{"jsonrpc":"2.0","id":"r6","result":{
  "categories":[
    {"id":"system_prompt","label":"System prompt","tokens":2400,"color":"var(--context-usage-system)"},
    {"id":"conversation","label":"Conversation","tokens":45600,"color":"var(--context-usage-…)"}
    // id ∈ system_prompt|tool_definitions|rules|skills|mcp|subagent_definitions|memory|conversation
    // categories with tokens==0 are omitted
  ],
  "context_max":128000,"context_percent":38,"context_used":48000,
  "estimated_total":48000,"model":"hermes-4-405b"
}}
```
Lazy session → same top-level keys, `categories:[]`. Errors: `4001`;
`5000` "Could not compute context breakdown: …".

---

## `session.compress` (server.py:9426) — LONG handler

Params: `session_id` (LIVE, required), `focus_topic` (optional str, default "").
Local-path success result (the shape the client should target):
```jsonc
{"jsonrpc":"2.0","id":"r7","result":{
  "status":"compressed",            // or "aborted" when summary.aborted
  "removed":8,
  "before_messages":24,"after_messages":16,
  "before_tokens":90000,"after_tokens":42000,
  "summary":{ "aborted":false, /* other fields opaque */ },
  "usage":{ /* opaque */ },
  "info":{ /* full _session_info dict — see below */ },
  "messages":[ … ]                  // canonical shape (post-compression history)
}}
```
Lock-held (nothing to do): `{"compressed":false,"lock_held":true,"message":"…"}`.
Compute-host variants add `"turn_isolation":true` and opaque `host_ack`/`info`.
Errors: `4009` session busy; `5005` compression failed; `5019` compute-host fail.

---

## `session.undo` (server.py:9398)

`session_id` (LIVE, required — builds agent). Result:
```jsonc
{"jsonrpc":"2.0","id":"r8","result":{"removed":2}}   // trailing assistant/tool + 1 user popped
```
Errors: `4009` "session busy — /interrupt the current turn before /undo"; `4001`.

---

## `session.save` (server.py:9598)

`session_id` (LIVE, required). Local-path result:
```jsonc
{"jsonrpc":"2.0","id":"r9","result":{"file":"/…/hermes_conversation_1783200000.json"}}
```
Compute-host path returns an opaque host dict instead. Errors: `5011` (all
save failures); `4001`.

---

## `session.branch` (server.py:9682) — LONG handler

Params: `session_id` (LIVE parent, required), `name` (optional str; empty →
auto-derived title). Result:
```jsonc
{"jsonrpc":"2.0","id":"r10","result":{
  "session_id":"c9d0e1f2",   // NEW live short id of the branch
  "title":"Fix the parser (branch)",
  "parent":"2026-uuid"       // parent's DURABLE session_key
}}
```
Note: the result gives **no durable id for the branch itself** — only its new
live id. A `session.info` event follows; the branch appears in `session.list`.
Errors: `4008` "nothing to branch — send a message first" (empty history);
`4090` active-session slot limit; `5008` DB/branch failed; `5000` agent init.

---

## `session.cwd.set` (server.py:7064)

Params: `session_id` (LIVE, required), `cwd` (required non-empty str). Result is
`info` — the full `_session_info` dict when a live agent exists, else a minimal
`{cwd, branch, project, lazy:true}`. Errors: `4001`; `4009` busy; `4016` cwd
required; `4017` invalid path.

---

## `session.close` (server.py:9670)

`session_id` (LIVE, default ""). Result `{"closed":true|false}`. Unknown id →
`closed:false` (no error). Never errors.

---

## The `session.info` event payload (`_session_info`, server.py:4121)

Emitted after every turn (protocol §6) and returned inline by `cwd.set` /
`compress`. Payload IS the info dict. Keys the client consumes:
```jsonc
{
  "model":"hermes-4-405b","provider":"nous",
  "reasoning_effort":"","service_tier":"","fast":false,
  "yolo":false,"approval_mode":"manual",
  "tools":{"shell":["run"], …},    // toolset→[tool names]; dynamic
  "skills":{ … },                   // dynamic; opaque
  "cwd":"/home/iggy/project","branch":"main",
  "project":{"id":…,"slug":"…","name":"…","primary_path":"…"} /* or null */,
  "personality":"","running":false,
  "title":"Fix the parser","stored_session_id":"2026-uuid",
  "usage":{ /* same shape as session.usage */ },
  "profile_name":"default",
  "version":"0.17.0","release_date":"2026-06-30",
  "mcp_servers":[…],"system_prompt":"…",
  "desktop_contract":4,"update_behind":null,"update_command":""
  // "credential_warning":str  — only when a live agent has a missing key
}
```
For Phase 2 the client reads `usage`, `cwd`, `title`, `model`, `provider`,
`running` from this event to live-update the session-info surface after a turn.

---

## `session.resume` `inflight` field (P2-02, server.py `_inflight_snapshot`:6235)

`session.resume` (wire §5) returns an `inflight` field for reconciling a turn
that was streaming when the socket dropped:
```jsonc
"inflight": null                                         // no live turn (cold/lazy/eager branches)
"inflight": {"user":"…","assistant":"partial …","streaming":true}   // fast-path reuse only
```
In the fast-path (already-live) reuse branch the key is present ONLY when a turn
is active; otherwise it is **omitted** (not null). Treat both `null` and missing
as "no inflight turn." `session.history` does NOT return `inflight`.
</content>
</invoke>
