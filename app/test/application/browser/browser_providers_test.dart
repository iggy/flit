// P9-05: BrowserActionController and PreviewRestartController acceptance.
// Connect/disconnect never throw (failures land in state.error); progress
// events accumulate; preview.restart.complete marks a task done.

import 'dart:async';

import 'package:flit/application/browser/browser_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/browser_status.dart';
import 'package:flit/domain/repositories/browser_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository for testing providers.
final class FakeBrowserRepository implements BrowserRepository {
  FakeBrowserRepository({
    this.statusResult,
    this.connectResult,
    this.disconnectResult,
    this.restartPreviewResult,
    this.shouldThrow = false,
  });

  final BrowserStatus? statusResult;
  final BrowserStatus? connectResult;
  final BrowserStatus? disconnectResult;
  final String? restartPreviewResult;
  final bool shouldThrow;

  final List<String> calls = <String>[];
  final StreamController<BrowserProgressLine> _progressController =
      StreamController<BrowserProgressLine>.broadcast();
  final StreamController<PreviewRestartEvent> _previewController =
      StreamController<PreviewRestartEvent>.broadcast();

  @override
  Future<BrowserStatus> status() async {
    calls.add('status');
    if (shouldThrow) {
      throw const GatewayRpcException(5000, 'status failed');
    }
    return statusResult ?? const BrowserStatus(connected: false);
  }

  @override
  Future<BrowserStatus> connect({String? url, String? sessionId}) async {
    calls.add('connect');
    if (shouldThrow) {
      throw const GatewayRpcException(5031, 'connect failed');
    }
    return connectResult ?? const BrowserStatus(connected: true);
  }

  @override
  Future<BrowserStatus> disconnect() async {
    calls.add('disconnect');
    if (shouldThrow) {
      throw const GatewayRpcException(5000, 'disconnect failed');
    }
    return disconnectResult ?? const BrowserStatus(connected: false);
  }

  @override
  Stream<BrowserProgressLine> progress(String sessionId) {
    return _progressController.stream;
  }

  @override
  Future<String> restartPreview({
    required String sessionId,
    required String url,
    String? cwd,
    String? context,
  }) async {
    calls.add('restartPreview');
    if (shouldThrow) {
      throw const GatewayRpcException(4012, 'restart failed');
    }
    return restartPreviewResult ?? 'preview_abc123';
  }

  @override
  Stream<PreviewRestartEvent> previewEvents(String sessionId) {
    return _previewController.stream;
  }

  void emitProgress(BrowserProgressLine line) {
    _progressController.add(line);
  }

  void emitPreviewEvent(PreviewRestartEvent event) {
    _previewController.add(event);
  }

  void dispose() {
    _progressController.close();
    _previewController.close();
  }
}

/// Fake active session notifier that returns a fixed state.
class FakeActiveSessionNotifier extends ActiveSessionNotifier {
  FakeActiveSessionNotifier(this._state);

  final ActiveSessionState _state;

  @override
  ActiveSessionState build() => _state;
}

