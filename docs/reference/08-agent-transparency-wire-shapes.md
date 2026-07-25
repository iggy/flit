# Reference: Phase 3 wire shapes (agent transparency & control)

Concrete JSON-RPC frames for slash commands, subagents/delegation, steering,
and the remaining interactive prompts. Grounded in the gateway handlers
(`hermes-agent/tui_gateway/server.py`, `tools/delegate_tool.py`) and
cross-checked against `ui-tui/src/gatewayTypes.ts`. **Python wins** where they
differ; TS-only fields and Python-only fields are called out.

Envelope reminders:
- request: `{"jsonrpc":"2.0","id":"<str>","method":"<str>","params":{...}}`
- response: `{"jsonrpc":"2.0","id":"<str>","result":{...}}` or `{...,"error":{"code":int,"message":str}}`
- event (no id): `{"jsonrpc":"2.0","method":"event","params":{"type":"<str>","session_id":"<str>","payload":{...}}}`

---

## Slash commands

### `commands.catalog` (P3-01)
Params: none.
Result (`server.py:14189`):
```jsonc
{
  "pairs": [["/model", "Switch model"], ...],   // [command, description] tuples
  "sub": {"/plugin": ["list", "add"]},           // subcommand names per command
  "canon": {"/m": "/model"},                     // alias/name (lowercased) -> canonical
  "categories": [
    {"name": "Session", "pairs": [["/new", "..."], ...]}
  ],
  "skill_count": 3,
  "warning": ""                                  // "" when no discovery error
}
```
A "pair" is a 2-element `[command, description]` array. A "category" is
`{name, pairs}`. Aliases are NOT per-entry; they live only in `canon`.

### `command.resolve` (P3-01)
Params: `{"name": "<command, with or without leading />"}`.
Result on success (`server.py:14268`): `{"canonical": "/model", "description": "...", "category": "..."}`.
Unknown command → error code **4011**.

### `complete.slash` (P3-02)
Params: `{"text": "<full input line, incl leading />"}` (cursor assumed at end).
Result (`server.py:15372`):
```jsonc
{
  "items": [{"text": "/model ", "display": "/model", "meta": "Switch model"}],
  "replace_from": 1     // int index to replace from
}
```
Item shape: `{text, display, meta}` — Python always sends `meta` (empty string
when none). Non-slash `text` → `{"items": [], ...}`.

### `complete.path` (P3-02)
Params: `{"word": "<partial @-token or path>"}`.
Result (`server.py:15207`): `{"items": [{"text": "...", "display": "...", "meta": "dir"|""}]}`.
NOTE: no `replace_from` (unlike `complete.slash`). Supports `@diff`, `@file:`,
`@folder:`, `@url:`, `@git:`, `@staged`, `~/`, `./`, absolute/bare paths.

### `command.dispatch` (P3-03)
Params: `{"name": "<command>", "arg": "<arg text>", "session_id": "<live id>"}`.
Result is a discriminated union on **`type`** (`server.py:14291`):
```jsonc
{"type": "exec",    "output": "<rendered text>"}
{"type": "plugin",  "output": "<rendered text>"}
{"type": "alias",   "target": "<other command>"}
{"type": "skill",   "message": "<text>", "name": "<skill name>"}
{"type": "send",    "message": "<text>", "notice": "<optional system line>"}
{"type": "prefill", "message": "<text>", "notice": "<text>"}
```
`send` → submit `message` as a user turn (show `notice` first if present).
`prefill` → populate composer with `message` (show `notice`). Not a
quick/plugin/bundle/skill command → error code **4018**.

### `slash.exec` (P3-03)
LONG handler — use ≥120s timeout.
Params: `{"command": "<full slash line>", "session_id": "<live id>"}`.
Result (`server.py:16084`): `{"output": "<rendered text>", "warning": "<optional>"}`.
Rendered-text field is **`output`** (`"(no output)"` when empty). Empty command
→ error **4004**. Pending-input commands (retry/queue/steer/plan/goal/moa/undo/
learn/compress/compact) and bundles are internally re-routed to
`command.dispatch`, so `slash.exec` may return a `command.dispatch` union shape
for those — callers must handle both.

---

## Subagents & delegation

