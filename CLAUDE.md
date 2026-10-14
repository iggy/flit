# AGENTS.md

flit is an open source coding agent: a **Go server** (`flit serve`) plus a
**Flutter app** as its main front end. It is a monorepo:

```
server/   Go service. One static binary, `flit`. Module github.com/iggy/flit/server.
proto/    The API schema (protobuf, package flit.v1) + buf config. Source of truth.
  dart/   Generated Dart client package `flit_api`, for the app.
app/      Flutter app (iOS, Android, macOS, Windows, Linux, web).
docs/     Plans, reference docs, phase tickets.
```

The app is still the Hermes gateway client it started as; switching it over
to the flit server (via `proto/dart`) is milestone M2. Until then the app
section below describes it as it is.

## Server (`server/`)

```sh
cd server
go build ./...
go test ./...                     # add -race locally (needs cgo)
go run ./cmd/flit serve           # first run writes config + token, prints the token
go run ./cmd/flit token           # print the token again
```

Release-style build (what CI does; must stay cgo-free):

```sh
CGO_ENABLED=0 go build -trimpath -o flit ./cmd/flit
```

Rules:
- **No cgo, ever.** Binaries are static (`CGO_ENABLED=0`) for linux/darwin/windows
  on amd64 and arm64. Pick pure-Go deps (e.g. `modernc.org/sqlite`, not
  `mattn/go-sqlite3`).
- **Config is YAML only.** No JSON config files anywhere. Config hot-reloads
  (`internal/config.Watch`); new settings must take effect live, without a
  restart. Unknown keys are errors.
- **Every RPC requires the token**, localhost included
  (`Authorization: Bearer <token>`, enforced by `internal/auth.Interceptor`).
  Never log the token.
- State lives in the data dir (SQLite + flat files). Data will carry team and
  project ids (default team "Personal", default project "Scratch"); don't
  design anything that assumes a single user or project.
