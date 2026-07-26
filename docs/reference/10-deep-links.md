# Deep Links & Routing (P9-02)

The Flit app supports deep links for opening specific sessions and kanban boards via URL.

## Supported Deep-Link URLs

### Session Links
```
flit://session/<durable-id>
/session/<durable-id>
```

Opens the chat screen bound to a specific session. The `<durable-id>` is the **durable/stored session id** (NOT the ephemeral live id) — that's the id that persists across app restarts and is stable for sharing/bookmarking.

**Why durable and not live?** Protocol §9 distinguishes two kinds of session id:
- **Live id**: short ephemeral id used for `session.prompt`, `session.interrupt`, etc. Valid only for the current connection lifetime.
- **Durable id**: stable stored id used for `session.list`, `session.resume`, `session.delete`. Persists across restarts.

Deep links MUST use the durable id because:
1. A shared/bookmarked URL needs to work tomorrow (live ids expire)
2. A cold-start deep link arrives before any session is bootstrapped (no live id exists yet)
3. The durable id can be resolved to a live id (via `session.resume`) when needed

### Kanban Board Links
```
flit://plugins/kanban/<board-slug>
/plugins/kanban/<board-slug>
```

Opens the kanban board for a specific board slug. The existing `/plugins/kanban` route (without a slug) still works and shows the current/default board.

The board slug is fed through `selectedKanbanBoardProvider` so `KanbanBoardNotifier.build()` passes it to `repository.board(board: slug)`.

### Task Links
Task detail links (`/task/:id`) are NOT implemented because the task detail UI is a modal sheet, not a standalone screen. If a full-screen task detail view is added later, the route can be added as:
```dart
GoRoute(
  path: '/task/:id',
  name: 'task-deep-link',
  builder: (context, state) {
    final id = state.pathParameters['id'] ?? '';
    return TaskDetailScreen(taskId: id);
  },
),
```

## URL Schemes

### Mobile (iOS, Android, macOS)
Custom scheme: `flit://`

Examples:
- `flit://session/abc123def456`
- `flit://plugins/kanban/my-board`

Registered via:
- **Android**: `AndroidManifest.xml` intent-filter with `<data android:scheme="flit"/>`
- **iOS/macOS**: `Info.plist` with `CFBundleURLTypes` + `FlutterDeepLinkingEnabled`

**Note**: HTTPS App Links (`https://flit.example.com/session/...`) require a real domain + `.well-known/assetlinks.json` / `apple-app-site-association` files, which are not configured. Custom scheme only for now.

### Web
Web builds handle path-based URLs natively via `go_router` (e.g. `https://app.example.com/session/abc123`). No special configuration needed.

### Desktop (Linux, Windows)
Custom scheme registration on Linux/Windows is platform-specific and not implemented. Path-based URLs work when the app is already running.

## Connection Guard & Pending Deep Links

Deep links can arrive at cold start before the user has connected to a gateway. The router guards connection-requiring routes:

1. **Guarded paths** (require a connection):
   - `/session/:id`
   - `/plugins/kanban/:board`
   - `/chat`
   - `/plugins`
   - `/agents`
   - `/settings/**`

2. **Redirect flow**:
   - Router checks `connectionConfigProvider` (null = not connected)
   - If no config → redirect to `/connect` AND store the original location in `pendingDeepLinkProvider`
   - User connects via the connect screen
   - On successful connect, `ConnectScreen` consumes the pending link via `pendingDeepLinkProvider.notifier.consumePending()` and navigates there instead of defaulting to `/chat`

3. **No loop**: The guard never redirects `/connect` itself to avoid an infinite loop.

## Session Resolution

The `SessionDeepLinkScreen` resolves a durable id by:

1. **Already active?** No-op if the requested durable id is already `activeSessionProvider.durableId`.
2. **In session list?** If the id exists in `sessionListProvider`, use `SessionActions.switchToSummary()` which:
   - Reuses the live id if the session is still live (via `sessionIdMapProvider`)
   - Falls back to `session.resume` if the session is durable-only
3. **Unknown id?** Direct `repository.resume(durableId)` call, which either succeeds (switches + seeds history) or fails (shows error + retry button).

Errors are surfaced in the UI (not thrown) following the app-wide controller convention.

## Implementation Files

### Core Routing
- `lib/core/router/app_router.dart` — GoRouter setup, routes, redirect guard
- `lib/core/router/pending_deep_link_provider.dart` — Stores pending deep-link location

### Screens
- `lib/presentation/sessions/session_deep_link_screen.dart` — Resolves session durable id
- `lib/presentation/plugins/kanban/kanban_deep_link_screen.dart` — Selects kanban board slug
- `lib/presentation/common/not_found_screen.dart` — Friendly 404 for unknown paths

### Application Logic
- `lib/application/sessions/deep_link_resolver.dart` — Session resolution provider + state
- `lib/application/plugins/plugin_providers.dart` — Added `selectedKanbanBoardProvider`

### Platform Manifests
- `android/app/src/main/AndroidManifest.xml` — Custom scheme intent-filter
- `ios/Runner/Info.plist` — `CFBundleURLTypes` + `FlutterDeepLinkingEnabled`
- `macos/Runner/Info.plist` — `CFBundleURLTypes` + `FlutterDeepLinkingEnabled`

## Testing

See:
- `test/core/router/app_router_test.dart` — Router resolution, guards, not-found
- `test/application/sessions/deep_link_resolver_test.dart` — Session resolution logic
