// P6-05/P6-06 acceptance: RollbackRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from the wire shapes documented in
// docs/reference/09-memory-learning-wire-shapes.md, plus DTO→domain mapping.

import 'package:flit/data/repositories/rollback_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call and
/// answers from [handler].
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  /// Answers a request; defaults to an empty result map.
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

/// A representative checkpoint wire dict.
const checkpointWire = <String, dynamic>{
  'hash': 'abc123def456abc123def456abc123def456abcd',
  'timestamp': '2026-07-25T10:30:00+00:00',
  'message': 'Before refactoring',
};

void main() {
  late FakeGatewayRpcClient client;
  late RollbackRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = RollbackRepositoryImpl(client);
  });

  group('list (wire rollback.list)', () {
    test('sends rollback.list with session_id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'enabled': true,
          'checkpoints': <Map<String, dynamic>>[],
        },
      );
      repository = RollbackRepositoryImpl(client);

      await repository.list('session-123');

      expect(client.calls.single.method, 'rollback.list');
      expect(
        client.calls.single.params,
        <String, dynamic>{'session_id': 'session-123'},
      );
    });

    test('maps enabled flag and checkpoints array', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'enabled': true,
          'checkpoints': <Map<String, dynamic>>[
            checkpointWire,
            <String, dynamic>{
              'hash': 'def456abc123def456abc123def456abc123defg',
              'timestamp': '2026-07-25T11:00:00+00:00',
              'message': 'After cleanup',
            },
          ],
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.list('session-123');

      expect(result.enabled, isTrue);
      expect(result.checkpoints, hasLength(2));
      expect(result.checkpoints[0].hash, checkpointWire['hash']);
      expect(result.checkpoints[0].timestamp, checkpointWire['timestamp']);
      expect(result.checkpoints[0].message, checkpointWire['message']);
      expect(result.checkpoints[1].hash, 'def456abc123def456abc123def456abc123defg');
      expect(result.checkpoints[1].message, 'After cleanup');
    });

    test('handles disabled checkpointing (enabled:false, empty list)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'enabled': false,
          'checkpoints': <Map<String, dynamic>>[],
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.list('session-123');

      expect(result.enabled, isFalse);
      expect(result.checkpoints, isEmpty);
    });
  });

  group('diff (wire rollback.diff)', () {
    test('sends rollback.diff with session_id and hash', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'stat': ' 1 file changed, 10 insertions(+), 5 deletions(-)',
          'diff': 'diff --git a/file.dart b/file.dart\n...',
        },
      );
      repository = RollbackRepositoryImpl(client);

      await repository.diff('session-123', 'abc123');

      expect(client.calls.single.method, 'rollback.diff');
      expect(
        client.calls.single.params,
        <String, dynamic>{
          'session_id': 'session-123',
          'hash': 'abc123',
        },
      );
    });

    test('maps stat and diff fields', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'stat': ' 2 files changed, 15 insertions(+), 8 deletions(-)',
          'diff': 'diff --git a/lib/main.dart b/lib/main.dart\nindex abc..def\n--- a/lib/main.dart\n+++ b/lib/main.dart',
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.diff('session-123', 'abc123');

      expect(result.stat, ' 2 files changed, 15 insertions(+), 8 deletions(-)');
      expect(result.diff, startsWith('diff --git a/lib/main.dart'));
    });

    test('defaults to empty strings when stat/diff are null', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'stat': null,
          'diff': null,
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.diff('session-123', 'abc123');

      expect(result.stat, '');
      expect(result.diff, '');
    });
  });

  group('restore (wire rollback.restore)', () {
    test('sends rollback.restore with session_id and hash (no file_path)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'success': true,
          'restored_to': 'abc123de',
          'reason': 'Before refactoring',
          'directory': '/home/user/repo',
          'history_removed': 4,
        },
      );
      repository = RollbackRepositoryImpl(client);

      await repository.restore('session-123', 'abc123');

      expect(client.calls.single.method, 'rollback.restore');
      expect(
        client.calls.single.params,
        <String, dynamic>{
          'session_id': 'session-123',
          'hash': 'abc123',
        },
      );
      // file_path key should NOT be present when null.
      expect(client.calls.single.params.containsKey('file_path'), isFalse);
    });

    test('includes file_path when provided', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'success': true,
          'file': 'lib/main.dart',
        },
      );
      repository = RollbackRepositoryImpl(client);

      await repository.restore('session-123', 'abc123', filePath: 'lib/main.dart');

      expect(client.calls.single.method, 'rollback.restore');
      expect(
        client.calls.single.params,
        <String, dynamic>{
          'session_id': 'session-123',
          'hash': 'abc123',
          'file_path': 'lib/main.dart',
        },
      );
    });

    test('maps full restore result with history_removed', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'success': true,
          'restored_to': 'abc123de',
          'reason': 'Before refactoring',
          'directory': '/home/user/repo',
          'history_removed': 4,
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.restore('session-123', 'abc123');

      expect(result.success, isTrue);
      expect(result.restoredTo, 'abc123de');
      expect(result.reason, 'Before refactoring');
      expect(result.directory, '/home/user/repo');
      expect(result.historyRemoved, 4);
      expect(result.file, isNull);
      expect(result.error, isNull);
    });

    test('maps file-scoped restore result (no history_removed)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'success': true,
          'file': 'lib/main.dart',
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.restore(
        'session-123',
        'abc123',
        filePath: 'lib/main.dart',
      );

      expect(result.success, isTrue);
      expect(result.file, 'lib/main.dart');
      expect(result.historyRemoved, isNull);
    });

    test('maps failure result with error message', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'success': false,
          'error': 'Checkpoint "xyz" not found',
        },
      );
      repository = RollbackRepositoryImpl(client);

      final result = await repository.restore('session-123', 'xyz');

      expect(result.success, isFalse);
      expect(result.error, 'Checkpoint "xyz" not found');
      expect(result.restoredTo, isNull);
      expect(result.historyRemoved, isNull);
    });
  });
}
