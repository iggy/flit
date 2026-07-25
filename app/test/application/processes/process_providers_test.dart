// P5-03 acceptance: ProcessActionController never throws on failure, sets
// error state, invalidates list on success, stores exec result.

import 'package:flit/application/processes/process_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/background_process.dart';
import 'package:flit/domain/repositories/process_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only fake process repository.
final class FakeProcessRepository implements ProcessRepository {
  FakeProcessRepository({
    this.listResult = const <BackgroundProcess>[],
    this.killResult = const ProcessKillResult(status: 'killed'),
    this.stopAllResult = 0,
    this.execResult = const ShellExecResult(stdout: '', stderr: '', code: 0),
    this.shouldThrowGatewayException = false,
    this.shouldThrowUnknownException = false,
  });

  final List<BackgroundProcess> listResult;
  final ProcessKillResult killResult;
  final int stopAllResult;
  final ShellExecResult execResult;
  final bool shouldThrowGatewayException;
  final bool shouldThrowUnknownException;

  final List<String> killedProcessIds = <String>[];
  final List<String> execCommands = <String>[];
  int stopAllCallCount = 0;

  @override
  Future<List<BackgroundProcess>> list({String? sessionId}) async {
    return listResult;
  }

  @override
  Future<ProcessKillResult> kill(String processId, {String? sessionId}) async {
    if (shouldThrowGatewayException) {
      throw const GatewayRpcException(-1, 'Gateway error');
    }
    if (shouldThrowUnknownException) {
      throw Exception('Unknown error');
    }
    killedProcessIds.add(processId);
    return killResult;
  }

  @override
  Future<int> stopAll() async {
    if (shouldThrowGatewayException) {
      throw const GatewayRpcException(-1, 'Gateway error');
    }
    if (shouldThrowUnknownException) {
      throw Exception('Unknown error');
    }
    stopAllCallCount++;
    return stopAllResult;
  }

  @override
  Future<ShellExecResult> exec(String command) async {
    if (shouldThrowGatewayException) {
      throw const GatewayRpcException(-1, 'Gateway error');
    }
    if (shouldThrowUnknownException) {
      throw Exception('Unknown error');
    }
    execCommands.add(command);
    return execResult;
  }
}

void main() {
  group('ProcessActionController.kill', () {
    test('calls repository.kill with processId and clears state on success',
        () async {
      final repository = FakeProcessRepository(
        killResult: const ProcessKillResult(
          status: 'killed',
          output: 'Process terminated',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.kill('proc_123');

      expect(repository.killedProcessIds, <String>['proc_123']);
      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, isNull);
    });

    test('sets error when kill result status is error', () async {
      final repository = FakeProcessRepository(
        killResult: const ProcessKillResult(
          status: 'error',
          error: 'Permission denied',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.kill('proc_123');

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Permission denied');
    });

    test('catches GatewayException and sets error, never throws', () async {
      final repository = FakeProcessRepository(
        shouldThrowGatewayException: true,
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.kill('proc_123');

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Gateway error');
    });

    test('catches unknown exception and sets error, never throws', () async {
      final repository = FakeProcessRepository(
        shouldThrowUnknownException: true,
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.kill('proc_123');

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, contains('Exception'));
    });

    test('sets error when repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.kill('proc_123');

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Not connected to a gateway.');
    });

    test('no-op when already busy', () async {
      final repository = FakeProcessRepository();
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
          processActionControllerProvider.overrideWith(
            () => _TestProcessActionController(
              const ProcessActionState(busy: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.kill('proc_123');

      expect(repository.killedProcessIds, isEmpty);
    });
  });

  group('ProcessActionController.stopAll', () {
    test('calls repository.stopAll and clears state on success', () async {
      final repository = FakeProcessRepository(stopAllResult: 5);
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.stopAll();

      expect(repository.stopAllCallCount, 1);
      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, isNull);
    });

    test('catches GatewayException and sets error, never throws', () async {
      final repository = FakeProcessRepository(
        shouldThrowGatewayException: true,
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.stopAll();

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Gateway error');
    });

    test('sets error when repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.stopAll();

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Not connected to a gateway.');
    });
  });

  group('ProcessActionController.exec', () {
    test('calls repository.exec and stores result in state', () async {
      final repository = FakeProcessRepository(
        execResult: const ShellExecResult(
          stdout: 'Hello World',
          stderr: '',
          code: 0,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.exec('echo "Hello World"');

      expect(repository.execCommands, <String>['echo "Hello World"']);
      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, isNull);
      expect(state.lastExecResult, isNotNull);
      expect(state.lastExecResult!.stdout, 'Hello World');
      expect(state.lastExecResult!.stderr, '');
      expect(state.lastExecResult!.code, 0);
    });

    test('stores result with non-zero exit code', () async {
      final repository = FakeProcessRepository(
        execResult: const ShellExecResult(
          stdout: '',
          stderr: 'Command not found',
          code: 127,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.exec('nonexistent');

      final state = container.read(processActionControllerProvider);
      expect(state.lastExecResult!.stderr, 'Command not found');
      expect(state.lastExecResult!.code, 127);
    });

    test('catches GatewayException and sets error, never throws', () async {
      final repository = FakeProcessRepository(
        shouldThrowGatewayException: true,
      );
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.exec('test');

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Gateway error');
      expect(state.lastExecResult, isNull);
    });

    test('sets error when repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [
          processRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);

      await controller.exec('test');

      final state = container.read(processActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Not connected to a gateway.');
    });
  });

  group('ProcessActionController.clearError', () {
    test('clears error while preserving busy and lastExecResult', () async {
      final container = ProviderContainer(
        overrides: [
          processActionControllerProvider.overrideWith(
            () => _TestProcessActionController(
              const ProcessActionState(
                error: 'Some error',
                lastExecResult: ShellExecResult(
                  stdout: 'test',
                  stderr: '',
                  code: 0,
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(processActionControllerProvider.notifier);
      controller.clearError();

      final state = container.read(processActionControllerProvider);
      expect(state.error, isNull);
      expect(state.lastExecResult, isNotNull);
    });
  });
}

/// Test-only controller that allows setting initial state.
class _TestProcessActionController extends ProcessActionController {
  _TestProcessActionController(this.initialState);

  final ProcessActionState initialState;

  @override
  ProcessActionState build() => initialState;
}
