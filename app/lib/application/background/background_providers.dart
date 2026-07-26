/// Riverpod wiring for background tasks (ticket P5-02).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/background_repository_impl.dart';
import 'package:flit/domain/models/background_task.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/repositories/background_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The background repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final backgroundRepositoryProvider = Provider<BackgroundRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return BackgroundRepositoryImpl(client);
});

/// Interaction state for background tasks: the list of tracked tasks, busy
/// flag (a submit is in flight), and any error.
final class BackgroundTasksState {
  const BackgroundTasksState({
    this.tasks = const <BackgroundTaskItem>[],
    this.busy = false,
    this.error,
  });

  /// All tracked background tasks, in submission order.
  final List<BackgroundTaskItem> tasks;

  /// A submit is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  BackgroundTasksState copyWith({
    List<BackgroundTaskItem>? tasks,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return BackgroundTasksState(
      tasks: tasks ?? this.tasks,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BackgroundTasksState &&
        deepListEquals(other.tasks, tasks) &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(tasks), busy, error);

  @override
  String toString() {
    return 'BackgroundTasksState(tasks: $tasks, busy: $busy, error: $error)';
  }
}

/// Provider for the background tasks controller.
final backgroundTasksProvider =
    NotifierProvider<BackgroundTasksNotifier, BackgroundTasksState>(
      BackgroundTasksNotifier.new,
    );

class BackgroundTasksNotifier extends Notifier<BackgroundTasksState> {
  @override
  BackgroundTasksState build() {
    final repository = ref.watch(backgroundRepositoryProvider);
    if (repository == null) {
      return const BackgroundTasksState();
    }
    final liveId = ref.watch(activeSessionProvider).liveId;
    if (liveId == null) {
      return const BackgroundTasksState();
    }
    // Subscribe to completions.
    final sub = repository.completions(liveId).listen(_onCompletion);
    ref.onDispose(sub.cancel);
    return const BackgroundTasksState();
  }

  void _onCompletion(BackgroundCompletion completion) {
    final tasks = <BackgroundTaskItem>[...state.tasks];
    final index = tasks.indexWhere((item) => item.taskId == completion.taskId);
    if (index >= 0) {
      tasks[index] = tasks[index].copyWith(done: true, result: completion.text);
    } else {
      // Task not found (shouldn't happen), add it as completed.
      tasks.add(
        BackgroundTaskItem(
          taskId: completion.taskId,
          prompt: '',
          done: true,
          result: completion.text,
        ),
      );
    }
    state = state.copyWith(tasks: tasks);
  }

  /// Submit a background prompt. NEVER throws — failures land in
  /// [BackgroundTasksState.error].
  Future<void> submit(String text) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(backgroundRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    final liveId = ref.read(activeSessionProvider).liveId;
    if (liveId == null) {
      state = state.copyWith(error: 'No active session.');
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final taskId = await repository.submit(liveId, text);
      final tasks = <BackgroundTaskItem>[
        ...state.tasks,
        BackgroundTaskItem(taskId: taskId, prompt: text),
      ];
      state = state.copyWith(tasks: tasks, busy: false, clearError: true);
    } on GatewayException catch (error) {
      state = state.copyWith(busy: false, error: error.message);
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
