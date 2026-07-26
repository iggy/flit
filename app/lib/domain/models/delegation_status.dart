/// Domain models for delegation control (ticket P3-05).
///
/// Wire shapes from docs/reference/08-agent-transparency-wire-shapes.md
/// (sections `delegation.status`, `delegation.pause`, `subagent.interrupt`).
library;

/// Result of `delegation.status` (P3-05) — active subagents, spawn limits,
/// and paused state.
final class DelegationStatus {
  const DelegationStatus({
    required this.active,
    required this.paused,
    required this.maxSpawnDepth,
    required this.maxConcurrentChildren,
  });

  /// Active subagents — all currently running or queued subagents.
  final List<ActiveSubagent> active;

  /// Whether delegation is paused (no new spawns).
  final bool paused;

  /// Maximum spawn depth (nesting level limit).
  final int maxSpawnDepth;

  /// Maximum concurrent children per parent.
  final int maxConcurrentChildren;

  @override
  bool operator ==(Object other) {
    return other is DelegationStatus &&
        _listEquals(other.active, active) &&
        other.paused == paused &&
        other.maxSpawnDepth == maxSpawnDepth &&
        other.maxConcurrentChildren == maxConcurrentChildren;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(active),
    paused,
    maxSpawnDepth,
    maxConcurrentChildren,
  );

  @override
  String toString() {
    return 'DelegationStatus(active: $active, paused: $paused, '
        'maxSpawnDepth: $maxSpawnDepth, '
        'maxConcurrentChildren: $maxConcurrentChildren)';
  }
}

/// One active subagent from `delegation.status` (wire §delegation.status).
final class ActiveSubagent {
  const ActiveSubagent({
    required this.id,
    this.parentId,
    required this.depth,
    required this.goal,
    this.model,
    required this.startedAt,
    required this.status,
    required this.toolCount,
    this.lastTool,
  });

  /// Wire `subagent_id`.
  final String id;

  /// Wire `parent_id` — null for root agents.
  final String? parentId;

  /// Wire `depth` — nesting level (0 = root).
  final int depth;

  /// Wire `goal` — task description.
  final String goal;

  /// Wire `model` — model name (e.g. `sonnet`).
  final String? model;

  /// Wire `started_at` — Unix timestamp (seconds).
  final double startedAt;

  /// Wire `status` — lifecycle string (e.g. `running`, `completed`).
  final String status;

  /// Wire `tool_count` — cumulative tool call count.
  final int toolCount;

  /// Wire `last_tool` — most recent tool name (present when known).
  final String? lastTool;

  @override
  bool operator ==(Object other) {
    return other is ActiveSubagent &&
        other.id == id &&
        other.parentId == parentId &&
        other.depth == depth &&
        other.goal == goal &&
        other.model == model &&
        other.startedAt == startedAt &&
        other.status == status &&
        other.toolCount == toolCount &&
        other.lastTool == lastTool;
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    depth,
    goal,
    model,
    startedAt,
    status,
    toolCount,
    lastTool,
  );

  @override
  String toString() {
    return 'ActiveSubagent(id: $id, parentId: $parentId, depth: $depth, '
        'goal: $goal, model: $model, startedAt: $startedAt, '
        'status: $status, toolCount: $toolCount, lastTool: $lastTool)';
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
