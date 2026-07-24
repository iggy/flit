# Reference: Overview & mental model

This directory is the **contract** between the Flutter app and the Hermes
gateway. It was produced by reading the `hermes-agent` source directly; every
non-obvious claim carries a `file:line` citation into that repo (paths are
relative to the `hermes-agent` checkout, a sibling of this repo at
`../hermes-agent/`).

Read these in order:

| # | File | What it covers |
|---|------|----------------|
| 00 | this file | the big picture, terminology, the two surfaces |
| 01 | `01-gateway-protocol.md` | connect handshake, auth modes, framing, event lifecycle, quirks |
| 02 | `02-rpc-index.md` | the complete list of 128 JSON-RPC methods |
| 03 | `03-mvp-wire-shapes.md` | copy-paste-ready request/response/event JSON for the MVP |
| 04 | `04-app-architecture.md` | Flutter/Riverpod layering and package choices |
| 05 | `05-conventions.md` | coding rules for implementers (read once) |
| 06 | `06-kanban-rest.md` | the kanban plugin's REST surface |

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
   `hermes_cli/web_server.py:12711` via `tui_gateway/ws.py`.
2. **REST/HTTP** on the same origin — profile management (`/api/profiles/*`),
   the kanban plugin (`/api/plugins/kanban/*`), status (`/api/status`), auth
   (`/auth/password-login`, `/api/auth/providers`, `/api/auth/ws-ticket`),
   file downloads. These are FastAPI routes in `hermes_cli/web_server.py`,
   `hermes_cli/dashboard_auth/`, and plugin routers.

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
  `web_server.py:10790-10956`).
- **Skin** — a theme payload (`colors`, `branding`, fonts) the gateway pushes
  in the `gateway.ready` event. Optional to use; see `design/theming.md`.
- **Plugin** — an optional bundle of capability. Some (kanban) expose REST
  surfaces; discover installed ones via `plugins.list` / `plugins.manage`.

## Trust the code, not the TypeScript types

The reference TypeScript client at `ui-tui/src/gatewayTypes.ts` is a useful
catalog of shapes, but it is **loose/aspirational** for several results. Where
the Python handler and the TS type disagree, **the Python handler wins**.
Known divergences (all confirmed against source):

| Method / event | TS says | Python actually returns | Source |
|---|---|---|---|
| `prompt.submit` result | `{ok?}` | `{status:"streaming"}` | `server.py:8091` |
| `session.interrupt` result | `{ok?}` | `{status:"interrupted"}` | `server.py:7826` |
| `clarify.respond` result | `{ok?}` | `{status:"ok"}` | `server.py:9682` |
| `message.complete` payload | no `status` | has `status: complete\|interrupted\|error` | `server.py:8674` |
| `gateway.ready` payload | `{skin?:...}` | `payload` **is** the skin dict | `ws.py:324` |

These are called out again at their point of use in `01`/`03`.
