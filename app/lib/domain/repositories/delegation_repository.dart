import 'package:flit/domain/models/agent_process.dart';
import 'package:flit/domain/models/delegation_status.dart';
import 'package:flit/domain/models/spawn_tree_snapshot.dart';

/// Intent-level delegation control operations (ticket P3-05).
///
/// Wire shapes from docs/reference/08-agent-transparency-wire-shapes.md.
abstract interface class DelegationRepository {
  /// `delegation.status` (P3-05) — active subagents + spawn limits + paused.
  Future<DelegationStatus> status();

  /// `delegation.pause` (P3-05) — pause (true) / resume (false) spawning.
  /// Returns the new paused state.
  Future<bool> setPaused(bool paused);

  /// `subagent.interrupt` (P3-05) — kill one subagent. Returns whether found.
  Future<bool> interrupt(String subagentId);

  /// `agents.list` (P3-05) — background agent processes.
  Future<List<AgentProcess>> agents();

  /// `spawn_tree.list` (P3-06) — saved spawn-tree snapshots for a session.
  Future<List<SpawnTreeSnapshotEntry>> listSnapshots(
    String sessionId, {
    int limit = 50,
    bool crossSession = false,
  });

  /// `spawn_tree.load` (P3-06) — load a saved snapshot by path.
  Future<SpawnTreeSnapshot> loadSnapshot(String path);

  /// `spawn_tree.save` (P3-06) — save subagents as a snapshot; returns path.
  Future<String> saveSnapshot({
    required String sessionId,
    required List<dynamic> subagents,
    double? startedAt,
    required double finishedAt,
    required String label,
  });
}
