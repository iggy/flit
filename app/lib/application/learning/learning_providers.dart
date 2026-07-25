/// Riverpod wiring for learning journey (tickets P6-01, P6-02): the
/// repository provider, the refreshable `learning.frames` fetch, and the
/// controller for mutation operations (edit/delete).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/learning_repository_impl.dart';
import 'package:flit/domain/models/learning_journey.dart';
import 'package:flit/domain/repositories/learning_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The learning repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect) — mirroring the nullable
/// repository provider pattern. Callers must handle null (the UI only
/// offers learning actions while connected).
final learningRepositoryProvider = Provider<LearningRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return LearningRepositoryImpl(client);
});

/// `learning.frames` for the journey screen (wire shape). Re-fetches on client
/// swap (reconnect); refresh after a change with
/// `ref.invalidate(learningJourneyProvider)` — [LearningController] does this
/// automatically after mutations.
final learningJourneyProvider = FutureProvider<LearningJourney>((ref) async {
  final repository = ref.watch(learningRepositoryProvider);
  if (repository == null) {
    // Disconnected: empty journey.
    return const LearningJourney(
      buckets: <LearningBucket>[],
      summary: <String>[],
      legend: <LearningLegend>[],
      categories: <LearningCategory>[],
      axis: (start: '', end: ''),
      count: 0,
    );
  }
  return repository.frames();
});

/// Interaction state for learning mutations (edit/delete).
final class LearningControllerState {
  const LearningControllerState({
    this.busy = false,
    this.error,
  });

  /// A mutating operation is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null. The controller NEVER
  /// throws — failures land here so the UI can show them inline.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is LearningControllerState &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, error);

  @override
  String toString() => 'LearningControllerState(busy: $busy, error: $error)';
}

/// Controller for learning mutations: edit, delete. NEVER throws; failures
/// land in [LearningControllerState.error].
final learningControllerProvider =
    NotifierProvider<LearningController, LearningControllerState>(
      LearningController.new,
    );

class LearningController extends Notifier<LearningControllerState> {
  @override
  LearningControllerState build() => const LearningControllerState();

  Future<void> edit(String id, String content) async {
    await _mutate(() async {
      final repository = ref.read(learningRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      final result = await repository.edit(id, content);
      if (!result.ok) {
        throw Exception(result.message);
      }
    });
  }

  Future<void> delete(String id) async {
    await _mutate(() async {
      final repository = ref.read(learningRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      final result = await repository.delete(id);
      if (!result.ok) {
        throw Exception(result.message);
      }
    });
  }

  void clearError() {
    state = LearningControllerState(busy: state.busy);
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (state.busy) {
      return;
    }
    state = const LearningControllerState(busy: true);
    try {
      await action();
      state = const LearningControllerState();
      ref.invalidate(learningJourneyProvider);
    } on GatewayException catch (error) {
      state = LearningControllerState(error: error.message);
    } on Object catch (error) {
      state = LearningControllerState(error: error.toString());
    }
  }
}
