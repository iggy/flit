# Reference: Complete JSON-RPC method index

Every method the gateway dispatch handles, grouped by concern. **128 methods
total** — 117 registered via `@method("...")` (`tui_gateway/server.py:1060`,
storing into the `_methods` dict) plus 11 `projects.*` via the
`@_projects_method(...)` wrapper (`server.py:10281`). Dispatch is a
decorator-registry lookup (`handle_request`, `server.py:1087`); unknown method →
JSON-RPC `-32601`.

Signature of every handler: `fn(rid, params: dict) -> dict`, returning
`_ok(rid, {...})` or `_err(rid, code, msg)`.

Several methods are **action-multiplexers** — one RPC with an `action`/`op`/`key`
param fanning to sub-behaviors: `config.set`, `config.get`, `cron.manage`,
`browser.manage`, `plugins.manage`, `skills.manage`, `tools.configure`,
`command.dispatch`, and the `billing.*` family.

The **phase** column maps each method to the plan phase that first needs it
(see `../roadmap.md`). ✱ = MVP.

## Sessions & lifecycle

| Method | Purpose | Phase |
|--------|---------|-------|
| `session.create` | Create a new agent chat session | 1 ✱ |
| `session.list` | List persisted/available sessions | 1 ✱ |
| `session.active_list` | List currently active in-memory sessions | 1 ✱ |
| `session.activate` | Mark/switch active session | 1 ✱ |
| `session.resume` | Resume an existing persisted session | 1 ✱ |
| `session.interrupt` | Interrupt the running turn | 1 ✱ |
| `session.most_recent` | Fetch most recently active session | 2 |
| `session.status` | Get session runtime status | 2 |
| `session.history` | Get session message history | 2 |
| `session.title` | Set/get session title | 2 |
| `session.usage` | Token/cost usage for session | 2 |
| `session.context_breakdown` | Break down context-window usage | 2 |
| `session.delete` | Delete a persisted session | 2 |
| `session.save` | Persist session state | 2 |
| `session.close` | Close/tear down an active session | 2 |
| `session.cwd.set` | Set the session working directory | 2 |
| `session.undo` | Undo last turn | 2 |
| `session.branch` | Branch a session into a new one | 2 |
| `session.compress` | Compress/summarize session context | 2 |
| `session.steer` | Steer/inject guidance into running turn | 3 |

## Prompting & turn control

| Method | Purpose | Phase |
|--------|---------|-------|
| `prompt.submit` | Submit a user prompt to the agent | 1 ✱ |
| `prompt.background` | Run a prompt as a detached background agent | 5 |
| `llm.oneshot` | One-shot LLM completion (no session) | 4 |

## Interactive responses

| Method | Purpose | Phase |
|--------|---------|-------|
| `approval.respond` | Respond to a tool-approval request | 1 ✱ |
| `clarify.respond` | Respond to an agent clarification | 1 ✱ |
| `sudo.respond` | Respond to a sudo password prompt | 3 |
| `secret.respond` | Respond to a secret/credential prompt | 3 |
| `terminal.read.respond` | Respond to a terminal read request | 3 |

## Models & providers

| Method | Purpose | Phase |
|--------|---------|-------|
| `model.options` | List available models/providers (+ auth state) | 1 ✱ |
| `model.save_key` | Save a provider API key | 4 |
| `model.disconnect` | Disconnect/clear a provider key | 4 |

> Setting the active model is **not** a `model.*` RPC — use
> `config.set{key:"model", value:"<model> --provider <slug>"}`. Reasoning effort
> = `config.set{key:"reasoning"}`; fast/service-tier = `config.set{key:"fast"}`.
> See `03-mvp-wire-shapes.md` §model.

## Config & display

| Method | Purpose | Phase |
|--------|---------|-------|
| `config.get` | Read one config value by key | 4 |
| `config.set` | Write one config value by key (multiplexer) | 1 ✱ (for model) |
| `config.show` | Human-readable grouped config summary | 4 |
| `setup.status` | First-run setup status | 4 |
| `setup.runtime_check` | Check runtime prerequisites | 4 |

The `display.*` family (thinking_mode, tui_compact, statusbar, etc.) is set via
`config.set` keys; those are TUI-presentation knobs, mostly not applicable to a
Flutter client. See `08` power-features notes if needed.

## Tools & MCP

| Method | Purpose | Phase |
|--------|---------|-------|
| `tools.list` | List available tools | 4 |
| `tools.show` | Show details of one tool | 4 |
| `tools.configure` | Enable/disable/configure tools (multiplexer) | 4 |
| `toolsets.list` | List tool sets/groups | 4 |
| `reload.mcp` | Reload MCP servers/tools | 4 |
| `reload.env` | Reload environment configuration | 4 |

## Slash commands & completion

| Method | Purpose | Phase |
|--------|---------|-------|
| `commands.catalog` | List available slash/CLI commands | 3 |
| `command.resolve` | Resolve a command string to a handler | 3 |
| `command.dispatch` | Dispatch a resolved command (multiplexer) | 3 |
| `slash.exec` | Execute a slash command (subprocess) | 3 |
| `cli.exec` | Execute a `hermes` CLI command headlessly | 3 |
| `complete.slash` | Slash-command autocompletion | 3 |
| `complete.path` | File-path / `@`-token autocompletion | 3 |
| `paste.collapse` | Collapse large pasted content | 7 |

## Plugins

