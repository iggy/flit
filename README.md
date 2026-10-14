# Flit

An open source coding agent. flit is a **Go server** (`flit serve`) that runs
the agent, plus a cross-platform **Flutter app** (iOS, Android, macOS,
Windows, Linux, web) as its main front end.

> **Status:** early. The server runs agent sessions (milestone M1): an
> OpenAI-compatible model client with streaming and tool calls, built-in
> file and shell tools, and a persistent, replayable event log per session,
> all over a versioned protobuf/Connect API with token auth. The app is
> still a client for Hermes Agent (below) until it is switched over to the
> flit server in M2.

## Repository layout

```
flit/
├── README.md                     ← you are here
├── AGENTS.md / CLAUDE.md         ← build/test commands + architecture rules for agents
├── server/                       ← Go server; builds the `flit` binary
├── proto/                        ← API schema (protobuf, package flit.v1) + buf config
│   └── dart/                     ← generated Dart client package (flit_api) for the app
├── app/                          ← the Flutter app
└── docs/
    ├── roadmap.md                ← phase overview + sequencing
    ├── reference/                ← the Hermes gateway contract (grounded in source)
    ├── design/                   ← theming etc.
    └── phases/                   ← per-phase tickets (P0-… through P9-…)
```

## Server

Requires Go (see `server/go.mod` for the version). No cgo: binaries are
static and cross-compile for Linux, macOS and Windows on amd64 and arm64.

```sh
cd server
go build -o flit ./cmd/flit
./flit serve
```

On first run flit:

- writes a commented default config to `~/.config/flit/config.yaml` (the
  per-user config dir on macOS/Windows; override with `--config`);
- creates its data dir (`~/.local/share/flit` on Linux,
  `~/Library/Application Support/flit` on macOS, `%LocalAppData%\flit` on
  Windows; override with `data_dir` in the config or `--data-dir`);
- generates an API token, prints it once, and stores it in the data dir.
  Print it again with `flit token`.

Every API call needs that token, even from localhost. The API is
[Connect](https://connectrpc.com) (so plain HTTP/JSON, gRPC and gRPC-Web all
work), served on `127.0.0.1:7433` by default:

```sh
curl -H "Authorization: Bearer $(./flit token)" -H "Content-Type: application/json" \
  -d '{}' http://127.0.0.1:7433/flit.v1.SystemService/Version
```

Config is YAML only, and edits to the file are applied while flit runs,
including moving to a new listen address or turning TLS on (`tls.cert_file`
and `tls.key_file`). The one exception is `data_dir`, which is read at
startup.

### Models

flit talks to any OpenAI-compatible chat completions endpoint: llama.cpp's
`llama-server` (start it with `--jinja` so tool calls work), vLLM, Ollama's
`/v1`, OpenAI and so on. Configure as many as you like and pick a default:

```yaml
providers:
  - name: local
    base_url: http://localhost:8080/v1
  - name: openai
    base_url: https://api.openai.com/v1
    api_key_env: OPENAI_API_KEY
agent:
  provider: local
  model: qwen3-coder
```

### Sessions and tools

A session is a conversation with the agent in one working directory. The
agent has `read`, `write`, `patch`, `list`, `grep` and `shell` tools; file
tools can't leave the working directory. `AGENTS.md` and `CLAUDE.md` in the
working directory are added to the system prompt.

Shell commands are checked against `shell.allow` / `shell.deny` patterns in
the config; anything else follows `shell.default` (`ask` by default), which
pauses the turn until a client answers the prompt. These rules reduce
prompts; they are not a sandbox.

Everything a session does is stored as numbered events in `flit.db` in the
data dir. A client can attach from any event number, replay, and then follow
live, so reconnecting never loses anything.

The API schema lives in [`proto/`](proto/); `buf generate` there produces the
Go server code and the Dart client. See [`AGENTS.md`](AGENTS.md) for the
full workflow.

