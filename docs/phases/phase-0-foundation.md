# Phase 0 — Foundation

**Goal:** a Flutter project exists, the transport core (RPC + REST clients) is
built and unit-tested against fakes, and the app can connect to a real gateway
and observe `gateway.ready`. No chat UI yet — this phase de-risks the protocol.

**Exit criteria:** running the app, entering a gateway URL + token, and tapping
Connect prints/toasts `gateway.ready` and the gateway version from
`/api/status`. All transport unit tests pass. `flutter analyze` clean.

**Reference inputs:** `reference/01-gateway-protocol.md` (§1–5),
`reference/04-app-architecture.md`, `reference/05-conventions.md`.

---

## P0-01 — Install the toolchain (human/dev task)

**Goal:** Flutter stable installed and `flutter doctor` green for the targets we
care about (start with the current desktop platform + one mobile emulator).

- Flutter/Dart are **not currently installed** on this machine. Install the
  stable channel; add to PATH.
- `flutter doctor` — resolve at least: Flutter SDK, one device (Linux desktop or
  Android emulator). iOS toolchain only needed on macOS.
- **Acceptance:** `flutter --version` works; `flutter doctor` shows no blocking
  errors for the chosen first target.
- **Notes:** this is a prerequisite task, not app code. Record the pinned
  Flutter version in `app/README.md`.

## P0-02 — Create the Flutter project + git

**Goal:** scaffold the app under `app/` and initialize git.

- `flutter create --org com.nousresearch --project-name hermes app`
  (platforms: enable android, ios, linux, macos, windows; web optional).
- `git init` at the repo root (`hermes-agent-flutter/`), add a Flutter
  `.gitignore`, commit the scaffold + the existing `docs/`.
- Set up `analysis_options.yaml` with `flutter_lints` (or `very_good_analysis`)
  and treat lints strictly.
- **Deliverables:** `app/` project tree; root `.gitignore`; first commit.
- **Acceptance:** `cd app && flutter run` shows the default counter app on the
  first target; `flutter analyze` clean.

## P0-03 — Add & pin dependencies

**Goal:** add the packages from `reference/04-app-architecture.md` and pin
versions.

- Add: `flutter_riverpod`, `riverpod_annotation`, `web_socket_channel`, `dio`,
  `freezed_annotation`, `json_annotation`, `flutter_secure_storage`, `go_router`,
  `flutter_markdown` (or `gpt_markdown`), `flutter_highlight`.
- Dev: `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`,
  `custom_lint`, `riverpod_lint`.
- **Acceptance:** `flutter pub get` succeeds; `dart run build_runner build`
  runs clean (even with nothing to generate yet).
- **Notes:** pin exact versions in `pubspec.yaml`; commit `pubspec.lock`.

## P0-04 — `ConnectionConfig` + secure storage

**Goal:** a model for a gateway connection and persistence for it.

- `data/transport/connection_config.dart`: immutable
  `ConnectionConfig {String baseUrl; String? token; AuthMode authMode}` with
  `AuthMode { token, oauth }`. Include URL normalization mirroring
  `connection-config.cjs:40-63` (require http/https; strip trailing slash, hash,
  query; preserve path prefix).
- `data/storage/`: save/load the config; store the **token** in
  `flutter_secure_storage`, the rest in shared prefs.
- Helper `wsUrlFor(ConnectionConfig)` → `ws(s)://host<prefix>/api/ws?token=…`
  (see protocol §2.1); redaction helper for logging.
- **Deliverables:** the config model, storage service, URL builder, and unit
  tests for normalization + WS URL building (port the cases in
  `connection-config.test.cjs`).
- **Acceptance:** unit tests cover: bare host, host with prefix, https→wss,
  trailing slash, token URL-encoding, redaction.

## P0-05 — `GatewayRestClient`

**Goal:** authenticated HTTP client.

