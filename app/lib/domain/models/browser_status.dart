/// Domain models for browser & preview control (ticket P9-05).
///
/// Wire shapes from gateway protocol (browser.manage, preview.restart).
library;

/// Status result from `browser.manage` (action: status|connect|disconnect).
final class BrowserStatus {
  const BrowserStatus({
    required this.connected,
    this.url,
    this.messages = const <String>[],
  });

  /// Wire `connected` — true when CDP connection is established.
  final bool connected;

  /// Wire `url` — the CDP WebSocket URL (null when disconnected).
  final String? url;

  /// Wire `messages` — human-readable status lines returned when a connect
  /// was attempted WITHOUT a `session_id` param (browser.progress events are
  /// only emitted when a session_id is passed; otherwise messages come back
  /// inline in the result). Empty when absent.
  final List<String> messages;

  @override
  bool operator ==(Object other) {
    return other is BrowserStatus &&
        other.connected == connected &&
        other.url == url &&
        _listEquals(other.messages, messages);
  }

  @override
  int get hashCode => Object.hash(connected, url, Object.hashAll(messages));

  @override
  String toString() {
    return 'BrowserStatus(connected: $connected, url: $url, '
        'messages: $messages)';
  }
}

/// One progress line from a `browser.manage` call that was made WITH a
/// `session_id` (event: browser.progress). [level] ∈ info|error.
final class BrowserProgressLine {
  const BrowserProgressLine({required this.message, required this.level});

  /// Wire `message` — the human-readable line.
  final String message;

  /// Wire `level` — "info" or "error".
  final String level;

  @override
  bool operator ==(Object other) {
    return other is BrowserProgressLine &&
        other.message == message &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(message, level);

  @override
  String toString() {
    return 'BrowserProgressLine(message: $message, level: $level)';
  }
}

/// One line from a `preview.restart` agent run (events:
/// preview.restart.progress / .complete). [level] defaults to "info" when the
/// first progress frame omits it; "error" when the line is an error.
final class PreviewRestartLine {
  const PreviewRestartLine({required this.text, required this.level});

  /// Wire `text` — the progress line or final result text.
  final String text;

  /// Wire `level` — "info" or "error"; defaults to "info" when absent.
  final String level;

  @override
  bool operator ==(Object other) {
    return other is PreviewRestartLine &&
        other.text == text &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(text, level);

  @override
  String toString() {
    return 'PreviewRestartLine(text: $text, level: $level)';
  }
}

/// A preview.restart task: initiated by `preview.restart`, emits
/// `preview.restart.progress` and `.complete` events. The task_id correlates
/// all frames; [done] flips when the `.complete` event arrives.
final class PreviewRestartTask {
  const PreviewRestartTask({
    required this.taskId,
    required this.url,
    this.lines = const <PreviewRestartLine>[],
    this.done = false,
    this.result,
  });

  /// Wire `task_id` — the unique identifier returned in the result and all
  /// events (format: `preview_<hex6>`).
  final String taskId;

  /// The `url` param that was passed to `preview.restart`.
  final String url;

  /// Accumulated progress lines (wire `text` from progress events + the final
  /// `text` from the complete event).
  final List<PreviewRestartLine> lines;

  /// True when the `preview.restart.complete` event has arrived.
  final bool done;

  /// Wire `text` from the `preview.restart.complete` event — the agent's final
  /// response, or "error: ..." on failure. Null until complete.
  final String? result;

  PreviewRestartTask copyWith({
    String? taskId,
    String? url,
    List<PreviewRestartLine>? lines,
    bool? done,
    String? result,
  }) {
    return PreviewRestartTask(
      taskId: taskId ?? this.taskId,
      url: url ?? this.url,
      lines: lines ?? this.lines,
      done: done ?? this.done,
      result: result ?? this.result,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PreviewRestartTask &&
        other.taskId == taskId &&
        other.url == url &&
        _listEquals(other.lines, lines) &&
        other.done == done &&
        other.result == result;
  }

  @override
  int get hashCode =>
      Object.hash(taskId, url, Object.hashAll(lines), done, result);

  @override
  String toString() {
    return 'PreviewRestartTask(taskId: $taskId, url: $url, '
        'lines: $lines, done: $done, result: $result)';
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