| Method | Purpose | Phase |
|--------|---------|-------|
| `plugins.list` | List installed plugins `{name,version,enabled}` | 1 ✱ |
| `plugins.manage` | Plugins Hub: list/toggle (multiplexer) | 5 |

> The kanban plugin has **no RPC** — it's REST (`06-kanban-rest.md`).

## Projects (workspaces)

`projects.list` · `get` · `create` · `update` · `add_folder` · `remove_folder`
· `set_primary` · `archive` · `delete` · `set_active` · `for_cwd` ·
`discover_repos` · `record_repos` · `tree` · `project_sessions`
(`server.py:10281-10686`). Per-profile named multi-folder workspaces — the
closest in-session analog to a "workspace dropdown". **Phase 4.**

## Subagents & delegation

| Method | Purpose | Phase |
|--------|---------|-------|
| `delegation.status` | Active subagents + spawn limits + paused flag | 3 |
| `delegation.pause` | Pause/resume new subagent spawning | 3 |
| `subagent.interrupt` | Interrupt one running subagent | 3 |
| `agents.list` | List background agent processes | 3 |
| `spawn_tree.save` / `spawn_tree.list` / `spawn_tree.load` | Spawn-tree snapshots (/replay) | 3 |

Paired events: `subagent.spawn_requested` / `start` / `thinking` / `tool` /
`progress` / `complete` (payload = `SubagentEventPayload`, see
`gatewayTypes.ts:539`).

## Automation & cron

| Method | Purpose | Phase |
|--------|---------|-------|
| `cron.manage` | Manage cron jobs — action: list/add/remove/pause/resume | 5 |
| `handoff.request` / `handoff.state` / `handoff.fail` | Hand a session to a messaging platform | 5 |

## Memory, learning & insights

| Method | Purpose | Phase |
|--------|---------|-------|
| `learning.frames` | Render learning-timeline (/journey) frames | 6 |
| `learning.detail` | Get one journey node's content | 6 |
| `learning.edit` | Rewrite a journey node | 6 |
| `learning.delete` | Delete a journey node | 6 |
| `insights.get` | Aggregate session/message counts over a window | 6 |
| `project.facts` | Structured project facts for a cwd | 6 |

## Rollback / checkpoints

| Method | Purpose | Phase |
|--------|---------|-------|
| `rollback.list` | List git checkpoints for the session cwd | 6 |
| `rollback.diff` | Diff working tree vs a checkpoint | 6 |
| `rollback.restore` | Restore repo to a checkpoint hash | 6 |

## Rich input / attachments

| Method | Purpose | Phase |
|--------|---------|-------|
| `image.attach` | Attach an image by host path | 7 |
| `image.attach_bytes` | Attach an image from base64 (remote client) | 7 |
| `image.detach` | Remove an attached image | 7 |
| `pdf.attach` | Render a PDF to per-page PNGs and queue them | 7 |
| `file.attach` | Stage a non-image file → `@file:` ref | 7 |
| `clipboard.paste` | Grab a server-side clipboard image | 7 |
| `input.detect_drop` | Detect a dragged file/image path in text | 7 |
| `terminal.resize` | Resize the terminal/PTY dimensions | 7 |

> Mobile clients use `image.attach_bytes` / `file.attach` with base64/data-url,
> **not** the path-based `image.attach` (paths are host-local).

## Voice

| Method | Purpose | Phase |
|--------|---------|-------|
| `voice.toggle` | status/on/off/tts | 7 |
| `voice.record` | VAD push-to-talk start/stop; emits `voice.transcript`/`voice.status` | 7 |
| `voice.tts` | Speak text via TTS | 7 |

## Billing & credits

| Method | Purpose | Phase |
|--------|---------|-------|
| `credits.view` | Nous credit view | 8 |
| `billing.state` | Serialized billing state (balance/card/cap/auto-reload) | 8 |
| `billing.charge` | Post a credit top-up charge | 8 |
| `billing.charge_status` | Poll a charge's status | 8 |
| `billing.auto_reload` | Configure auto top-up | 8 |
| `billing.step_up` | Device-flow to grant charge scope | 8 |

> Billing handlers return structured `{ok, error, ...}` envelopes **even on
> failure** (`server.py:7228`) — branch on the typed error code, don't rely on
> RPC error frames.

## Processes & browser

| Method | Purpose | Phase |
|--------|---------|-------|
| `process.list` | Session-scoped background process registry | 5 |
| `process.kill` | Kill one background process (session-scoped) | 5 |
| `process.stop` | Kill ALL background processes (global) | 5 |
| `shell.exec` | Execute a raw shell command | 5 |
| `browser.manage` | Manage CDP browser: status/connect/disconnect | 9 |
| `preview.restart` | Restart the app serving a Preview URL | 9 |

## Cosmetic: the "pet" (petdex mascot)

16 methods — `pet.info` · `info.meta` · `cells` · `gallery` · `select` ·
`remove` · `export` · `rename` · `thumb` · `disable` · `scale` · `cancel` ·
`generate` · `generate.status` · `hatch`. A per-profile sprite mascot stored
under `display.pet.*`, ships spritesheet bytes as base64. **Entirely cosmetic —
Phase 9 (optional / stretch).**

## Misc

| Method | Purpose | Phase |
|--------|---------|-------|
| `verification.status` | Report verification/health status | 4 |
| `skills.reload` | Reload skill definitions | 5 |
| `skills.manage` | Manage skills (multiplexer) | 5 |
