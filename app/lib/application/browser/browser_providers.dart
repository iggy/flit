/// Riverpod wiring for browser & preview control (ticket P9-05).
library;

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/browser_repository_impl.dart';
import 'package:flit/domain/models/browser_status.dart';
import 'package:flit/domain/repositories/browser_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The browser repository for the current connection, or null when there is no
/// RPC client (disconnected / pre-connect).
final browserRepositoryProvider = Provider<BrowserRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return BrowserRepositoryImpl(client);
});

/// Refreshable browser connection status (from `browser.manage` action:
/// "status").
final browserStatusProvider =
    AsyncNotifierProvider<BrowserStatusNotifier, BrowserStatus>(
      BrowserStatusNotifier.new,
    );

class BrowserStatusNotifier extends AsyncNotifier<BrowserStatus> {
  @override
  Future<BrowserStatus> build() async {
    final repository = ref.watch(browserRepositoryProvider);
    if (repository == null) {
      return const BrowserStatus(connected: false);
    }
    return repository.status();
  }

  /// Re-fetch the browser status.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(browserRepositoryProvider);
      if (repository == null) {
        return const BrowserStatus(connected: false);
      }
      return repository.status();
    });
  }
}

/// Interaction state for browser actions (connect, disconnect).
final class BrowserActionState {
  const BrowserActionState({
    this.busy = false,
    this.error,
    this.progressLines = const <BrowserProgressLine>[],
  });

  /// An action is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  /// Accumulated `browser.progress` lines from the most recent connect call
  /// that was made WITH a `session_id` (protocol P9-05 quirk: events are ONLY
  /// emitted when a session_id was passed; otherwise lines come back in the
  /// result's `messages` list). Cleared on the next action.
  final List<BrowserProgressLine> progressLines;

  BrowserActionState copyWith({
    bool? busy,
    String? error,
    List<BrowserProgressLine>? progressLines,
  }) {
    return BrowserActionState(
      busy: busy ?? this.busy,
      error: error,
      progressLines: progressLines ?? this.progressLines,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BrowserActionState &&
        other.busy == busy &&
        other.error == error &&
        _listEquals(other.progressLines, progressLines);
  }

  @override
  int get hashCode => Object.hash(busy, error, Object.hashAll(progressLines));

  @override
  String toString() {
    return 'BrowserActionState(busy: $busy, error: $error, '
        'progressLines: $progressLines)';
  }
}

/// Controller for browser actions: connect, disconnect. NEVER throws —
/// failures land in [BrowserActionState.error]. Connect accumulates
/// `browser.progress` events when a session_id is available.
final browserActionControllerProvider =
    NotifierProvider<BrowserActionController, BrowserActionState>(
      BrowserActionController.new,
    );

class BrowserActionController extends Notifier<BrowserActionState> {
  StreamSubscription<BrowserProgressLine>? _progressSub;

  @override
  BrowserActionState build() {
    ref.onDispose(() {
      _progressSub?.cancel();
    });
    return const BrowserActionState();
  }

  /// Connect to CDP. [url] is optional (omit to use the gateway's default).
  /// When an active session exists, progress lines are accumulated from
  /// `browser.progress` events; otherwise they come back in the result's
  /// `messages` list. NEVER throws — failures land in [state.error]. On
  /// success, invalidates the status provider.
  Future<void> connect({String? url}) async {
    if (state.busy) {
      return;
    }
    await _progressSub?.cancel();
    _progressSub = null;

    final repository = ref.read(browserRepositoryProvider);
    if (repository == null) {
      state = const BrowserActionState(error: 'Not connected to a gateway.');
      return;
    }

    final sessionId = ref.read(activeSessionProvider).liveId;
    state = const BrowserActionState(busy: true);

    // Subscribe to browser.progress events when we have a session id
    // (protocol P9-05: events are ONLY emitted when session_id was passed).
    if (sessionId != null) {
      _progressSub = repository
          .progress(sessionId)
          .listen(
            (line) {
              state = state.copyWith(
                progressLines: <BrowserProgressLine>[
                  ...state.progressLines,
                  line,
                ],
              );
            },
            onError: (Object error) {
              // Event stream errors are rare but possible (e.g., parse failure);
              // log but don't stop the action.
            },
          );
    }

    try {
      final result = await repository.connect(url: url, sessionId: sessionId);

      // When no session_id was passed, messages come back in the result
      // instead of as events — accumulate them as pseudo-progress lines.
      final lines = <BrowserProgressLine>[...state.progressLines];
      if (sessionId == null && result.messages.isNotEmpty) {
        for (final msg in result.messages) {
          lines.add(BrowserProgressLine(message: msg, level: 'info'));
        }
      }

      if (result.connected) {
        state = BrowserActionState(progressLines: lines);
        ref.invalidate(browserStatusProvider);
      } else {
        // connected: false is a SUCCESSFUL result, not an error — but it's
        // a failure state we should show.
        state = BrowserActionState(
          error: 'Failed to connect to browser',
          progressLines: lines,
        );
      }
    } on GatewayException catch (error) {
      state = BrowserActionState(error: error.message);
    } on Object catch (error) {
      state = BrowserActionState(error: error.toString());
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
    }
  }