### Subagent events (P3-04)
Types: `subagent.spawn_requested`, `subagent.start`, `subagent.thinking`,
`subagent.tool`, `subagent.progress`, `subagent.complete`. One shared payload
type `SubagentEventPayload` (`server.py:4554` builds it). Base fields **always
present**: `goal` (str), `task_count` (int), `task_index` (int).
Conditional fields (present when the emitter supplies them):
```jsonc
{
  "subagent_id": "abc123",
  "parent_id": "root" ,          // str | null
  "child_session_id": "...",      // Python-only; NOT in TS type
  "depth": 1,
  "model": "sonnet",
  "tool_count": 4,
  "toolsets": ["fs", "web"],
  "input_tokens": 0, "output_tokens": 0, "reasoning_tokens": 0, "api_calls": 0,
  "files_read": ["..."], "files_written": ["..."],
  "output_tail": [{"tool": "...", "preview": "...", "is_error": false}],
  "tool_name": "...",             // subagent.tool
  "tool_preview": "...",          // subagent.tool only
  "text": "...",                  // thinking text / progress summary / preview
  "status": "running",            // completed|error|failed|interrupted|queued|running|timeout
  "summary": "...",               // subagent.complete
  "duration_seconds": 1.2,        // subagent.complete
  "cost_usd": 0.01                // subagent.complete (conditional)
}
```
Per-type notes:
- `subagent.spawn_requested`: thin — only `{goal, task_count, task_index, text}`
  (emitted without identity enrichment).
- `subagent.start`: identity base + `text` (goal/preview).
- `subagent.thinking`: identity base + `text` (thinking text).
- `subagent.tool`: identity base + `tool_name`, `tool_preview`, `text`.
- `subagent.progress`: identity base + `text` (batched tool-name summary).
- `subagent.complete`: `status`, `duration_seconds`, `summary`, token rollups,
  `files_read`/`files_written`, `output_tail`, optional `cost_usd`.
- `subagent.text` exists in Python but is NEVER sent to the parent session —
  do not rely on it.
Keyed by `subagent_id` / `parent_id` for the spawn tree.

### `delegation.status` (P3-05)
Params: none.
Result (`server.py:9877`):
```jsonc
{
  "active": [
    {"subagent_id": "...", "parent_id": null, "depth": 0, "goal": "...",
     "model": "sonnet"|null, "started_at": 1690000000.0, "status": "running",
     "tool_count": 3, "last_tool": "..."}   // last_tool present when known (not in TS)
  ],
  "paused": false,
  "max_spawn_depth": 3,
  "max_concurrent_children": 4
}
```

### `delegation.pause` (P3-05)
Params: `{"paused": true}` to pause, `{"paused": false}` to resume (defaults
true if omitted).
Result (`server.py:9897`): `{"paused": <new bool state>}`.

### `subagent.interrupt` (P3-05)
Params: `{"subagent_id": "<required>"}` (empty → error **4000**).
Result (`server.py:9905`): `{"found": <bool>, "subagent_id": "..."}`.

### `agents.list` (P3-05)
Params: none.
Result (`server.py:17103`):
```jsonc
{"processes": [{"session_id": "...", "command": "<=80 chars", "status": "...", "uptime": 12.3}]}
```

### `spawn_tree.save` (P3-06)
Params: `{"session_id": "...", "subagents": [...],  // required non-empty
          "started_at": <num|null>, "finished_at": <num>, "label": "..."}`.
Result (`server.py:9978`): `{"path": "...", "session_id": "..."}`.

### `spawn_tree.list` (P3-06)
Params: `{"session_id": "...", "limit": 50, "cross_session": false}`.
Result (`server.py:10021`):
```jsonc
{"entries": [{"path": "...", "session_id": "...", "finished_at": <num>,
              "started_at": <num|null>, "label": "...", "count": 3}]}
```
Sorted by `finished_at` desc.

### `spawn_tree.load` (P3-06)
Params: `{"path": "<required>"}` (empty → **4000**; path escape → **4030**).
Result (`server.py:10072`): the saved snapshot verbatim:
`{"session_id", "started_at": <num|null>, "finished_at": <num>, "label",
  "subagents": [...]}`  (`subagents` is opaque; TUI-assembled.)

---

## Steering & remaining prompts

### `session.steer` (P3-07)
Params: `{"session_id": "<live id>", "text": "<guidance>"}` (empty text →
error **4002**; unknown session → **4001**; agent lacks steer → **4010**).
Result (`server.py:10096`): `{"status": "queued"|"rejected", "text": "<echo>"}`.
`queued` = accepted mid-turn; `rejected` = agent declined.

### Interactive prompts (P3-08) — correlated by `request_id`
All emitted via the blocking bridge; `request_id` is injected into the payload.
Respond success → `{"status": "ok"}`; late reply on expired request →
`{"status": "expired"}`; no pending request → error **4009**. On timeout the
gateway emits `<name>.expire` `{request_id}`.

| Prompt | Event type (S→C) | Payload | Respond method | Answer key | Timeout |
|---|---|---|---|---|---|
| sudo | `sudo.request` | `{request_id}` | `sudo.respond` | `password` | 120s |
| secret | `secret.request` | `{prompt, env_var, request_id}` (+opt `metadata`) | `secret.respond` | `value` | 300s |
| terminal read | `terminal.read.request` | `{request_id}` (+opt `start`, `count`) | `terminal.read.respond` | `text` | 30s |

Respond params: `{session_id?, request_id, <answer key>: <value>}`. `sudo` and
`secret` require secure text entry (password field); the values are never
stored. Note `session.interrupt` also clears pending sudo/secret/clarify for
the session.