- Layout: `cmd/flit` (CLI), `internal/config`, `internal/auth`,
  `internal/server` (HTTP server + rebind), `internal/system`
  (SystemService), `gen/` (generated, don't edit).

## API (`proto/`)

Schema first: change the `.proto`, then regenerate. Never hand-edit
`server/gen` or `proto/dart/lib/src/gen`.

```sh
cd proto
buf lint
buf format -w
buf generate      # Go -> server/gen, Dart -> proto/dart/lib/src/gen
```

buf generate uses remote plugins on the Buf Schema Registry (network needed).
Plugin versions in `buf.gen.yaml` are pinned to match the runtime libraries
in `server/go.mod` and `proto/dart/pubspec.yaml`; bump them together. The API
is versioned from day one (`flit.v1`); breaking changes go in a new package.
CI fails if generated code is stale.

## App (`app/`)

Flutter client, currently for the Hermes Agent **gateway**. It is a *thin
gateway client*: it never spawns the Python backend, it connects to a running
gateway over WebSocket JSON-RPC (+ some REST) and renders chat, tool calls,
sessions, models, and plugins.

The Flutter project lives in **`app/`** — run all app commands from there.

### App commands

Flutter is expected at `~/flutter/bin` (add to `PATH`). A `Taskfile.yaml` in
`app/` wraps everything; raw `flutter` also works.

```sh
cd app
export PATH="$HOME/flutter/bin:$PATH"

flutter pub get                                          # or: task pub-get
dart run build_runner build --delete-conflicting-outputs # REQUIRED codegen; see below
flutter analyze                                          # task analyze — MUST stay clean
flutter test                                             # task test  (append -- --name foo)
flutter test test/path/to/one_test.dart                  # single file
flutter run -d linux                                     # task watch (DEVICE=chrome task watch)
```

Builds: `task build-android|build-ios|build-web|build-macos|build-windows|build-linux`.
Override build mode with `BUILD_MODE=debug task ...` (default `release`).

### Codegen is mandatory

`freezed`, `json_serializable`, and `riverpod_generator` produce the `*.g.dart`
and `*.freezed.dart` files that sit next to their sources (e.g.
`session_dtos.g.dart`, `gateway_event_parser.freezed.dart`). After editing any
DTO, freezed union, or annotated provider you **must** re-run
`dart run build_runner build --delete-conflicting-outputs` or analyze/test will
fail on missing generated parts. Generated files are excluded from lints.

### Architecture: four layers, dependencies point DOWN only

```
presentation/  Flutter widgets/screens. ConsumerWidgets that watch providers. Never touch a client/DTO.
application/   Riverpod providers & notifiers. State, orchestration, the event fold.
domain/        Plain immutable Dart models + repository *interfaces*. NO Flutter, NO I/O.
data/          Repository impls, the RPC + REST clients, DTOs (+ json), secure storage.
```

Rules that are enforced by convention (see `docs/reference/04-app-architecture.md`,
`05-conventions.md`):
- Presentation watches providers only; it never imports a client or DTO.
- `data/` never imports Flutter.
- **DTOs translate; domain models are clean.** Wire quirks are absorbed in
  `data/dto` + repositories via `.toDomain()`. Never expose a DTO above `data/`.

#### Data flow
`ConnectionStore` (secure storage) → `ConnectionConfig` → `GatewayRpcClient`
(WS) / `GatewayRestClient` (HTTP) → repository impls → application providers →
widgets. Repositories are re-minted on client swap (reconnect) so subscribers
re-subscribe to the new event stream — see `application/providers.dart` and
`connection/connection_providers.dart`. Client providers are **nullable**
(null = disconnected); callers must handle null.

#### The event fold — highest-value, most bug-prone code
`application/chat/message_fold.dart` is a **pure** reducer (no Riverpod, no I/O)
that folds the turn-event stream (`message.start/delta/complete`,
`tool.start/complete`, `approval.request`, `clarify.request`, `error`) into a
`FoldState` (message list + pending interactive prompts). Keep it pure and
unit-tested. Interactive prompts are NOT chat messages — they render inline and
are cleared by the notifier, not the fold.

### Protocol: never invent it

The gateway contract is documented and source-grounded in
**`docs/reference/`** (`01-gateway-protocol.md`, `02-rpc-index.md`,
`03-mvp-wire-shapes.md`, `06-kanban-rest.md`). Golden rule: every RPC method,
param, result field, and event field must come from those docs. If a shape
isn't documented, stop and add an open question — do not guess field names.
Where Python and TypeScript shapes disagree, **Python wins**.

Non-obvious protocol facts baked into the code:
- WS frames are **newline-delimited**; one WS message may carry multiple JSON
  frames. Split on `\n` before decoding.
- Client waits for a `gateway.ready` event before marking itself ready.
- Two session ids: short **live id** (prompt/interrupt) vs durable
  **stored/session_key id** (list/resume/delete). DTOs fold these into
  `liveId` / `durableId`.
- Default per-request timeout is **120s** (long handlers exist).
- Reconnect is client-driven with backoff; gated-mode WS tickets are
  single-use so a fresh URI is minted per reconnect attempt.
- Close codes 4401 / 4403 are terminal auth failures (no retry).

#### Auth
Loopback token mode (URL + session token, sent as `X-Hermes-Session-Token`) or
gated username/password (login → session cookies in the cookie jar → single-use
WS tickets). **The password is never stored.** Never log tokens, cookie values,
or full WS URLs — redact the query string.

### Conventions

- Files `snake_case.dart`; types `UpperCamelCase`; providers end in `Provider`,
  notifiers in `Notifier`. Prefer `final`; models are immutable.
- Strict analyzer: `strict-casts`, `strict-inference`, `strict-raw-types`, plus
  extra lints (`require_trailing_commas`, `always_use_package_imports`,
  `only_throw_errors`, `cancel_subscriptions`, `directives_ordering`, …). Use
  `package:flit/...` imports, not relative. Lints are treated as errors.
- Snake_case wire → Dart via `@JsonKey(name: 'session_id')`.
- Repositories return typed results / throw typed `GatewayException`
  (`core/errors/gateway_error.dart`); never let a raw `DioException` or socket
  error leak into a provider.

### Dependencies are pinned exact

`pubspec.yaml` uses exact versions and `pubspec.lock` is committed. Bump
deliberately — do **not** run `pub upgrade`. Note: `custom_lint` /
`riverpod_lint` are intentionally omitted (no release compatible with the
pinned riverpod 3.3 / freezed yet).

### Testing

- Mirror `lib/` structure under `test/`. Fixtures (captured wire frames) live in
  `test/fixtures/` (e.g. `turn_basic.jsonl`) — develop against recorded frames,
  no live backend needed for most work.
- Unit-test the event fold with exact frame sequences; unit-test the RPC client
  against a fake WS (inject `channelFactory` / `GatewayChannelFactory`) covering
  multiple frames per message, event-before-response, parse errors, timeouts.
- Widget tests exist for chat bubble, tool card, interactive prompts, etc.
- Don't mark work done with failing/absent tests where the ticket specifies them.

### Workflow context

Work is organized as phased tickets in `docs/phases/*` (stable IDs like
`P1-06`, referenced in commit messages). Each ticket lists Inputs, Deliverables,
Acceptance, and pitfalls. Read `docs/reference/05-conventions.md` once before
implementing.