## App

### Today: a Hermes gateway client

Hermes already ships four clients: a desktop app (Electron), a web dashboard,
a terminal UI (Ink/React), and a plain CLI. This project adds a **fifth**: a
Flutter app that runs on iOS, Android, macOS, Windows, and Linux from one
codebase, with mobile as a first-class target the others don't serve.

The app is a **gateway client**. It does *not* embed or spawn the Python
backend the way the Electron desktop app does — it connects to a gateway you
point it at.

#### How it talks to Hermes

The app speaks the same protocol the desktop app and TUI use: **newline-delimited
JSON-RPC 2.0 over a WebSocket** at `/api/ws`, dispatched by the gateway's
`tui_gateway.server.dispatch()`. Some features (notably the kanban plugin) are
served as **REST** on the same host/port.

The full, source-grounded protocol contract lives in
[`docs/reference/`](docs/reference/). Every claim there is cited to a
`file:line` in the `hermes-agent` repo so an implementer can verify it.

### Prerequisites

- **Flutter SDK 3.44.8** (stable channel). The dev machine keeps it at
  `~/flutter`; add `~/flutter/bin` to your `PATH`. See
  [Phase 0](docs/phases/phase-0-foundation.md) for setup notes.
- A running Hermes gateway to connect to (local `hermes dashboard`, or a remote
  one).
- **Linux build deps** (Debian/Ubuntu), needed for the GTK + secure-storage
  native build:

  ```sh
  sudo apt install clang cmake ninja-build libgtk-3-dev libsecret-1-dev xz-utils
  ```

  `libsecret-1-dev` is required by `flutter_secure_storage` (used to store
  session tokens / cookies). Without it the Linux desktop build fails at
  CMake's `pkg_check_modules` step with `libsecret-1>=0.18.4 … not found`.
- **macOS**: Xcode + CocoaPods (for iOS/macOS targets).
- **Windows**: Visual Studio with the "Desktop development with C++" workload.
- **Android**: Android Studio / Android SDK + NDK (NDK is deferred; see roadmap).
- **Web**: no extra deps beyond Flutter.

### Develop

All commands run from [`app/`](app/):

```sh
cd app
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen (freezed/json/riverpod)
flutter analyze                                            # must stay clean
flutter test
flutter run -d linux
```

Builds: `task build-android|build-ios|build-web|build-macos|build-windows|build-linux`
(override with `BUILD_MODE=debug task …`; default is `release`). See
[`app/README.md`](app/README.md) and [`AGENTS.md`](AGENTS.md) for the full
command reference, pinned dependencies, and architecture rules.

### Screenshots

#### Android

<img src="docs/screenshots/android-chat.png" alt="Android chat" width="270" />
<img src="docs/screenshots/android-sessions.png" alt="Android sessions" width="270" />
<img src="docs/screenshots/android-menu.png" alt="Android menu" width="270" />

#### Linux

<img src="docs/screenshots/linux-chat.jpg" alt="Linux chat" width="480" />
<img src="docs/screenshots/linux-sessions.jpg" alt="Linux sessions" width="480" />

## For implementers (app)

The plan is written so that most tickets can be picked up and completed
**independently**. Before implementing (or extending) any ticket:

1. Read [`docs/reference/05-conventions.md`](docs/reference/05-conventions.md) once.
2. Read the ticket. Each ticket lists its **inputs** (which reference sections
   it depends on), **deliverables** (files to create), and **acceptance
   criteria** (how to know it's done).
3. Ground every wire interaction in [`docs/reference/03-mvp-wire-shapes.md`](docs/reference/03-mvp-wire-shapes.md)
   or the relevant reference section. Do not invent RPC method names or fields.

## Release process (app)

Create a tag with a description (`git tag --sign`) and then push (`git push origin --tags`). CI creates the github
release, etc.

Server binaries are built by the Server workflow on every change but are not
attached to releases yet.
