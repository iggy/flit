# Hermes Flutter

A cross-platform (mobile + desktop) client for [Hermes Agent](https://github.com/NousResearch/hermes-agent),
built in Flutter. It connects to a running Hermes **gateway** and gives you
chat, tool-calling, model selection, plugins (kanban, etc.), and — over
successive phases — full parity with the existing desktop/TUI experiences.

> **Status:** Planning. No code has been written yet. This repository currently
> holds the design and the phased implementation plan under [`docs/`](docs/).
> Start at [`docs/roadmap.md`](docs/roadmap.md).

## What this is

Hermes already ships four clients: a desktop app (Electron), a web dashboard,
a terminal UI (Ink/React), and a plain CLI. This project adds a **fifth**: a
Flutter app that runs on iOS, Android, macOS, Windows, and Linux from one
codebase, with mobile as a first-class target the others don't serve.

The app is a **gateway client**. It does *not* embed or spawn the Python
backend the way the Electron desktop app does — it connects to a gateway you
point it at (URL + token). That keeps the mobile story simple and the app
small.

## How it talks to Hermes

The app speaks the same protocol the desktop app and TUI use: **newline-delimited
JSON-RPC 2.0 over a WebSocket** at `/api/ws`, dispatched by the gateway's
`tui_gateway.server.dispatch()`. Some features (notably the kanban plugin) are
served as **REST** on the same host/port. Both are authenticated by the same
token.

The full, source-grounded protocol contract lives in
[`docs/reference/`](docs/reference/). Every claim there is cited to a
`file:line` in the `hermes-agent` repo so an implementer can verify it.

## Repository layout

```
hermes-agent-flutter/
├── README.md                     ← you are here
├── docs/
│   ├── roadmap.md                ← phase overview + sequencing (read first)
│   ├── reference/                ← the gateway contract (grounded in source)
│   │   ├── 00-overview.md
│   │   ├── 01-gateway-protocol.md
│   │   ├── 02-rpc-index.md
│   │   ├── 03-mvp-wire-shapes.md
│   │   ├── 04-app-architecture.md
│   │   ├── 05-conventions.md
│   │   └── 06-kanban-rest.md
│   ├── design/
│   │   └── theming.md            ← Material 3 now, "match Hermes skin" later
│   └── phases/
│       ├── phase-0-foundation.md
│       ├── phase-1-mvp.md        ← the demo target
│       ├── phase-2-session-depth.md
│       ├── phase-3-agent-transparency.md
│       ├── phase-4-config-and-models.md
│       ├── phase-5-automation-and-plugins.md
│       ├── phase-6-memory-and-learning.md
│       ├── phase-7-rich-io.md
│       ├── phase-8-auth-and-billing.md
│       └── phase-9-platform-polish.md
└── app/                          ← the Flutter project (created in Phase 0)
```

## For implementers (including smaller models)

The plan is written so that most tickets can be picked up and completed
**independently**, by a less-capable model, without needing to re-derive the
protocol. Before implementing any ticket:

1. Read [`docs/reference/05-conventions.md`](docs/reference/05-conventions.md) once.
2. Read the ticket. Each ticket lists its **inputs** (which reference sections
   it depends on), **deliverables** (files to create), and **acceptance
   criteria** (how to know it's done).
3. Ground every wire interaction in [`docs/reference/03-mvp-wire-shapes.md`](docs/reference/03-mvp-wire-shapes.md)
   or the relevant reference section. Do not invent RPC method names or fields.

## Prerequisites

- Flutter SDK (stable channel) — **not currently installed on the dev machine**;
  installing it is the first task in [Phase 0](docs/phases/phase-0-foundation.md).
- A running Hermes gateway to connect to (local `hermes dashboard`, or a remote
  one). See Phase 0 for how to stand one up for development.
