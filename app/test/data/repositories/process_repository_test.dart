// P5-03 acceptance: ProcessRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/data/repositories/process_repository.dart';
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
  group('ProcessRepositoryImpl.list (wire process.list)', () {
    test('sends process.list with session_id when provided', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'processes': <Map<String, dynamic>>[
            <String, dynamic>{
              'session_id': 'proc_123',
              'command': 'npm run dev',
              'cwd': '/app',
              'pid': 1234,
              'started_at': '2026-07-25T10:00:00Z',
              'uptime_seconds': 3600,
              'status': 'running',
              'output_tail': 'Server running on port 3000',
              'output_preview': 'Server running...',
            },
          ],
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final processes = await repository.list(sessionId: 'sess_abc');

      expect(client.calls.single.method, 'process.list');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
      });
      expect(processes.length, 1);
      expect(processes[0].processId, 'proc_123');
      expect(processes[0].command, 'npm run dev');
      expect(processes[0].cwd, '/app');
      expect(processes[0].pid, 1234);
      expect(processes[0].startedAt, '2026-07-25T10:00:00Z');
      expect(processes[0].uptimeSeconds, 3600);
      expect(processes[0].status, 'running');
      expect(processes[0].outputTail, 'Server running on port 3000');
      expect(processes[0].outputPreview, 'Server running...');
    });

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'processes': <Map<String, dynamic>>[],
        },
      );
      final repository = ProcessRepositoryImpl(client);

      await repository.list();

      expect(client.calls.single.params, isEmpty);
    });

    test('absent processes key yields empty list', () async {
      final repository = ProcessRepositoryImpl(FakeGatewayRpcClient());

      final processes = await repository.list();

      expect(processes, isEmpty);
    });

    test('parse defensively: missing fields become null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'processes': <Map<String, dynamic>>[
            <String, dynamic>{
              'session_id': 'proc_456',
              'status': 'exited',
              'exit_code': 1,
            },
          ],
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final processes = await repository.list();

      expect(processes.length, 1);
      expect(processes[0].processId, 'proc_456');
      expect(processes[0].command, isNull);
      expect(processes[0].cwd, isNull);
      expect(processes[0].pid, isNull);
      expect(processes[0].status, 'exited');
      expect(processes[0].exitCode, 1);
    });
  });

  group('ProcessRepositoryImpl.kill (wire process.kill)', () {
    test('sends process.kill with process_id and session_id', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'killed',
          'output': 'Process terminated',
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.kill('proc_123', sessionId: 'sess_abc');

      expect(client.calls.single.method, 'process.kill');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'process_id': 'proc_123',
      });
      expect(result.status, 'killed');
      expect(result.output, 'Process terminated');
    });

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'not_found'},
      );
      final repository = ProcessRepositoryImpl(client);

      await repository.kill('proc_999');

      expect(client.calls.single.params, <String, dynamic>{
        'process_id': 'proc_999',
      });
    });

    test('parses polymorphic status: killed', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'killed',
          'output': 'Terminated',
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.kill('proc_123');

      expect(result.status, 'killed');
      expect(result.output, 'Terminated');
      expect(result.error, isNull);
    });

    test('parses polymorphic status: already_exited', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'already_exited',
          'output': 'Process already exited',
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.kill('proc_123');

      expect(result.status, 'already_exited');
      expect(result.output, 'Process already exited');
    });

    test('parses polymorphic status: not_found', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'not_found'},
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.kill('proc_999');

      expect(result.status, 'not_found');
    });

    test('parses polymorphic status: error', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'error',
          'error': 'Permission denied',
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.kill('proc_123');

      expect(result.status, 'error');
      expect(result.error, 'Permission denied');
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = ProcessRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.kill('proc_123');

      expect(result.status, 'unknown');
      expect(result.output, isNull);
      expect(result.error, isNull);
    });
  });

  group('ProcessRepositoryImpl.stopAll (wire process.stop)', () {
    test('sends process.stop with no params', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'killed': 3},
      );
      final repository = ProcessRepositoryImpl(client);

      final count = await repository.stopAll();

      expect(client.calls.single.method, 'process.stop');
      expect(client.calls.single.params, isEmpty);
      expect(count, 3);
    });

    test('absent killed field falls back to 0', () async {
      final repository = ProcessRepositoryImpl(FakeGatewayRpcClient());

      final count = await repository.stopAll();

      expect(count, 0);
    });
  });

  group('ProcessRepositoryImpl.exec (wire shell.exec)', () {
    test('sends shell.exec with command param only', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'stdout': 'Hello World',
          'stderr': '',
          'code': 0,
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.exec('echo "Hello World"');

      expect(client.calls.single.method, 'shell.exec');
      expect(client.calls.single.params, <String, dynamic>{
        'command': 'echo "Hello World"',
      });
      expect(result.stdout, 'Hello World');
      expect(result.stderr, '');
      expect(result.code, 0);
    });

    test('parses stdout, stderr, and exit code', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'stdout': 'output line 1\noutput line 2',
          'stderr': 'warning: deprecated',
          'code': 1,
        },
      );
      final repository = ProcessRepositoryImpl(client);

      final result = await repository.exec('npm test');

      expect(result.stdout, 'output line 1\noutput line 2');
      expect(result.stderr, 'warning: deprecated');
      expect(result.code, 1);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = ProcessRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.exec('test');

      expect(result.stdout, '');
      expect(result.stderr, '');
      expect(result.code, 0);
    });
  });
}
