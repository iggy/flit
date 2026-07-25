// P5-01 acceptance: CronRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/cron_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call
/// and answers from [handler].
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  final Map<String, dynamic> Function(
    String method,
    Map<String, dynamic> params,
  )?
  handler;

  /// Every (method, params) call, in order.
  final List<({String method, Map<String, dynamic> params})> calls =
      <({String method, Map<String, dynamic> params})>[];

  @override
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const <String, dynamic>{},
  ]) async {
    calls.add((method: method, params: params));
    final answer = handler;
    return answer == null ? const <String, dynamic>{} : answer(method, params);
  }
}

void main() {
  group('CronRepositoryImpl.list (wire cron.manage action=list)', () {
    test('sends cron.manage with action=list and parses jobs', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'count': 2,
          'jobs': <Map<String, dynamic>>[
            <String, dynamic>{
              'job_id': 'job_123',
              'name': 'Daily report',
              'skills': <String>['dataviz'],
              'prompt_preview': 'Generate status...',
              'model': 'claude-3-5-sonnet',
              'provider': 'anthropic',
              'schedule': 'every day at 9am',
              'repeat': 'daily',
              'deliver': 'slack',
              'next_run_at': '2026-07-26T09:00:00Z',
              'last_run_at': '2026-07-25T09:00:00Z',
              'last_status': 'success',
              'last_delivery_error': null,
              'enabled': true,
              'state': 'scheduled',
              'paused_at': null,
              'paused_reason': null,
            },
            <String, dynamic>{
              'job_id': 'job_456',
              'name': 'Weekly backup',
              'skills': <String>[],
              'prompt_preview': 'Backup files...',
              'schedule': 'every monday',
              'repeat': 'weekly',
              'deliver': 'email',
              'enabled': false,
              'state': 'paused',
            },
          ],
        },
      );
      final repository = CronRepositoryImpl(client);

      final jobs = await repository.list();

      expect(client.calls.single.method, 'cron.manage');
      expect(client.calls.single.params, <String, dynamic>{'action': 'list'});
      expect(jobs.length, 2);

      // First job: all fields present.
      expect(jobs[0].id, 'job_123');
      expect(jobs[0].name, 'Daily report');
      expect(jobs[0].skills, <String>['dataviz']);
      expect(jobs[0].promptPreview, 'Generate status...');
      expect(jobs[0].model, 'claude-3-5-sonnet');
      expect(jobs[0].provider, 'anthropic');
      expect(jobs[0].schedule, 'every day at 9am');
      expect(jobs[0].repeat, 'daily');
      expect(jobs[0].deliver, 'slack');
      expect(jobs[0].nextRunAt, '2026-07-26T09:00:00Z');
      expect(jobs[0].lastRunAt, '2026-07-25T09:00:00Z');
      expect(jobs[0].lastStatus, 'success');
      expect(jobs[0].lastDeliveryError, null);
      expect(jobs[0].enabled, true);
      expect(jobs[0].state, 'scheduled');
      expect(jobs[0].pausedAt, null);
      expect(jobs[0].pausedReason, null);
      expect(jobs[0].isPaused, false); // state='scheduled' AND enabled=true

      // Second job: minimal fields, paused.
      expect(jobs[1].id, 'job_456');
      expect(jobs[1].name, 'Weekly backup');
      expect(jobs[1].skills, isEmpty);
      expect(jobs[1].enabled, false);
      expect(jobs[1].state, 'paused');
      expect(jobs[1].isPaused, true); // state='paused' OR enabled=false
    });

    test('throws GatewayRpcException when success=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': false,
          'error': 'Database connection failed',
        },
      );
      final repository = CronRepositoryImpl(client);

      expect(
        repository.list,
        throwsA(
          isA<GatewayRpcException>()
              .having((e) => e.code, 'code', -1)
              .having((e) => e.message, 'message', 'Database connection failed'),
        ),
      );
    });

    test('absent fields fall back to safe defaults', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'jobs': <Map<String, dynamic>>[
            <String, dynamic>{
              // Only required wire fields.
            },
          ],
        },
      );
      final repository = CronRepositoryImpl(client);

      final jobs = await repository.list();

      expect(jobs.length, 1);
      expect(jobs[0].id, ''); // job_id missing → ''
      expect(jobs[0].name, '');
      expect(jobs[0].skills, isEmpty);
      expect(jobs[0].promptPreview, '');
      expect(jobs[0].model, null);
      expect(jobs[0].schedule, '?'); // schedule missing → '?'
      expect(jobs[0].repeat, '');
      expect(jobs[0].deliver, '');
      expect(jobs[0].enabled, false);
      expect(jobs[0].state, '');
    });

    test('isPaused is true when state=paused', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'jobs': <Map<String, dynamic>>[
            <String, dynamic>{
              'job_id': 'job_1',
              'enabled': true,
              'state': 'paused',
            },
          ],
        },
      );
      final repository = CronRepositoryImpl(client);

      final jobs = await repository.list();

      expect(jobs[0].isPaused, true);
    });

    test('isPaused is true when enabled=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'jobs': <Map<String, dynamic>>[
            <String, dynamic>{
              'job_id': 'job_1',
              'enabled': false,
              'state': 'scheduled',
            },
          ],
        },
      );
      final repository = CronRepositoryImpl(client);

      final jobs = await repository.list();

      expect(jobs[0].isPaused, true);
    });
  });

  group('CronRepositoryImpl.add (wire cron.manage action=add)', () {
    test('sends cron.manage with action=add, prompt, schedule, and name',
        () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'job_id': 'job_new',
        },
      );
      final repository = CronRepositoryImpl(client);

      await repository.add(
        prompt: 'Daily summary',
        schedule: 'every day at 5pm',
        name: 'Summary job',
      );

      expect(client.calls.single.method, 'cron.manage');
      expect(client.calls.single.params, <String, dynamic>{
        'action': 'add',
        'prompt': 'Daily summary',
        'schedule': 'every day at 5pm',
        'name': 'Summary job',
      });
    });

    test('omits name when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'job_id': 'job_new',
        },
      );
      final repository = CronRepositoryImpl(client);

      await repository.add(
        prompt: 'Daily summary',
        schedule: 'every day at 5pm',
      );

      expect(client.calls.single.params, <String, dynamic>{
        'action': 'add',
        'prompt': 'Daily summary',
        'schedule': 'every day at 5pm',
      });
    });

    test('throws GatewayRpcException when success=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': false,
          'error': 'Invalid schedule format',
        },
      );
      final repository = CronRepositoryImpl(client);

      expect(
        () => repository.add(
          prompt: 'Test',
          schedule: 'invalid',
        ),
        throwsA(
          isA<GatewayRpcException>()
              .having((e) => e.code, 'code', -1)
              .having((e) => e.message, 'message', 'Invalid schedule format'),
        ),
      );
    });
  });

  group('CronRepositoryImpl.remove (wire cron.manage action=remove)', () {
    test('sends cron.manage with action=remove and name=jobId', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'message': 'Job removed',
          'removed_job': <String, dynamic>{
            'job_id': 'job_123',
            'name': 'Old job',
            'schedule': 'daily',
          },
        },
      );
      final repository = CronRepositoryImpl(client);

      await repository.remove('job_123');

      expect(client.calls.single.method, 'cron.manage');
      expect(client.calls.single.params, <String, dynamic>{
        'action': 'remove',
        'name': 'job_123',
      });
    });

    test('throws GatewayRpcException when success=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': false,
          'error': 'Job not found',
        },
      );
      final repository = CronRepositoryImpl(client);

      expect(
        () => repository.remove('job_missing'),
        throwsA(
          isA<GatewayRpcException>()
              .having((e) => e.code, 'code', -1)
              .having((e) => e.message, 'message', 'Job not found'),
        ),
      );
    });
  });

  group('CronRepositoryImpl.pause (wire cron.manage action=pause)', () {
    test('sends cron.manage with action=pause and name=jobId', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'job': <String, dynamic>{
            'job_id': 'job_123',
            'state': 'paused',
          },
        },
      );
      final repository = CronRepositoryImpl(client);

      await repository.pause('job_123');

      expect(client.calls.single.method, 'cron.manage');
      expect(client.calls.single.params, <String, dynamic>{
        'action': 'pause',
        'name': 'job_123',
      });
    });

    test('throws GatewayRpcException when success=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': false,
          'error': 'Job not found',
        },
      );
      final repository = CronRepositoryImpl(client);

      expect(
        () => repository.pause('job_missing'),
        throwsA(
          isA<GatewayRpcException>()
              .having((e) => e.code, 'code', -1)
              .having((e) => e.message, 'message', 'Job not found'),
        ),
      );
    });
  });

  group('CronRepositoryImpl.resume (wire cron.manage action=resume)', () {
    test('sends cron.manage with action=resume and name=jobId', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': true,
          'job': <String, dynamic>{
            'job_id': 'job_123',
            'state': 'scheduled',
          },
        },
      );
      final repository = CronRepositoryImpl(client);

      await repository.resume('job_123');

      expect(client.calls.single.method, 'cron.manage');
      expect(client.calls.single.params, <String, dynamic>{
        'action': 'resume',
        'name': 'job_123',
      });
    });

    test('throws GatewayRpcException when success=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'success': false,
          'error': 'Job not found',
        },
      );
      final repository = CronRepositoryImpl(client);

      expect(
        () => repository.resume('job_missing'),
        throwsA(
          isA<GatewayRpcException>()
              .having((e) => e.code, 'code', -1)
              .having((e) => e.message, 'message', 'Job not found'),
        ),
      );
    });
  });
}
