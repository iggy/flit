/// One tool invocation displayed inside an assistant message
/// (docs/reference/01-gateway-protocol.md §7).
///
/// Clean domain view: wire quirks (polymorphic `result`, snake_case
/// `tool_id`/`duration_s`/`inline_diff`) are absorbed in `data/dto`
/// (05-conventions.md).
library;

/// Lifecycle of a tool call, folded from `tool.start`/`tool.complete`.
enum ToolCallStatus {
  /// `tool.start` seen, no `tool.complete` yet.
  running,

  /// `tool.complete` without an error.
  done,

  /// `tool.complete` carrying an `error` payload field.
  error,
}

/// A single task item from the gateway's tool.todos array.
final class ToolTask {
  const ToolTask({
    required this.id,
    required this.content,
    this.status = ToolTaskStatus.pending,
  });

  /// Unique identifier for this task.
  final String id;

  /// The task content/description.
  final String content;

  /// Current status of this task.
  final ToolTaskStatus status;

  ToolTask copyWith({String? id, String? content, ToolTaskStatus? status}) {
    return ToolTask(
      id: id ?? this.id,
      content: content ?? this.content,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ToolTask &&
        other.id == id &&
        other.content == content &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, content, status);

  @override
  String toString() => 'ToolTask(id: $id, content: $content, status: $status)';
}

/// Status of a task item.
enum ToolTaskStatus { pending, inProgress, completed, cancelled }

/// Display-only model of a tool call (protocol §7: no client reply required).
final class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    this.context,
    this.status = ToolCallStatus.running,
    this.result,
    this.summary,
    this.inlineDiff,
    this.durationS,
    this.tasks = const <ToolTask>[],
  });

  /// Wire `tool_id` — correlates `tool.complete` to `tool.start`.
  final String id;

  /// Tool name, e.g. `shell`.
  final String name;

  /// Human-readable context line, e.g. the shell command (`ls -la`).
  final String? context;

  /// Current lifecycle status.
  final ToolCallStatus status;

  /// Tool result — **polymorphic on the wire** (protocol §7): a parsed
  /// JSON dict/list when the tool output was valid JSON, else a raw string.
  final dynamic result;

  /// Short completion summary, e.g. `1 file`.
  final String? summary;

  /// Unified diff for file-edit tools — render monospace (protocol §7).
  final String? inlineDiff;

  /// Wire `duration_s` — wall time of the tool run in seconds.
  final double? durationS;

  /// Task items from the gateway (tool.todos).
  final List<ToolTask> tasks;

  /// The event fold mutates via copy (ticket P1-01).
  ToolCall copyWith({
    String? id,
    String? name,
    String? context,
    ToolCallStatus? status,
    dynamic result,
    String? summary,
    String? inlineDiff,
    double? durationS,
    List<ToolTask>? tasks,
  }) {
    return ToolCall(
      id: id ?? this.id,
      name: name ?? this.name,
      context: context ?? this.context,
      status: status ?? this.status,
      result: result ?? this.result,
      summary: summary ?? this.summary,
      inlineDiff: inlineDiff ?? this.inlineDiff,
      durationS: durationS ?? this.durationS,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ToolCall &&
        other.id == id &&
        other.name == name &&
        other.context == context &&
        other.status == status &&
        other.result == result &&
        other.summary == summary &&
        other.inlineDiff == inlineDiff &&
        other.durationS == durationS &&
        _tasksEquals(other.tasks, tasks);
  }

  static bool _tasksEquals(List<ToolTask> a, List<ToolTask> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    context,
    status,
    result,
    summary,
    inlineDiff,
    durationS,
    Object.hashAll(tasks),
  );

  @override
  String toString() {
    return 'ToolCall(id: $id, name: $name, context: $context, '
        'status: ${status.name}, result: $result, summary: $summary, '
        'inlineDiff: $inlineDiff, durationS: $durationS, tasks: $tasks)';
  }
}
