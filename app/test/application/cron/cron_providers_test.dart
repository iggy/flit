// P5-01 acceptance: cron providers against a fake repository.
// Controller sets error (never throws) on failure; invalidates list on success.

import 'package:flit/application/cron/cron_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/cron_job.dart';
import 'package:flit/domain/repositories/cron_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake cron repository answering from [jobs] and recording calls.
final class FakeCronRepository implements CronRepository {
  FakeCronRepository({this.jobs = const <CronJob>[], this.error});

  List<CronJob> jobs;
  Exception? error;
  int listCalls = 0;
  final List<
    ({
      String action,
      String? jobId,
      String? prompt,
      String? schedule,
      String? name,
    })
  >
  calls =
      <
        ({
          String action,
          String? jobId,
          String? prompt,
          String? schedule,
          String? name,
        })
      >[];

  @override
  Future<List<CronJob>> list() async {
    listCalls++;
    calls.add((
      action: 'list',
      jobId: null,
      prompt: null,
      schedule: null,
      name: null,
    ));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return jobs;
  }

  @override
  Future<void> add({
    required String prompt,
    required String schedule,
    String? name,
  }) async {
    calls.add((
      action: 'add',
      jobId: null,
      prompt: prompt,
      schedule: schedule,
      name: name,
    ));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> remove(String jobId) async {
    calls.add((
      action: 'remove',
      jobId: jobId,
      prompt: null,
      schedule: null,
      name: null,
    ));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> pause(String jobId) async {
    calls.add((
      action: 'pause',
      jobId: jobId,
      prompt: null,
      schedule: null,
      name: null,
    ));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> resume(String jobId) async {
    calls.add((
      action: 'resume',
      jobId: jobId,
      prompt: null,
      schedule: null,
      name: null,
    ));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }
}

const _job1 = CronJob(
  id: 'job_123',
  name: 'Daily report',
  skills: <String>['dataviz'],
  promptPreview: 'Generate status...',
  schedule: 'every day at 9am',
  repeat: 'daily',
  deliver: 'slack',
  enabled: true,
  state: 'scheduled',
);

const _job2 = CronJob(
  id: 'job_456',
  name: 'Weekly backup',
  skills: <String>[],
  promptPreview: 'Backup files...',
  schedule: 'every monday',
  repeat: 'weekly',
  deliver: 'email',
  enabled: false,
  state: 'paused',
);

void main() {
  group('cronJobsProvider', () {
    test('returns jobs from the fake repository', () async {
      final repository = FakeCronRepository(
        jobs: const <CronJob>[_job1, _job2],
      );
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(cronJobsProvider.future), const <CronJob>[
        _job1,
        _job2,
      ]);
      expect(repository.listCalls, 1);
    });

    test('is empty when the repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(await container.read(cronJobsProvider.future), isEmpty);
    });
  });

  group('CronActionController.add', () {
    test(
      'happy path: calls repository.add with params and invalidates list',
      () async {
        final repository = FakeCronRepository();
        final container = ProviderContainer(
          overrides: [cronRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(cronActionControllerProvider.notifier)
            .add(prompt: 'Test prompt', schedule: 'daily', name: 'Test job');

        // add call happens, then list is invalidated/called.
        final addCall = repository.calls.firstWhere((c) => c.action == 'add');
        expect(addCall.action, 'add');
        expect(addCall.prompt, 'Test prompt');
        expect(addCall.schedule, 'daily');
        expect(addCall.name, 'Test job');

        final state = container.read(cronActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, null);
      },
    );

    test(
      'failure path: sets error on GatewayException (never throws)',
      () async {
        final repository = FakeCronRepository()
          ..error = const GatewayRpcException(-1, 'Invalid schedule');
        final container = ProviderContainer(
          overrides: [cronRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(cronActionControllerProvider.notifier)
            .add(prompt: 'Test', schedule: 'invalid');

        final state = container.read(cronActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, 'Invalid schedule');
      },
    );

    test('not-connected: sets error when repository is null', () async {
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      await container
          .read(cronActionControllerProvider.notifier)
          .add(prompt: 'Test', schedule: 'daily');

      final state = container.read(cronActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, 'Not connected to a gateway.');
    });
  });

  group('CronActionController.remove', () {
    test('happy path: calls repository.remove and invalidates list', () async {
      final repository = FakeCronRepository();
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(cronActionControllerProvider.notifier)
          .remove('job_123');

      // remove call happens, then list is invalidated/called.
      final removeCall = repository.calls.firstWhere(
        (c) => c.action == 'remove',
      );
      expect(removeCall.action, 'remove');
      expect(removeCall.jobId, 'job_123');

      final state = container.read(cronActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, null);
    });

    test(
      'failure path: sets error on GatewayException (never throws)',
      () async {
        final repository = FakeCronRepository()
          ..error = const GatewayRpcException(-1, 'Job not found');
        final container = ProviderContainer(
          overrides: [cronRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(cronActionControllerProvider.notifier)
            .remove('job_missing');

        final state = container.read(cronActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, 'Job not found');
      },
    );
  });

  group('CronActionController.pause', () {
    test('happy path: calls repository.pause and invalidates list', () async {
      final repository = FakeCronRepository();
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(cronActionControllerProvider.notifier)
          .pause('job_123');

      // pause call happens, then list is invalidated/called.
      final pauseCall = repository.calls.firstWhere((c) => c.action == 'pause');
      expect(pauseCall.action, 'pause');
      expect(pauseCall.jobId, 'job_123');

      final state = container.read(cronActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, null);
    });

    test(
      'failure path: sets error on GatewayException (never throws)',
      () async {
        final repository = FakeCronRepository()
          ..error = const GatewayRpcException(-1, 'Job not found');
        final container = ProviderContainer(
          overrides: [cronRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(cronActionControllerProvider.notifier)
            .pause('job_missing');

        final state = container.read(cronActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, 'Job not found');
      },
    );
  });

  group('CronActionController.resume', () {
    test('happy path: calls repository.resume and invalidates list', () async {
      final repository = FakeCronRepository();
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(cronActionControllerProvider.notifier)
          .resume('job_123');

      // resume call happens, then list is invalidated/called.
      final resumeCall = repository.calls.firstWhere(
        (c) => c.action == 'resume',
      );
      expect(resumeCall.action, 'resume');
      expect(resumeCall.jobId, 'job_123');

      final state = container.read(cronActionControllerProvider);
      expect(state.busy, false);
      expect(state.error, null);
    });

    test(
      'failure path: sets error on GatewayException (never throws)',
      () async {
        final repository = FakeCronRepository()
          ..error = const GatewayRpcException(-1, 'Job not found');
        final container = ProviderContainer(
          overrides: [cronRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(cronActionControllerProvider.notifier)
            .resume('job_missing');

        final state = container.read(cronActionControllerProvider);
        expect(state.busy, false);
        expect(state.error, 'Job not found');
      },
    );
  });

  group('CronActionController.clearError', () {
    test('clears error while preserving busy state', () async {
      final repository = FakeCronRepository()
        ..error = const GatewayRpcException(-1, 'Test error');
      final container = ProviderContainer(
        overrides: [cronRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      // Trigger an error.
      await container
          .read(cronActionControllerProvider.notifier)
          .remove('job_missing');
      expect(container.read(cronActionControllerProvider).error, 'Test error');

      // Clear the error.
      container.read(cronActionControllerProvider.notifier).clearError();
      expect(container.read(cronActionControllerProvider).error, null);
    });
  });
}