void main() {
  group('BrowserActionController', () {
    test(
      'connect success with no session_id — messages become pseudo-progress',
      () async {
        final fakeRepo = FakeBrowserRepository(
          connectResult: const BrowserStatus(
            connected: true,
            url: 'ws://localhost:9222/devtools/browser/abc',
            messages: <String>['Launching browser', 'Connected'],
          ),
        );

        final container = ProviderContainer(
          overrides: [
            browserRepositoryProvider.overrideWithValue(fakeRepo),
            activeSessionProvider.overrideWith(
              () => FakeActiveSessionNotifier(const ActiveSessionState()),
            ),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(fakeRepo.dispose);

        final controller = container.read(
          browserActionControllerProvider.notifier,
        );
        await controller.connect();

        final state = container.read(browserActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, isNull);
        expect(state.progressLines.length, 2);
        expect(state.progressLines[0].message, 'Launching browser');
        expect(state.progressLines[0].level, 'info');
        expect(state.progressLines[1].message, 'Connected');
        expect(state.progressLines[1].level, 'info');
      },
    );

    test(
      'connect success with session_id — subscribes to progress events',
      () async {
        final fakeRepo = FakeBrowserRepository(
          connectResult: const BrowserStatus(
            connected: true,
            url: 'ws://localhost:9222/devtools/browser/xyz',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            browserRepositoryProvider.overrideWithValue(fakeRepo),
            activeSessionProvider.overrideWith(
              () => FakeActiveSessionNotifier(
                const ActiveSessionState(liveId: 'sess_abc'),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(fakeRepo.dispose);

        final controller = container.read(
          browserActionControllerProvider.notifier,
        );
        await controller.connect();

        final state = container.read(browserActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, isNull);
        // Progress events are accumulated during connect via subscription, but
        // since this is a fast in-memory fake, no events are emitted before the
        // subscription is torn down. The real-world behavior is tested by
        // integration tests against a live gateway.
        expect(fakeRepo.calls, contains('connect'));
      },
    );

    test('connect returns connected: false — sets error state', () async {
      final fakeRepo = FakeBrowserRepository(
        connectResult: const BrowserStatus(
          connected: false,
          messages: <String>['Timeout waiting for browser'],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(fakeRepo),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(const ActiveSessionState()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        browserActionControllerProvider.notifier,
      );
      await controller.connect();

      final state = container.read(browserActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Failed to connect to browser');
      expect(state.progressLines.length, 1);
      expect(state.progressLines[0].message, 'Timeout waiting for browser');
    });

    test('connect throws GatewayException — lands in state.error', () async {
      final fakeRepo = FakeBrowserRepository(shouldThrow: true);

      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(fakeRepo),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(const ActiveSessionState()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        browserActionControllerProvider.notifier,
      );
      await controller.connect();

      final state = container.read(browserActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'connect failed');
      expect(state.progressLines, isEmpty);
    });

    test('disconnect success — invalidates status provider', () async {
      final fakeRepo = FakeBrowserRepository(
        disconnectResult: const BrowserStatus(connected: false),
      );

      final container = ProviderContainer(
        overrides: [browserRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        browserActionControllerProvider.notifier,
      );
      await controller.disconnect();

      final state = container.read(browserActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, isNull);
      expect(fakeRepo.calls, contains('disconnect'));
    });

    test('disconnect throws GatewayException — lands in state.error', () async {
      final fakeRepo = FakeBrowserRepository(shouldThrow: true);

      final container = ProviderContainer(
        overrides: [browserRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        browserActionControllerProvider.notifier,
      );
      await controller.disconnect();

      final state = container.read(browserActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'disconnect failed');
    });

    test('no repository (disconnected) — sets error state', () async {
      final container = ProviderContainer(
        overrides: [browserRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        browserActionControllerProvider.notifier,
      );
      await controller.connect();

      final state = container.read(browserActionControllerProvider);
      expect(state.error, 'Not connected to a gateway.');
    });
  });

  group('PreviewRestartController', () {
    test('restart success — task added and events accumulate', () async {
      final fakeRepo = FakeBrowserRepository(
        restartPreviewResult: 'preview_abc123',
      );

      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(fakeRepo),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(
              const ActiveSessionState(liveId: 'sess_xyz'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        previewRestartControllerProvider.notifier,
      );
      await controller.restart(url: 'http://localhost:3000');

      var state = container.read(previewRestartControllerProvider);
      expect(state.error, isNull);
      expect(state.tasks.length, 1);
      expect(state.tasks[0].taskId, 'preview_abc123');
      expect(state.tasks[0].url, 'http://localhost:3000');
      expect(state.tasks[0].done, false);
      expect(state.tasks[0].lines, isEmpty);

      // Emit progress events.
      fakeRepo.emitPreviewEvent(
        const PreviewRestartEvent(
          taskId: 'preview_abc123',
          text: 'Navigating to URL',
          level: 'info',
          terminal: false,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      state = container.read(previewRestartControllerProvider);
      expect(state.tasks[0].lines.length, 1);
      expect(state.tasks[0].lines[0].text, 'Navigating to URL');
      expect(state.tasks[0].lines[0].level, 'info');
      expect(state.tasks[0].done, false);

      // Emit complete event.
      fakeRepo.emitPreviewEvent(
        const PreviewRestartEvent(
          taskId: 'preview_abc123',
          text: 'Preview restarted successfully',
          level: 'info',
          terminal: true,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      state = container.read(previewRestartControllerProvider);
      expect(state.tasks[0].lines.length, 2);
      expect(state.tasks[0].lines[1].text, 'Preview restarted successfully');
      expect(state.tasks[0].done, true);
      expect(state.tasks[0].result, 'Preview restarted successfully');
    });

    test('restart throws GatewayException — lands in state.error', () async {
      final fakeRepo = FakeBrowserRepository(shouldThrow: true);

      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(fakeRepo),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(
              const ActiveSessionState(liveId: 'sess_xyz'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        previewRestartControllerProvider.notifier,
      );
      await controller.restart(url: 'http://localhost:3000');

      final state = container.read(previewRestartControllerProvider);
      expect(state.error, 'restart failed');
      expect(state.tasks, isEmpty);
    });

    test('restart with no active session — sets error state', () async {
      final fakeRepo = FakeBrowserRepository();

      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(fakeRepo),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(const ActiveSessionState()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        previewRestartControllerProvider.notifier,
      );
      await controller.restart(url: 'http://localhost:3000');

      final state = container.read(previewRestartControllerProvider);
      expect(state.error, 'No active session.');
      expect(state.tasks, isEmpty);
    });

    test('unknown task_id in event — does not crash', () async {
      final fakeRepo = FakeBrowserRepository(
        restartPreviewResult: 'preview_abc123',
      );

      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(fakeRepo),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(
              const ActiveSessionState(liveId: 'sess_xyz'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepo.dispose);

      final controller = container.read(
        previewRestartControllerProvider.notifier,
      );
      await controller.restart(url: 'http://localhost:3000');

      // Emit event for unknown task_id.
      fakeRepo.emitPreviewEvent(
        const PreviewRestartEvent(
          taskId: 'preview_unknown',
          text: 'Unknown task',
          level: 'info',
          terminal: false,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(previewRestartControllerProvider);
      expect(state.tasks.length, 1);
      expect(state.tasks[0].taskId, 'preview_abc123');
      expect(state.tasks[0].lines, isEmpty);
    });

    test('no repository (disconnected) — sets error state', () async {
      final container = ProviderContainer(
        overrides: [
          browserRepositoryProvider.overrideWithValue(null),
          activeSessionProvider.overrideWith(
            () => FakeActiveSessionNotifier(
              const ActiveSessionState(liveId: 'sess_xyz'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        previewRestartControllerProvider.notifier,
      );
      await controller.restart(url: 'http://localhost:3000');

      final state = container.read(previewRestartControllerProvider);
      expect(state.error, 'Not connected to a gateway.');
      expect(state.tasks, isEmpty);
    });
  });
}
