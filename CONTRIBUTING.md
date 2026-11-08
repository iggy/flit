# Contributing to flit

Thanks for helping. This page is for people building flit from source or
changing its code. If you just want to use flit, start with the
[README](README.md).

[`AGENTS.md`](AGENTS.md) (also `CLAUDE.md`) has the build and test commands
and the architecture rules in full. It's written for coding agents but it's
the source of truth for humans too.

## Repository layout

```
flit/
├── README.md                     ← for users
├── CONTRIBUTING.md               ← you are here
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

## Server (Go)

Requires Go (see `server/go.mod` for the version). No cgo: binaries are
static and cross-compile for Linux, macOS and Windows on amd64 and arm64.

```sh
cd server
go build ./...
go test ./...                     # add -race locally (needs cgo)
go run ./cmd/flit serve           # first run writes config + token, prints the token
```

Release-style build (what CI does; must stay cgo-free):

```sh
CGO_ENABLED=0 go build -trimpath -o flit ./cmd/flit
```

Rules of the road:

- **No cgo, ever.** Pick pure-Go dependencies (e.g. `modernc.org/sqlite`).
- **Config is YAML only** and hot-reloads. New settings must take effect
  live. Unknown keys are errors.
- **Every RPC requires the token**, localhost included. The one exception is
  webhook deliveries under `/webhooks/`.
- **The event log is the source of truth.** Persist, then publish.
- **Schema changes** append a migration to `store.migrations`; never edit one
  that has shipped.
- Test agent behaviour against `llmtest`, not a real model. The real-model
  test (`TestLlamaCppCodingTask`) runs only with
  `FLIT_TEST_LLAMA_URL=http://host:8080/v1` (optional
  `FLIT_TEST_LLAMA_MODEL`, `FLIT_TEST_LLAMA_KEY`).

See [`AGENTS.md`](AGENTS.md) for the complete list.

## API schema

Schema first: change the `.proto`, then regenerate. Never hand-edit
generated code.

```sh
cd proto
buf lint
buf format -w
buf generate      # Go -> server/gen, Dart -> proto/dart/lib/src/gen
```

`buf generate` uses remote plugins on the Buf Schema Registry (network
needed). CI fails if generated code is stale.

## App (Flutter)

### Prerequisites

- **Flutter SDK 3.44.8** (stable channel). The dev machine keeps it at
  `~/flutter`; add `~/flutter/bin` to your `PATH`. See
  [Phase 0](docs/phases/phase-0-foundation.md) for setup notes.
- **Linux build deps** (Debian/Ubuntu), needed for the GTK + secure-storage
  native build:

  ```sh
  sudo apt install clang cmake ninja-build libgtk-3-dev libsecret-1-dev xz-utils
  ```

  `libsecret-1-dev` is required by `flutter_secure_storage` (used to store
  device tokens). Without it the Linux desktop build fails at CMake's
  `pkg_check_modules` step with `libsecret-1>=0.18.4 … not found`.
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

## The Hermes gateway client

Besides flit servers, the app can connect to a Hermes Agent **gateway**.
Hermes already ships four clients (desktop app, web dashboard, terminal UI,
CLI); this app is a fifth that runs on iOS, Android, macOS, Windows and Linux
from one codebase. It does *not* embed or spawn the Python backend; it
connects to a gateway you point it at.

It speaks the same protocol the desktop app and TUI use: **newline-delimited
JSON-RPC 2.0 over a WebSocket** at `/api/ws`. Some features (notably the
kanban plugin) are served as **REST** on the same host and port. The full,
source-grounded protocol contract lives in
[`docs/reference/`](docs/reference/); every claim there is cited to a
`file:line` in the `hermes-agent` repo.

flit code and Hermes code must stay separate: flit code must not depend on
Hermes providers and vice versa (see `AGENTS.md`).

## Picking up a ticket (app)

Work is organised as phased tickets in `docs/phases/`. Most can be
completed independently. Before implementing (or extending) any ticket:

1. Read [`docs/reference/05-conventions.md`](docs/reference/05-conventions.md) once.
2. Read the ticket. Each lists its **inputs** (which reference sections it
   depends on), **deliverables** (files to create), and **acceptance
   criteria** (how to know it's done).
3. Ground every wire interaction in
   [`docs/reference/03-mvp-wire-shapes.md`](docs/reference/03-mvp-wire-shapes.md)
   or the relevant reference section. Do not invent RPC method names or fields.

## Release process

Create a tag with a description (`git tag --sign`) and then push
(`git push origin --tags`). CI creates the GitHub release and attaches the
app builds, the server binaries, and a SHA-256 checksums file.

The server is built for Linux, macOS and Windows on amd64 and arm64 and
packaged as `flit-server-<version>-<os>-<arch>.tar.gz` (`.zip` on Windows),
each containing the `flit` binary and `LICENSE`. The version is the tag
without its leading `v`, and is stamped into the binary (`flit version`).
The Server workflow still builds on every change, but only the Release
workflow's archives are published. `flit-<version>-sha256sums.txt` covers
every asset on the release.
