/// Domain models for spawn-tree snapshots (ticket P3-06).
///
/// Wire shapes from docs/reference/08-agent-transparency-wire-shapes.md
/// §spawn_tree.save, §spawn_tree.list, §spawn_tree.load.
library;

import 'package:flit/domain/models/deep_equals.dart';

/// A saved spawn-tree snapshot entry from `spawn_tree.list`.
final class SpawnTreeSnapshotEntry {
  const SpawnTreeSnapshotEntry({
    required this.path,
    required this.sessionId,
    required this.finishedAt,
    this.startedAt,
    required this.label,
    required this.count,
  });

  /// Wire `path` — the snapshot's storage path (identifier for load).
  final String path;

  /// Wire `session_id` — the session this snapshot belongs to.
  final String sessionId;

  /// Wire `finished_at` — when the snapshot was saved (epoch seconds).
  final double finishedAt;

  /// Wire `started_at` — when the spawn tree began (epoch seconds, optional).
  final double? startedAt;

  /// Wire `label` — a human-readable label for the snapshot.
  final String label;

  /// Wire `count` — the number of subagents in the saved tree.
  final int count;

  @override
  bool operator ==(Object other) {
    return other is SpawnTreeSnapshotEntry &&
        other.path == path &&
        other.sessionId == sessionId &&
        other.finishedAt == finishedAt &&
        other.startedAt == startedAt &&
        other.label == label &&
        other.count == count;
  }

  @override
  int get hashCode =>
      Object.hash(path, sessionId, finishedAt, startedAt, label, count);

  @override
  String toString() {
    return 'SpawnTreeSnapshotEntry(path: $path, sessionId: $sessionId, '
        'finishedAt: $finishedAt, startedAt: $startedAt, '
        'label: $label, count: $count)';
  }
}

/// A loaded spawn-tree snapshot from `spawn_tree.load`.
///
/// The `subagents` list is OPAQUE (TUI-assembled) — it is kept as raw JSON
/// and NOT typed into a domain model. Clients can display it defensively
/// or pass it through to `spawn_tree.save`.
final class SpawnTreeSnapshot {
  const SpawnTreeSnapshot({
    required this.sessionId,
    this.startedAt,
    required this.finishedAt,
    required this.label,
    this.subagents = const <dynamic>[],
  });

  /// Wire `session_id` — the session this snapshot belongs to.
  final String sessionId;

  /// Wire `started_at` — when the spawn tree began (epoch seconds, optional).
  final double? startedAt;

  /// Wire `finished_at` — when the snapshot was saved (epoch seconds).
  final double finishedAt;

  /// Wire `label` — a human-readable label for the snapshot.
  final String label;

  /// Wire `subagents` — OPAQUE TUI-assembled subagent list (kept as raw JSON).
  final List<dynamic> subagents;

  @override
  bool operator ==(Object other) {
    return other is SpawnTreeSnapshot &&
        other.sessionId == sessionId &&
        other.startedAt == startedAt &&
        other.finishedAt == finishedAt &&
        other.label == label &&
        deepListEquals(other.subagents, subagents);
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    startedAt,
    finishedAt,
    label,
    Object.hashAll(subagents),
  );

  @override
  String toString() {
    return 'SpawnTreeSnapshot(sessionId: $sessionId, startedAt: $startedAt, '
        'finishedAt: $finishedAt, label: $label, '
        'subagents: ${subagents.length} items)';
  }
}
