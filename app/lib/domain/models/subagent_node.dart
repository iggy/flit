/// Domain model for a subagent node in the spawn tree (ticket P3-04).
///
/// Wire shapes from docs/reference/08-agent-transparency-wire-shapes.md;
/// snake_case absorbed at the DTO boundary (05-conventions.md).
library;

/// Lifecycle status of a subagent, mapped from the wire `status` field.
enum SubagentStatus {
  /// Agent is queued (wire: `queued`).
  queued,

  /// Agent is running (wire: `running` or unknown/default).
  running,

  /// Agent is thinking (set when a `subagent.thinking` event arrives).
  thinking,

  /// Agent completed successfully (wire: `completed`).
  completed,

  /// Agent encountered an error (wire: `error`).
  error,

  /// Agent failed (wire: `failed`).
  failed,

  /// Agent was interrupted (wire: `interrupted`).
  interrupted,

  /// Agent timed out (wire: `timeout`).
  timeout,
}

/// Map a wire status string to [SubagentStatus]; unknown → running.
SubagentStatus parseSubagentStatus(String? status) {
  return switch (status) {
    'queued' => SubagentStatus.queued,
    'running' => SubagentStatus.running,
    'thinking' => SubagentStatus.thinking,
    'completed' => SubagentStatus.completed,
    'error' => SubagentStatus.error,
    'failed' => SubagentStatus.failed,
    'interrupted' => SubagentStatus.interrupted,
    'timeout' => SubagentStatus.timeout,
    _ => SubagentStatus.running,
  };
}

/// One node in the subagent spawn tree (P3-04), keyed by [id] and linked to
/// its parent via [parentId].
///
/// Immutable; the spawn-tree fold mutates via [copyWith].
final class SubagentNode {
  const SubagentNode({
    required this.id,
    this.parentId,
    this.depth = 0,
    required this.goal,
    this.model,
    this.status = SubagentStatus.running,
    this.lastActivity,
    this.lastToolName,
    this.toolCount = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.reasoningTokens = 0,
    this.apiCalls = 0,
    this.filesRead = const <String>[],
    this.filesWritten = const <String>[],
    this.summary,
    this.durationSeconds,
    this.costUsd,
  });

  /// Wire `subagent_id` — the primary key.
  final String id;

  /// Wire `parent_id` — links this node to its parent in the tree (null for
  /// root agents).
  final String? parentId;

  /// Wire `depth` — nesting level (0 = root).
  final int depth;

  /// Wire `goal` — the subagent's task description.
  final String goal;

  /// Wire `model` — the model name (e.g. `sonnet`).
  final String? model;

  /// Current lifecycle status.
  final SubagentStatus status;

  /// The latest activity line for a live status indicator: the most recent
  /// `text` / `tool_preview` / progress summary.
  final String? lastActivity;

  /// The most recent tool name (from `subagent.tool`).
  final String? lastToolName;

  /// Wire `tool_count` — cumulative count of tool calls.
  final int toolCount;

  /// Wire `input_tokens` — cumulative input token usage.
  final int inputTokens;

  /// Wire `output_tokens` — cumulative output token usage.
  final int outputTokens;

  /// Wire `reasoning_tokens` — cumulative reasoning token usage.
  final int reasoningTokens;

  /// Wire `api_calls` — cumulative API call count.
  final int apiCalls;

  /// Wire `files_read` — list of file paths read by the agent.
  final List<String> filesRead;

  /// Wire `files_written` — list of file paths written by the agent.
  final List<String> filesWritten;

  /// Wire `summary` — final summary line (on `subagent.complete`).
  final String? summary;

  /// Wire `duration_seconds` — total wall time (on `subagent.complete`).
  final double? durationSeconds;

  /// Wire `cost_usd` — total cost in USD (on `subagent.complete`).
  final double? costUsd;

  SubagentNode copyWith({
    String? id,
    String? parentId,
    int? depth,
    String? goal,
    String? model,
    SubagentStatus? status,
    String? lastActivity,
    String? lastToolName,
    int? toolCount,
    int? inputTokens,
    int? outputTokens,
    int? reasoningTokens,
    int? apiCalls,
    List<String>? filesRead,
    List<String>? filesWritten,
    String? summary,
    double? durationSeconds,
    double? costUsd,
  }) {
    return SubagentNode(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      depth: depth ?? this.depth,
      goal: goal ?? this.goal,
      model: model ?? this.model,
      status: status ?? this.status,
      lastActivity: lastActivity ?? this.lastActivity,
      lastToolName: lastToolName ?? this.lastToolName,
      toolCount: toolCount ?? this.toolCount,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      reasoningTokens: reasoningTokens ?? this.reasoningTokens,
      apiCalls: apiCalls ?? this.apiCalls,
      filesRead: filesRead ?? this.filesRead,
      filesWritten: filesWritten ?? this.filesWritten,
      summary: summary ?? this.summary,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      costUsd: costUsd ?? this.costUsd,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SubagentNode &&
        other.id == id &&
        other.parentId == parentId &&
        other.depth == depth &&
        other.goal == goal &&
        other.model == model &&
        other.status == status &&
        other.lastActivity == lastActivity &&
        other.lastToolName == lastToolName &&
        other.toolCount == toolCount &&
        other.inputTokens == inputTokens &&
        other.outputTokens == outputTokens &&
        other.reasoningTokens == reasoningTokens &&
        other.apiCalls == apiCalls &&
        _listEquals(other.filesRead, filesRead) &&
        _listEquals(other.filesWritten, filesWritten) &&
        other.summary == summary &&
        other.durationSeconds == durationSeconds &&
        other.costUsd == costUsd;
  }

  @override
  int get hashCode => Object.hash(
        id,
        parentId,
        depth,
        goal,
        model,
        status,
        lastActivity,
        lastToolName,
        toolCount,
        inputTokens,
        outputTokens,
        reasoningTokens,
        apiCalls,
        Object.hashAll(filesRead),
        Object.hashAll(filesWritten),
        summary,
        durationSeconds,
        costUsd,
      );

  @override
  String toString() {
    return 'SubagentNode(id: $id, parentId: $parentId, depth: $depth, '
        'goal: $goal, model: $model, status: ${status.name}, '
        'lastActivity: $lastActivity, lastToolName: $lastToolName, '
        'toolCount: $toolCount, inputTokens: $inputTokens, '
        'outputTokens: $outputTokens, reasoningTokens: $reasoningTokens, '
        'apiCalls: $apiCalls, filesRead: $filesRead, '
        'filesWritten: $filesWritten, summary: $summary, '
        'durationSeconds: $durationSeconds, costUsd: $costUsd)';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
