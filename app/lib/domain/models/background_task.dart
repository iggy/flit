/// Plain domain models for background tasks (ticket P5-02).
///
/// NO Flutter, NO codegen — hand-written immutable with value equality.
library;

/// A `background.complete` event (P5-02): the gateway pushed a task completion
/// onto the parent session. Consumed by the background repository's stream.
final class BackgroundCompletion {
  const BackgroundCompletion({required this.taskId, required this.text});

  /// Server-assigned task id (e.g. "bg_ab12cd").
  final String taskId;

  /// Final response text, or "error: ..." on failure.
  final String text;

  @override
  bool operator ==(Object other) {
    return other is BackgroundCompletion &&
        other.taskId == taskId &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(taskId, text);

  @override
  String toString() {
    return 'BackgroundCompletion(taskId: $taskId, text: $text)';
  }
}

/// One background task item tracked client-side (UI state).
final class BackgroundTaskItem {
  const BackgroundTaskItem({
    required this.taskId,
    required this.prompt,
    this.done = false,
    this.result,
  });

  /// Server-assigned task id (e.g. "bg_ab12cd").
  final String taskId;

  /// The user prompt that was submitted.
  final String prompt;

  /// Whether the task is complete (a `background.complete` event arrived).
  final bool done;

  /// The final result text (when [done] is true), or null.
  final String? result;

  BackgroundTaskItem copyWith({bool? done, String? result}) {
    return BackgroundTaskItem(
      taskId: taskId,
      prompt: prompt,
      done: done ?? this.done,
      result: result ?? this.result,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BackgroundTaskItem &&
        other.taskId == taskId &&
        other.prompt == prompt &&
        other.done == done &&
        other.result == result;
  }

  @override
  int get hashCode => Object.hash(taskId, prompt, done, result);

  @override
  String toString() {
    return 'BackgroundTaskItem(taskId: $taskId, prompt: $prompt, '
        'done: $done, result: $result)';
  }
}