  /// Disconnect from CDP. NEVER throws — failures land in [state.error]. On
  /// success, invalidates the status provider.
  Future<void> disconnect() async {
    if (state.busy) {
      return;
    }
    await _progressSub?.cancel();
    _progressSub = null;

    final repository = ref.read(browserRepositoryProvider);
    if (repository == null) {
      state = const BrowserActionState(error: 'Not connected to a gateway.');
      return;
    }

    state = const BrowserActionState(busy: true);

    try {
      await repository.disconnect();
      state = const BrowserActionState();
      ref.invalidate(browserStatusProvider);
    } on GatewayException catch (error) {
      state = BrowserActionState(error: error.message);
    } on Object catch (error) {
      state = BrowserActionState(error: error.toString());
    }
  }

  void clearError() {
    state = BrowserActionState(
      busy: state.busy,
      progressLines: state.progressLines,
    );
  }
}

/// State for preview.restart tasks: a list of tasks (keyed by task_id), each
/// accumulating progress lines and a final result.
final class PreviewRestartState {
  const PreviewRestartState({
    this.tasks = const <PreviewRestartTask>[],
    this.error,
  });

  /// All preview.restart tasks (keyed by task_id).
  final List<PreviewRestartTask> tasks;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  PreviewRestartState copyWith({
    List<PreviewRestartTask>? tasks,
    String? error,
  }) {
    return PreviewRestartState(tasks: tasks ?? this.tasks, error: error);
  }

  @override
  bool operator ==(Object other) {
    return other is PreviewRestartState &&
        _listEquals(other.tasks, tasks) &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(tasks), error);

  @override
  String toString() {
    return 'PreviewRestartState(tasks: $tasks, error: $error)';
  }
}

/// Controller for preview.restart tasks. NEVER throws — failures land in
/// [PreviewRestartState.error]. Subscribes to `preview.restart.progress` and
/// `.complete` events and accumulates progress lines into tasks keyed by
/// `task_id`.
final previewRestartControllerProvider =
    NotifierProvider<PreviewRestartController, PreviewRestartState>(
      PreviewRestartController.new,
    );

class PreviewRestartController extends Notifier<PreviewRestartState> {
  StreamSubscription<PreviewRestartEvent>? _eventSub;

  @override
  PreviewRestartState build() {
    ref.onDispose(() {
      _eventSub?.cancel();
    });
    return const PreviewRestartState();
  }

  /// Restart a preview URL. Requires an active session. NEVER throws —
  /// failures land in [state.error]. On success, the task_id is added to
  /// [state.tasks] and progress events are subscribed.
  Future<void> restart({
    required String url,
    String? cwd,
    String? context,
  }) async {
    final repository = ref.read(browserRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }

    final sessionId = ref.read(activeSessionProvider).liveId;
    if (sessionId == null) {
      state = state.copyWith(error: 'No active session.');
      return;
    }

    // Subscribe to events for this session if not already subscribed.
    _eventSub ??= repository
        .previewEvents(sessionId)
        .listen(
          _handleEvent,
          onError: (Object error) {
            // Event stream errors are rare but possible (e.g., parse failure).
          },
        );

    try {
      final taskId = await repository.restartPreview(
        sessionId: sessionId,
        url: url,
        cwd: cwd,
        context: context,
      );

      // Add the new task to the list.
      final newTask = PreviewRestartTask(taskId: taskId, url: url);
      state = state.copyWith(
        tasks: <PreviewRestartTask>[...state.tasks, newTask],
      );
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  void _handleEvent(PreviewRestartEvent event) {
    final taskIndex = state.tasks.indexWhere((t) => t.taskId == event.taskId);
    if (taskIndex == -1) {
      // Unknown task_id — don't crash, just ignore.
      return;
    }

    final task = state.tasks[taskIndex];
    final newLine = PreviewRestartLine(text: event.text, level: event.level);
    final updatedTask = task.copyWith(
      lines: <PreviewRestartLine>[...task.lines, newLine],
      done: event.terminal,
      result: event.terminal ? event.text : task.result,
    );

    final updatedTasks = <PreviewRestartTask>[...state.tasks];
    updatedTasks[taskIndex] = updatedTask;

    state = state.copyWith(tasks: updatedTasks);
  }

  void clearError() {
    state = PreviewRestartState(tasks: state.tasks);
  }

  void clearTasks() {
    state = const PreviewRestartState();
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
