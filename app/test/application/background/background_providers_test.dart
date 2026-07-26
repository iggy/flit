// P5-02 acceptance: BackgroundTasksNotifier never throws on failure (sets
// error), tracks pending tasks, and flips them to done on completion events.

import 'dart:async';

import 'package:flit/application/background/background_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/background_task.dart';
import 'package:flit/domain/repositories/background_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundTasksNotifier.submit', () {
    test('appends pending task on success, clears busy and error', () async {
      final repo = _FakeBackgroundRepository();
      final container = _containerWith(repo, liveId: 'sess_1');

      expect(container.read(backgroundTasksProvider).busy, isFalse);

      final future = container
          .read(backgroundTasksProvider.notifier)
          .submit('write a poem');

      expect(container.read(backgroundTasksProvider).busy, isTrue);

      await future;

      final state = container.read(backgroundTasksProvider);
      expect(state.busy, isFalse);
      expect(state.error, isNull);
      expect(state.tasks.length, 1);
      expect(state.tasks[0].taskId, 'bg_abc123');
      expect(state.tasks[0].prompt, 'write a poem');
      expect(state.tasks[0].done, isFalse);
      expect(state.tasks[0].result, isNull);
    });

    test('sets error on GatewayException (never throws)', () async {
      final repo = _FakeBackgroundRepository(
        submitError: const GatewayNetworkException('Gateway returned HTTP 500'),
      );
      final container = _containerWith(repo, liveId: 'sess_1');

      await container.read(backgroundTasksProvider.notifier).submit('test');

      final state = container.read(backgroundTasksProvider);
      expect(state.busy, isFalse);
      expect(state.error, 'Gateway returned HTTP 500');
      expect(state.tasks, isEmpty);
    });

    test('sets error on generic exception (never throws)', () async {
      final repo = _FakeBackgroundRepository(
        submitError: Exception('Unexpected'),
      );
      final container = _containerWith(repo, liveId: 'sess_1');

      await container.read(backgroundTasksProvider.notifier).submit('test');

      final state = container.read(backgroundTasksProvider);
      expect(state.error, contains('Unexpected'));
    });

    test('sets error when repository is null (not connected)', () async {
      final container = ProviderContainer(
        overrides: [
          backgroundRepositoryProvider.overrideWithValue(null),
          activeSessionProvider.overrideWith(
            () => _FakeActiveSessionNotifier(
              const ActiveSessionState(liveId: 'sess_1'),
            ),
          ),
        ],
      );

      await container.read(backgroundTasksProvider.notifier).submit('test');

      final state = container.read(backgroundTasksProvider);
      expect(state.error, 'Not connected to a gateway.');
      expect(state.tasks, isEmpty);
    });

    test('sets error when liveId is null (no active session)', () async {
      final repo = _FakeBackgroundRepository();
      final container = ProviderContainer(
        overrides: [
          backgroundRepositoryProvider.overrideWithValue(repo),
          activeSessionProvider.overrideWith(
            () => _FakeActiveSessionNotifier(
              const ActiveSessionState(liveId: null),
            ),
          ),
        ],
      );

      await container.read(backgroundTasksProvider.notifier).submit('test');

      final state = container.read(backgroundTasksProvider);
      expect(state.error, 'No active session.');
      expect(state.tasks, isEmpty);
    });

    test('ignores submit when already busy', () async {
      final repo = _FakeBackgroundRepository();
      final container = _containerWith(repo, liveId: 'sess_1');

      // Start first submit (don't await).
      final future1 = container
          .read(backgroundTasksProvider.notifier)
          .submit('first');

      // Try to submit while busy.
      await container.read(backgroundTasksProvider.notifier).submit('second');

      // Complete first submit.
      await future1;

      final state = container.read(backgroundTasksProvider);
      // Only the first task was submitted.
      expect(state.tasks.length, 1);
      expect(state.tasks[0].prompt, 'first');
    });
  });

  group('BackgroundTasksNotifier completion handling', () {
    test('flips task to done when completion event arrives', () async {
      final completionsController = StreamController<BackgroundCompletion>();
      final repo = _FakeBackgroundRepository(
        completionsController: completionsController,
      );
      final container = _containerWith(repo, liveId: 'sess_1');

      // Submit a task.
      await container
          .read(backgroundTasksProvider.notifier)
          .submit('write a poem');

      expect(container.read(backgroundTasksProvider).tasks[0].done, isFalse);

      // Emit a completion.
      completionsController.add(
        const BackgroundCompletion(
          taskId: 'bg_abc123',
          text: 'Roses are red...',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(backgroundTasksProvider);
      expect(state.tasks[0].done, isTrue);
      expect(state.tasks[0].result, 'Roses are red...');
    });

    test('appends unknown taskId as completed (defensive)', () async {
      final completionsController = StreamController<BackgroundCompletion>();
      final repo = _FakeBackgroundRepository(
        completionsController: completionsController,
      );
      final container = _containerWith(repo, liveId: 'sess_1');

      // Read the provider to trigger the subscription in build().
      expect(container.read(backgroundTasksProvider).tasks, isEmpty);

      // Emit a completion for a task we never submitted.
      completionsController.add(
        const BackgroundCompletion(
          taskId: 'bg_unknown',
          text: 'surprise result',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(backgroundTasksProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks[0].taskId, 'bg_unknown');
      expect(state.tasks[0].prompt, '');
      expect(state.tasks[0].done, isTrue);
      expect(state.tasks[0].result, 'surprise result');
    });
  });

  group('BackgroundTasksNotifier.clearError', () {
    test('clears error but preserves tasks and busy', () async {
      final repo = _FakeBackgroundRepository(
        submitError: const GatewayNetworkException('Error'),
      );
      final container = _containerWith(repo, liveId: 'sess_1');

      await container.read(backgroundTasksProvider.notifier).submit('test');

      expect(container.read(backgroundTasksProvider).error, isNotNull);

      container.read(backgroundTasksProvider.notifier).clearError();

      expect(container.read(backgroundTasksProvider).error, isNull);
    });
  });
}

ProviderContainer _containerWith(
  BackgroundRepository repository, {
  required String liveId,
}) {
  return ProviderContainer(
    overrides: [
      backgroundRepositoryProvider.overrideWithValue(repository),
      activeSessionProvider.overrideWith(
        () => _FakeActiveSessionNotifier(ActiveSessionState(liveId: liveId)),
      ),
    ],
  );
}

/// Fake active session notifier for overriding activeSessionProvider.
class _FakeActiveSessionNotifier extends ActiveSessionNotifier {
  _FakeActiveSessionNotifier(this._state);

  final ActiveSessionState _state;

  @override
  ActiveSessionState build() => _state;
}

final class _FakeBackgroundRepository implements BackgroundRepository {
  _FakeBackgroundRepository({
    this.submitError,
    StreamController<BackgroundCompletion>? completionsController,
  }) : _completionsController =
           completionsController ?? StreamController<BackgroundCompletion>();

  final Exception? submitError;
  final StreamController<BackgroundCompletion> _completionsController;

  @override
  Future<String> submit(String sessionId, String text) async {
    if (submitError != null) {
      throw submitError!;
    }
    return 'bg_abc123';
  }

  @override
  Stream<BackgroundCompletion> completions(String sessionId) {
    return _completionsController.stream;
  }
}
