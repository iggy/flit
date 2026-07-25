/// Riverpod wiring for cron job management (ticket P5-01).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/cron_repository.dart';
import 'package:flit/domain/models/cron_job.dart';
import 'package:flit/domain/repositories/cron_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The cron repository for the current connection, or null when there is no
/// RPC client (disconnected / pre-connect).
final cronRepositoryProvider = Provider<CronRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return CronRepositoryImpl(client);
});

/// Refreshable list of cron jobs (from `cron.manage` action=list).
final cronJobsProvider =
    AsyncNotifierProvider<CronJobsNotifier, List<CronJob>>(
      CronJobsNotifier.new,
    );

class CronJobsNotifier extends AsyncNotifier<List<CronJob>> {
  @override
  Future<List<CronJob>> build() async {
    final repository = ref.watch(cronRepositoryProvider);
    if (repository == null) {
      return const <CronJob>[];
    }
    return repository.list();
  }

  /// Manually refresh the job list (e.g., after an add/remove/pause/resume).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Interaction state for cron actions (add/remove/pause/resume).
final class CronActionState {
  const CronActionState({
    this.busy = false,
    this.error,
  });

  /// An action call is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is CronActionState &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, error);

  @override
  String toString() {
    return 'CronActionState(busy: $busy, error: $error)';
  }
}

/// Controller for cron actions: add/remove/pause/resume.
final cronActionControllerProvider =
    NotifierProvider<CronActionController, CronActionState>(
      CronActionController.new,
    );

class CronActionController extends Notifier<CronActionState> {
  @override
  CronActionState build() => const CronActionState();

  /// Add a new cron job. NEVER throws — failures land in [CronActionState.error].
  Future<void> add({
    required String prompt,
    required String schedule,
    String? name,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(cronRepositoryProvider);
    if (repository == null) {
      state = const CronActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const CronActionState(busy: true);
    try {
      await repository.add(prompt: prompt, schedule: schedule, name: name);
      state = const CronActionState();
      ref.invalidate(cronJobsProvider);
    } on GatewayException catch (error) {
      state = CronActionState(error: error.message);
    } on Object catch (error) {
      state = CronActionState(error: error.toString());
    }
  }

  /// Remove a cron job by id. NEVER throws — failures land in [CronActionState.error].
  Future<void> remove(String jobId) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(cronRepositoryProvider);
    if (repository == null) {
      state = const CronActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const CronActionState(busy: true);
    try {
      await repository.remove(jobId);
      state = const CronActionState();
      ref.invalidate(cronJobsProvider);
    } on GatewayException catch (error) {
      state = CronActionState(error: error.message);
    } on Object catch (error) {
      state = CronActionState(error: error.toString());
    }
  }

  /// Pause a cron job by id. NEVER throws — failures land in [CronActionState.error].
  Future<void> pause(String jobId) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(cronRepositoryProvider);
    if (repository == null) {
      state = const CronActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const CronActionState(busy: true);
    try {
      await repository.pause(jobId);
      state = const CronActionState();
      ref.invalidate(cronJobsProvider);
    } on GatewayException catch (error) {
      state = CronActionState(error: error.message);
    } on Object catch (error) {
      state = CronActionState(error: error.toString());
    }
  }

  /// Resume a paused cron job by id. NEVER throws — failures land in [CronActionState.error].
  Future<void> resume(String jobId) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(cronRepositoryProvider);
    if (repository == null) {
      state = const CronActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const CronActionState(busy: true);
    try {
      await repository.resume(jobId);
      state = const CronActionState();
      ref.invalidate(cronJobsProvider);
    } on GatewayException catch (error) {
      state = CronActionState(error: error.message);
    } on Object catch (error) {
      state = CronActionState(error: error.toString());
    }
  }

  void clearError() {
    state = CronActionState(busy: state.busy);
  }
}
