# Reference: App architecture

The target architecture for the Flutter app. Decided up front so tickets can be
implemented independently and compose cleanly. State management is **Riverpod**
(chosen for compile-safe DI + fine-grained reactive providers, which decompose
into small independently-testable units).

---

## Layered architecture

Four layers, dependencies point **downward only**. A widget never imports the
transport; a repository never imports a widget.

```
┌─────────────────────────────────────────────────────────────┐
│  presentation/   Flutter widgets + screens. Watch providers.  │
├─────────────────────────────────────────────────────────────┤
│  application/    Riverpod providers & notifiers. App state,   │
│                  orchestration, per-feature controllers.      │
├─────────────────────────────────────────────────────────────┤
│  domain/         Plain Dart models (immutable), enums, and    │
│                  repository *interfaces*. No Flutter, no I/O.  │
├─────────────────────────────────────────────────────────────┤
│  data/           Repositories (impl), the JSON-RPC client,    │
│                  the REST client, DTOs + (de)serialization,   │
│                  secure storage.                              │
└─────────────────────────────────────────────────────────────┘
```

- **domain/** models are hand-written immutable classes (or `freezed`) that the
  UI speaks in — e.g. `ChatMessage`, `ToolCall`, `SessionSummary`,
  `ModelProvider`, `ApprovalRequest`. They do **not** mirror wire shapes 1:1;
  DTOs in `data/` translate.
- **data/** owns the two clients (see below) and repositories that expose
  intent-level methods (`ChatRepository.submitPrompt(...)`, `Stream<TurnEvent>
  events(sessionId)`).
- **application/** holds Riverpod providers: connection state, the active
  session, the message list notifier that folds turn events into `ChatMessage`s,
  the model-picker controller, etc.
- **presentation/** is dumb-ish: `ConsumerWidget`s that watch providers and
  render.

## The transport core (data layer)

Two clients, one shared connection config (`{baseUrl, token, authMode}`).

### `GatewayRpcClient` (WebSocket / JSON-RPC)

Port of `ui-tui/src/gatewayClient.ts`, minus the child-process spawning (we only
do **attach** mode). Responsibilities:

- Open `wss?/api/ws?token=…`; wait for `gateway.ready` before marking ready.
- **Split inbound WS text on `\n`**, JSON-decode each line (multiple frames per
  message — see protocol §5).
- Maintain a `Map<String, Completer>` of pending requests keyed by string id
  (`r1`, `r2`, …); resolve/reject on matching response frames.
- Expose a broadcast `Stream<GatewayEvent>` for `method:"event"` frames.
- Per-request timeout (≥120s default; long handlers exist).
- Reconnect with exponential backoff; re-emit a connection-state stream so the
  app can show "reconnecting" and trigger `session.resume`.

Suggested surface:
```dart
abstract class GatewayRpcClient {
  Stream<ConnectionState> get connection;      // connecting/ready/reconnecting/closed
  Stream<GatewayEvent> get events;             // all server-pushed events
  Future<T> request<T>(String method, [Map<String,dynamic> params = const {}]);
  Future<void> connect(ConnectionConfig cfg);
  Future<void> close();
}
```

### `GatewayRestClient` (HTTP)

Thin `dio`/`http` wrapper that injects auth (`X-Hermes-Session-Token` header in
token mode) and the base URL. Used for `/api/status`, `/api/profiles/*`,
`/api/plugins/kanban/*`, `/api/auth/ws-ticket`, downloads.

## Event → state folding

The chat message list is derived by a notifier that subscribes to
`events.where((e) => e.sessionId == activeId)` and folds the turn lifecycle
(protocol §6) into an ordered `List<ChatMessage>`:

- `message.start` → append a streaming assistant message.
- `message.delta` → append text to the current streaming message.
- `tool.start` → attach a `ToolCall(status: running)` to the current message.
- `tool.complete` → resolve that `ToolCall` by `tool_id`.
- `message.complete` / `error` → finalize the message (mark terminal).
- `approval.request` / `clarify.request` → surface an `InteractivePrompt` the UI
  renders inline and answers via the repo.

Keep this fold **pure and unit-tested** — it's the highest-value test target and
the easiest place for a smaller model to introduce ordering bugs.

## Suggested folder layout (inside `app/`)

```
lib/
  main.dart
  core/                      # theming, routing, constants, result types
  data/
    transport/
      gateway_rpc_client.dart
      gateway_rest_client.dart
      connection_config.dart
    dto/                     # wire DTOs + json (mirror server shapes)
    repositories/            # ChatRepository, SessionRepository, ModelRepository, …
    storage/                 # secure token storage
  domain/
    models/                  # ChatMessage, ToolCall, SessionSummary, …
    repositories/            # abstract interfaces
  application/
    connection/              # connectionProvider, statusProvider
    chat/                    # messageListNotifier, composerController
    sessions/                # sessionListProvider, activeSessionProvider
    models/                  # modelPickerController
    plugins/                 # pluginListProvider, kanbanBoardProvider
  presentation/
    connect/                 # connect screen (URL + token)
    chat/                    # chat screen, message bubbles, tool cards
    sessions/                # session drawer/list
    models/                  # model picker sheet
    plugins/kanban/          # board view
    common/                  # shared widgets
```

## Package choices (pin exact versions in Phase 0)

| Concern | Package | Why |
|---|---|---|
| State/DI | `flutter_riverpod` + `riverpod_generator` | chosen approach; codegen keeps providers terse |
| Immutable models/unions | `freezed` + `json_serializable` | DTOs + sealed event unions with pattern matching |
| WebSocket | `web_socket_channel` | cross-platform, works on web too |
| HTTP | `dio` | interceptors for auth, good error surface |
| Secure token storage | `flutter_secure_storage` | keychain/keystore on mobile |
| Routing | `go_router` | declarative, deep-link friendly |
| Markdown render | `flutter_markdown` (or `gpt_markdown`) | assistant text is markdown (`rendered` field) |
| Code/diff display | `flutter_highlight` | tool `inline_diff` / code blocks |

## Cross-platform notes

- **Mobile** can't use path-based attach (`image.attach`) — use
  `image.attach_bytes` / `file.attach` with base64/data-url (protocol/RPC §rich
  input).
- **WebSocket on web** has no custom-header support — which is exactly why auth
  is query-string. Our design already assumes this, so the same client works on
  web if we ever target it.
- Store the token in `flutter_secure_storage`; never log the token or full WS
  URL (redact the query string, mirroring `gatewayClient.ts` `redactUrl`).
