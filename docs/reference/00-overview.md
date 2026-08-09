# Reference: Overview & mental model

This directory is the **contract** between the Flutter app and the Hermes
gateway. It was produced by reading the `hermes-agent` source directly; every
non-obvious claim carries a `file:line` citation into that repo (paths are
relative to the `hermes-agent` checkout, a sibling of this repo at
`../hermes-agent/`).

**Verified against gateway `0.20.0` (release date `2026.8.3`).** Known gaps
between what these docs describe and what the app implements are tracked in
`../updates/gateway-0.18-to-0.20-required.md` (must-fix) and
`../updates/gateway-0.18-to-0.20-optional.md` (new capabilities / polish).

> Citations move. The `tui_gateway` refactor split the RPC handlers out of the
> monolithic `server.py` into `methods_session.py`, `methods_tools.py`,
> `methods_prompt.py`, `methods_config.py`, and `methods_complete.py`; the
> profiles REST router moved to `hermes_cli/web_routers/profiles.py`. When a
> citation looks wrong, grep for the symbol (`@method("session.foo")`,
> `def _handler`) rather than trusting the line number.

Read these in order:

| # | File | What it covers |
|---|------|----------------|
| 00 | this file | the big picture, terminology, the two surfaces |
| 01 | `01-gateway-protocol.md` | connect handshake, auth modes, framing, event lifecycle, quirks |
| 02 | `02-rpc-index.md` | the complete list of 145 JSON-RPC methods |
| 03 | `03-mvp-wire-shapes.md` | copy-paste-ready request/response/event JSON for the MVP |
| 04 | `04-app-architecture.md` | Flutter/Riverpod layering and package choices |
| 05 | `05-conventions.md` | coding rules for implementers (read once) |
| 06 | `06-kanban-rest.md` | the kanban plugin's REST surface |
| 07 | `07-session-depth-wire-shapes.md` | Phase 2 session methods (history, usage, compress, …) |
| 08 | `08-agent-transparency-wire-shapes.md` | Phase 3 slash commands, subagents, steering, prompts |
| 09 | `09-memory-learning-wire-shapes.md` | Phase 6 learning journey, insights, rollback |
| 10 | `10-deep-links.md` | deep-link / URL scheme handling |

## The one-paragraph mental model

A Hermes **gateway** is a long-lived process that owns agent **sessions**,
tools, model calls, and plugins. Clients attach to it and drive it. The Flutter
app is one such client. It attaches over a **single WebSocket** and exchanges
**JSON-RPC 2.0** frames: the client sends *requests* (`{id, method, params}`)
and gets *responses* (`{id, result|error}`); the server pushes *events*
(`{method:"event", params:{type, session_id, payload}}`) that are **not**
correlated to any request — they carry the streaming assistant output, tool
activity, and interactive prompts. That is the entire protocol.

## Two surfaces, one origin

A client connects to **one host/port** but uses two protocols against it:

1. **JSON-RPC over WebSocket** at `ws(s)://<host><prefix>/api/ws` — chat,
   tools, sessions, models, config, slash commands, most everything. This is
   `tui_gateway.server.dispatch()`, mounted by the dashboard web server at
   `hermes_cli/web_server.py:15923` (`gateway_ws`) via `tui_gateway/ws.py`.
2. **REST/HTTP** on the same origin — profile management (`/api/profiles/*`),
   the kanban plugin (`/api/plugins/kanban/*`), status (`/api/status`), auth
   (`/auth/password-login`, `/api/auth/providers`, `/api/auth/ws-ticket`),
   file downloads. These are FastAPI routes in `hermes_cli/web_server.py`,
   `hermes_cli/web_routers/` (profiles, sessions, cron, git, mcp, skills,
   tools), `hermes_cli/dashboard_auth/`, and plugin routers mounted under
   `/api/plugins/<name>/` (`web_server.py:17389`).

> **Why this matters:** the Flutter app needs *both* an RPC client and an HTTP
> client, but they share a base URL and a token. Profiles and kanban are REST,
> not RPC — do not look for `profile.*` or `kanban.*` JSON-RPC methods; they
> don't exist (`tui_gateway/server.py` has no such `@method`).

## Terminology

- **Gateway** — the Hermes backend process the app connects to.
- **Session** — one agent conversation. Has a **short live id**
  (`uuid4().hex[:8]`, used to address a running session) and a **durable
  stored id / session_key** (the DB row, used to list/resume/delete). See
  `01-gateway-protocol.md` §"Two kinds of session id".
- **Turn** — one user prompt → assistant reply cycle. Streams as a sequence of
  events (`message.start` → deltas → `message.complete`).
- **Profile** — a fully independent `~/.hermes/profiles/<name>/` HERMES_HOME
  directory (own model, skills, MCPs, secrets, persona). Managed via REST;
  switching means the gateway runs under a different HERMES_HOME. There is **no
  in-session profile-switch RPC** (`hermes_cli/profiles.py:1-9`,
  `hermes_cli/web_routers/profiles.py:373`).
- **Skin** — a theme payload (`colors`, `branding`, fonts) the gateway pushes
  in the `gateway.ready` event (under `payload.skin` as of v0.20 — see 01 §4)
  and re-broadcasts as `skin.changed`. Optional to use; see `design/theming.md`.
- **Plugin** — an optional bundle of capability. Some (kanban) expose REST
  surfaces; discover installed ones via `plugins.list` / `plugins.manage`.

## Trust the code, not the TypeScript types

The reference TypeScript client at `ui-tui/src/gatewayTypes.ts` is a useful
catalog of shapes, but it is **loose/aspirational** for several results. Where
the Python handler and the TS type disagree, **the Python handler wins**.
Known divergences (all confirmed against source):

| Method / event | TS says | Python actually returns | Source |
|---|---|---|---|
| `prompt.submit` result | `{ok?}` | `{status:"streaming"}` | `methods_prompt.py:367` |
| `session.interrupt` result | `{ok?}` | `{status:"interrupted"}` | `methods_session.py:2970` |
| `clarify.respond` result | `{ok?}` | `{status:"ok"}` (or `"expired"`) | `server.py:10606` |
| `approval.respond` result | `{ok?}` | `{resolved: <int count>}` | `methods_prompt.py:949` |
| `message.complete` payload | no `status` | has `status: complete\|interrupted\|error` | `server.py:10006` |
| `tool.progress` event | declared | **never emitted** by this gateway | `server.py:5482` |

These are called out again at their point of use in `01`/`03`.

The `gateway.ready` payload used to be the divergence in the other direction —
the TS type nested the skin under `payload.skin` and Python sent it bare. **As
of v0.20 Python nests it too** (`ws.py:313-327`), so the TS type is now the
correct one and flit's parser is the stale one (01 §4).