- `data/transport/gateway_rest_client.dart` using `dio`. Base URL from config;
  interceptor injects `X-Hermes-Session-Token` in token mode (nothing for public
  paths). Typed error mapping.
- Implement `Future<GatewayStatus> status({String? profile})` hitting
  `GET /api/status` and parsing the fields in protocol §1 (esp. `auth_required`,
  `version`, `gateway_running`).
- **Deliverables:** the REST client + `GatewayStatus` DTO + `status()`.
- **Acceptance:** unit test against a mock `dio` returning a canned `/api/status`
  body asserts parsed fields and correct `authMode` inference
  (`auth_required` → `AuthMode`).

## P0-06 — `GatewayRpcClient` (the core)

**Goal:** the JSON-RPC-over-WS client, ported from `gatewayClient.ts` (attach
mode only).

- `data/transport/gateway_rpc_client.dart`:
  - `connect(ConnectionConfig)` opens `web_socket_channel` to the WS URL.
  - **Inbound handling:** on each WS message, **split on `\n`**, JSON-decode each
    line, route: id-match → resolve pending; `method=="event"` → push to the
    events `StreamController.broadcast`; else drop (protocol §3 routing rule).
  - `request<T>(method, params)`: mint string id (`r{n++}`), register a
    `Completer` with a timeout (default 120s), send frame; resolve on response,
    reject on error frame or timeout.
  - Emit a `ConnectionState` stream: `connecting → ready` (on `gateway.ready`) →
    `reconnecting`/`closed`.
  - Reconnect with exponential backoff (cap ~30s); reset pending on transport
    swap (reject in-flight with a clear error).
- **Deliverables:** the client + `GatewayEvent` base type +
  `ConnectionState` enum.
- **Acceptance (unit tests against a fake WS channel):**
  - resolves a request when a matching-id response arrives;
  - handles **two frames in one message** (a delta + a response);
  - dispatches an event that arrives **before** a pending response;
  - surfaces an error frame as a rejected request;
  - times out a request with no response;
  - transitions to `ready` only after `gateway.ready`.
- **Notes:** this is the load-bearing class — the fake-WS tests are mandatory.
  Do not skip the multi-frame-per-message test; it's the #1 real-world gotcha.

## P0-07 — Riverpod wiring + connect smoke screen

**Goal:** a minimal screen that exercises the whole transport end to end.

- Providers: `connectionConfigProvider`, `restClientProvider`,
  `rpcClientProvider`, `connectionStateProvider` (streams the client's state),
  `gatewayEventsProvider` (streams events).
- `presentation/connect/connect_screen.dart`: fields for URL + token, a Connect
  button. On connect: call `status()` (show version + `auth_required`), then open
  the RPC socket; show a live connection-state chip; when `gateway.ready`
  arrives, toast "Connected to Hermes vX.Y".
- **Deliverables:** providers + connect screen wired into `main.dart`/router.
- **Acceptance:** against a **real local gateway** (see below), entering URL +
  token and connecting shows the version and reaches `ready`. Against a wrong
  token, shows a clear 4401/auth error (not a silent hang).

---

## Standing up a gateway for development

Most tickets can be developed against recorded fixtures, but P0-05/06/07 want a
real backend. In the `hermes-agent` checkout:

- Run the dashboard (which mounts `/api/ws`, `/api/status`, `/api/profiles`,
  and kanban): `hermes dashboard` (see its `--help` for host/port/token flags).
- Note the printed **URL** and **session token** (token mode; `/api/status`
  should report `auth_required: false` on loopback).
- If you need it reachable from a phone/emulator, bind to `0.0.0.0` and use the
  machine's LAN IP; keep it on a trusted network (token is a bearer secret).
- **Capture fixtures:** once connected, run one tool-using prompt and save the
  raw frames (a small logging tap in the RPC client) into
  `app/test/fixtures/turn_*.jsonl` for replay in later tests.

> Ask the user for how they normally launch a dev gateway if the above flags
> differ in their setup — don't assume.
