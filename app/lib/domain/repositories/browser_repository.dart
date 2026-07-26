/// Repository interface for browser & preview control (ticket P9-05).
library;

import 'package:flit/domain/models/browser_status.dart';

/// Browser & preview control repository — CDP connect/disconnect/status and
/// preview.restart (hidden agent for live-reloading a URL in the browser).
abstract interface class BrowserRepository {
  /// Query browser connection status (wire `browser.manage` action: "status").
  ///
  /// Returns the current CDP connection state: connected + url, or
  /// disconnected.
  Future<BrowserStatus> status();

  /// Connect to Chrome DevTools Protocol (wire `browser.manage` action:
  /// "connect").
  ///
  /// [url] is the CDP WebSocket URL; omit it to use the gateway's default. A
  /// given url may be normalized by the gateway, so ALWAYS read the returned
  /// `url` rather than echoing what you sent.
  ///
  /// [sessionId] is OPTIONAL. When provided, human-readable progress lines are
  /// emitted as `browser.progress` events (subscribe via [progress]); when
  /// omitted, they come back in the result's `messages` list instead. This is
  /// a wire quirk: `browser.progress` events are ONLY emitted when a
  /// `session_id` was passed.
  ///
  /// On failure to reach/launch a browser it may return a SUCCESSFUL RPC
  /// result carrying `connected: false` with `messages` — this is NOT an error
  /// response. Or it may return a JSON-RPC error (code 4015: bad/unsupported
  /// url or action; code 5031: could not reach CDP).
  Future<BrowserStatus> connect({String? url, String? sessionId});

  /// Disconnect from CDP (wire `browser.manage` action: "disconnect").
  ///
  /// Always returns `{connected: false}`.
  Future<BrowserStatus> disconnect();

  /// Stream of `browser.progress` events for the given [sessionId] — only
  /// emitted when the corresponding `browser.manage` call was made WITH a
  /// `session_id` param (see [connect]).
  Stream<BrowserProgressLine> progress(String sessionId);

  /// Restart a preview URL (wire `preview.restart`).
  ///
  /// Launches a hidden background agent that navigates to [url], waits for
  /// load, and reports progress via `preview.restart.progress` events. The
  /// result is returned IMMEDIATELY as `{task_id: "preview_<hex6>"}` — the
  /// agent runs in a background thread and emits progress/complete events on
  /// the PARENT [sessionId] (required).
  ///
  /// [url] is REQUIRED (non-empty). [cwd] and [context] are optional context
  /// hints for the agent. Throws a GatewayException (code 4012) when [url] is
  /// missing or empty.
  ///
  /// Subscribe to [previewEvents] to consume progress lines and the final
  /// result.
  Future<String> restartPreview({
    required String sessionId,
    required String url,
    String? cwd,
    String? context,
  });

  /// Stream of `preview.restart.progress` and `.complete` events for the given
  /// [sessionId]. Each event carries a [taskId] to correlate frames from
  /// multiple concurrent restart tasks.
  ///
  /// Progress events emit [text] + [level] ("info" or "error"; the first frame
  /// may omit level, defaulting to "info"). Complete events emit the final
  /// [text] — the agent's response, or "error: ..." on failure.
  Stream<PreviewRestartEvent> previewEvents(String sessionId);
}

/// A single preview.restart event: progress or complete. Both carry [taskId]
/// for correlation; progress events include [level]; complete events are
/// marked [terminal].
final class PreviewRestartEvent {
  const PreviewRestartEvent({
    required this.taskId,
    required this.text,
    required this.level,
    this.terminal = false,
  });

  /// Wire `task_id` — correlates all frames from one restart task.
  final String taskId;

  /// Wire `text` — a progress line or the final result text.
  final String text;

  /// Wire `level` — "info" or "error" (defaults to "info" when absent).
  final String level;

  /// True for `.complete` events, false for `.progress`.
  final bool terminal;

  @override
  bool operator ==(Object other) {
    return other is PreviewRestartEvent &&
        other.taskId == taskId &&
        other.text == text &&
        other.level == level &&
        other.terminal == terminal;
  }

  @override
  int get hashCode => Object.hash(taskId, text, level, terminal);

  @override
  String toString() {
    return 'PreviewRestartEvent(taskId: $taskId, text: $text, '
        'level: $level, terminal: $terminal)';
  }
}
