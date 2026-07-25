/// Riverpod wiring for process control (ticket P5-03).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/process_repository.dart';
import 'package:flit/domain/models/background_process.dart';
import 'package:flit/domain/repositories/process_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The process repository for the current connection, or null when there is no
/// RPC client (disconnected / pre-connect).
final processRepositoryProvider = Provider<ProcessRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ProcessRepositoryImpl(client);
});

/// Refreshable list of background processes (from `process.list`).
final processListProvider =
    AsyncNotifierProvider<ProcessListNotifier, List<BackgroundProcess>>(
      ProcessListNotifier.new,
    );

class ProcessListNotifier extends AsyncNotifier<List<BackgroundProcess>> {
  @override
  Future<List<BackgroundProcess>> build() async {
    final repository = ref.watch(processRepositoryProvider);
    if (repository == null) {
      return const <BackgroundProcess>[];
    }
    final sessionId = ref.watch(activeSessionProvider).liveId;
    return repository.list(sessionId: sessionId);
  }

  /// Re-fetch the process list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(processRepositoryProvider);
      if (repository == null) {
        return const <BackgroundProcess>[];
      }
      final sessionId = ref.read(activeSessionProvider).liveId;
      return repository.list(sessionId: sessionId);
    });
  }
}

/// Interaction state for process actions (kill, stopAll, exec).
final class ProcessActionState {
  const ProcessActionState({
    this.busy = false,
    this.error,
    this.lastExecResult,
  });

  /// An action is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  /// The last shell.exec result (so UI can display stdout/stderr/code).
  final ShellExecResult? lastExecResult;

  @override
  bool operator ==(Object other) {
    return other is ProcessActionState &&
        other.busy == busy &&
        other.error == error &&
        other.lastExecResult == lastExecResult;
  }

  @override
  int get hashCode => Object.hash(busy, error, lastExecResult);

  @override
  String toString() {
    return 'ProcessActionState(busy: $busy, error: $error, '
        'lastExecResult: $lastExecResult)';
  }
}

/// Controller for process actions: kill, stopAll, exec.
final processActionControllerProvider =
    NotifierProvider<ProcessActionController, ProcessActionState>(
      ProcessActionController.new,
    );

class ProcessActionController extends Notifier<ProcessActionState> {
  @override
  ProcessActionState build() => const ProcessActionState();

  /// Kill a specific background process. NEVER throws — failures land in
  /// [ProcessActionState.error]. On success, invalidates the process list.
  Future<void> kill(String processId) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(processRepositoryProvider);
    if (repository == null) {
      state = const ProcessActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ProcessActionState(busy: true);
    try {
      final sessionId = ref.read(activeSessionProvider).liveId;
      final result = await repository.kill(processId, sessionId: sessionId);
      if (result.status == 'error') {
        state = ProcessActionState(
          error: result.error ?? 'Failed to kill process',
        );
      } else {
        state = const ProcessActionState();
        ref.invalidate(processListProvider);
      }
    } on GatewayException catch (error) {
      state = ProcessActionState(error: error.message);
    } on Object catch (error) {
      state = ProcessActionState(error: error.toString());
    }
  }

  /// Stop all background processes. NEVER throws — failures land in
  /// [ProcessActionState.error]. On success, invalidates the process list.
  Future<void> stopAll() async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(processRepositoryProvider);
    if (repository == null) {
      state = const ProcessActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ProcessActionState(busy: true);
    try {
      await repository.stopAll();
      state = const ProcessActionState();
      ref.invalidate(processListProvider);
    } on GatewayException catch (error) {
      state = ProcessActionState(error: error.message);
    } on Object catch (error) {
      state = ProcessActionState(error: error.toString());
    }
  }

  /// Execute a shell command. NEVER throws — failures land in
  /// [ProcessActionState.error]. Stores the result in state for UI display.
  Future<void> exec(String command) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(processRepositoryProvider);
    if (repository == null) {
      state = const ProcessActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ProcessActionState(busy: true);
    try {
      final result = await repository.exec(command);
      state = ProcessActionState(lastExecResult: result);
    } on GatewayException catch (error) {
      state = ProcessActionState(error: error.message);
    } on Object catch (error) {
      state = ProcessActionState(error: error.toString());
    }
  }

  void clearError() {
    state = ProcessActionState(
      busy: state.busy,
      lastExecResult: state.lastExecResult,
    );
  }
}
