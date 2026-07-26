/// Riverpod wiring for delegation control (ticket P3-05).
///
/// Mirrors the nullable-repository pattern of application/plugins/plugin_providers.dart:
/// repositories are null when disconnected, and callers handle null.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/repositories/delegation_repository.dart';
import 'package:flit/domain/models/agent_process.dart';
import 'package:flit/domain/models/delegation_status.dart';
import 'package:flit/domain/models/spawn_tree_snapshot.dart';
import 'package:flit/domain/repositories/delegation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The delegation repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final delegationRepositoryProvider = Provider<DelegationRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return DelegationRepositoryImpl(client);
});

/// Delegation status (active subagents + spawn limits + paused state).
/// Manual refresh via [DelegationStatusNotifier.refresh]; auto-refresh on
/// repository swap (reconnect).
final delegationStatusProvider =
    AsyncNotifierProvider<DelegationStatusNotifier, DelegationStatus?>(
      DelegationStatusNotifier.new,
    );

class DelegationStatusNotifier extends AsyncNotifier<DelegationStatus?> {
  @override
  Future<DelegationStatus?> build() async {
    final repository = ref.watch(delegationRepositoryProvider);
    if (repository == null) {
      return null;
    }
    return repository.status();
  }

  /// Re-fetch the delegation status (manual refresh, e.g. after interrupt).
  Future<void> refresh() async {
    final repository = ref.read(delegationRepositoryProvider);
    if (repository == null) {
      state = const AsyncData(null);
      return;
    }
    state = AsyncData(await repository.status());
  }

  /// Toggle paused state (pause = true, resume = false) and refresh.
  Future<void> setPaused(bool paused) async {
    final repository = ref.read(delegationRepositoryProvider);
    if (repository == null) {
      return;
    }
    await repository.setPaused(paused);
    await refresh();
  }

  /// Interrupt a subagent and refresh.
  Future<bool> interrupt(String subagentId) async {
    final repository = ref.read(delegationRepositoryProvider);
    if (repository == null) {
      return false;
    }
    final found = await repository.interrupt(subagentId);
    await refresh();
    return found;
  }
}

/// Agent processes from `agents.list` — background agent sessions.
/// Empty when disconnected.
final agentProcessesProvider = FutureProvider<List<AgentProcess>>((ref) async {
  final repository = ref.watch(delegationRepositoryProvider);
  if (repository == null) {
    return const <AgentProcess>[];
  }
  return repository.agents();
});

/// Spawn-tree snapshots for a session (from `spawn_tree.list`, P3-06).
/// Empty when disconnected or repository is null.
final snapshotListProvider =
    FutureProvider.family<List<SpawnTreeSnapshotEntry>, String>((
      ref,
      sessionId,
    ) async {
      final repository = ref.watch(delegationRepositoryProvider);
      if (repository == null) {
        return const <SpawnTreeSnapshotEntry>[];
      }
      return repository.listSnapshots(sessionId);
    });

/// A loaded spawn-tree snapshot by path (from `spawn_tree.load`, P3-06).
/// Null when disconnected or repository is null.
final snapshotDetailProvider =
    FutureProvider.family<SpawnTreeSnapshot?, String>((ref, path) async {
      final repository = ref.watch(delegationRepositoryProvider);
      if (repository == null) {
        return null;
      }
      return repository.loadSnapshot(path);
    });
