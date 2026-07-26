/// Riverpod wiring for git rollback / checkpoints (tickets P6-05, P6-06): the
/// repository provider, the refreshable `rollback.list` fetch, and the
/// controller for diff lookup and restore operations.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/rollback_repository_impl.dart';
import 'package:flit/domain/models/rollback.dart';
import 'package:flit/domain/repositories/rollback_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The rollback repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect) — mirroring the nullable
/// [projectsRepositoryProvider] pattern. Callers must handle null (the UI only
/// offers checkpoint actions while connected).
final rollbackRepositoryProvider = Provider<RollbackRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return RollbackRepositoryImpl(client);
});

/// `rollback.list` for the active session. Re-fetches on client swap
/// (reconnect) or session switch; refresh after a restore with
/// `ref.invalidate(checkpointListProvider)` — [RollbackController] does this
/// automatically after a successful full restore.
final checkpointListProvider = FutureProvider<CheckpointList>((ref) async {
  final repository = ref.watch(rollbackRepositoryProvider);
  final liveId = ref.watch(activeSessionProvider).liveId;
  if (repository == null || liveId == null) {
    // Disconnected or no active session: empty disabled state.
    return const CheckpointList(enabled: false, checkpoints: <Checkpoint>[]);
  }
  return repository.list(liveId);
});

/// Interaction state for rollback operations.
final class RollbackControllerState {
  const RollbackControllerState({
    this.busy = false,
    this.error,
    this.lastResult,
  });

  /// A mutating operation (restore) is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null. The controller NEVER
  /// throws — failures land here so the UI can show them inline.
  final String? error;

  /// The most recent restore result, or null. The UI watches this to show
  /// success feedback (full restore summary) or a failure notice (success:false
  /// case). Call [clearResult] after displaying to avoid re-showing on rebuild.
  final RestoreResult? lastResult;

  @override
  bool operator ==(Object other) {
    return other is RollbackControllerState &&
        other.busy == busy &&
        other.error == error &&
        other.lastResult == lastResult;
  }

  @override
  int get hashCode => Object.hash(busy, error, lastResult);

  @override
  String toString() =>
      'RollbackControllerState(busy: $busy, error: $error, lastResult: $lastResult)';
}

/// Controller for rollback operations: loadDiff (read) and restore (mutation).
/// NEVER throws; failures land in [RollbackControllerState.error].
final rollbackControllerProvider =
    NotifierProvider<RollbackController, RollbackControllerState>(
      RollbackController.new,
    );

class RollbackController extends Notifier<RollbackControllerState> {
  @override
  RollbackControllerState build() => const RollbackControllerState();

  /// Load a diff for the given checkpoint hash (read-only; no busy guard).
  /// Returns the diff on success or null on failure (sets [error] instead).
  Future<CheckpointDiff?> loadDiff(String hash) async {
    final repository = ref.read(rollbackRepositoryProvider);
    final liveId = ref.read(activeSessionProvider).liveId;
    if (repository == null) {
      state = RollbackControllerState(
        busy: state.busy,
        error: 'Not connected to a gateway.',
        lastResult: state.lastResult,
      );
      return null;
    }
    if (liveId == null) {
      state = RollbackControllerState(
        busy: state.busy,
        error: 'No active session.',
        lastResult: state.lastResult,
      );
      return null;
    }
    try {
      return await repository.diff(liveId, hash);
    } on GatewayException catch (error) {
      state = RollbackControllerState(
        busy: state.busy,
        error: error.message,
        lastResult: state.lastResult,
      );
      return null;
    } on Object catch (error) {
      state = RollbackControllerState(
        busy: state.busy,
        error: error.toString(),
        lastResult: state.lastResult,
      );
      return null;
    }
  }

  /// Restore to the given checkpoint hash (the destructive mutation).
  ///
  /// When `filePath` is omitted: full restore (rewrites working tree AND drops
  /// chat history since the checkpoint). When provided: file-scoped restore
  /// (no history drop). On success, [lastResult] is populated with the restore
  /// metadata; on failure, [error] is set.
  Future<void> restore(String hash, {String? filePath}) async {
    if (state.busy) {
      return;
    }
    state = RollbackControllerState(busy: true, lastResult: state.lastResult);
    try {
      final repository = ref.read(rollbackRepositoryProvider);
      final liveId = ref.read(activeSessionProvider).liveId;
      if (repository == null) {
        state = const RollbackControllerState(
          error: 'Not connected to a gateway.',
        );
        return;
      }
      if (liveId == null) {
        state = const RollbackControllerState(error: 'No active session.');
        return;
      }
      final result = await repository.restore(liveId, hash, filePath: filePath);
      state = RollbackControllerState(lastResult: result);
      // Invalidate the checkpoint list on success (new checkpoint state).
      if (result.success) {
        ref.invalidate(checkpointListProvider);
      }
    } on GatewayException catch (error) {
      state = RollbackControllerState(error: error.message);
    } on Object catch (error) {
      state = RollbackControllerState(error: error.toString());
    }
  }

  void clearError() {
    state = RollbackControllerState(
      busy: state.busy,
      lastResult: state.lastResult,
    );
  }

  void clearResult() {
    state = RollbackControllerState(busy: state.busy, error: state.error);
  }
}
