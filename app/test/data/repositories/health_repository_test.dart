// P4-06 acceptance: HealthRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params for health diagnostic methods
// (setupStatus, runtimeCheck, verificationStatus).

import 'package:flit/data/repositories/health_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request`. Records every call and answers from [handler].
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

void main() {
  late FakeGatewayRpcClient client;
  late HealthRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = HealthRepositoryImpl(client);
  });

  group('setupStatus (ticket P4-06)', () {
    test('sends setup.status with empty params', () async {
      await repository.setupStatus();

      expect(client.calls.single.method, 'setup.status');
      expect(client.calls.single.params, <String, dynamic>{});
    });

    test('returns true when provider_configured is true', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'provider_configured': true,
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.setupStatus();

      expect(result, isTrue);
    });

    test('returns false when provider_configured is false', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'provider_configured': false,
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.setupStatus();

      expect(result, isFalse);
    });

    test('defaults to false when provider_configured is missing', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{},
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.setupStatus();

      expect(result, isFalse);
    });
  });

  group('runtimeCheck (ticket P4-06)', () {
    test('sends setup.runtime_check with empty params when no provider',
        () async {
      await repository.runtimeCheck();

      expect(client.calls.single.method, 'setup.runtime_check');
      expect(client.calls.single.params, <String, dynamic>{});
    });

    test('includes provider when provided', () async {
      await repository.runtimeCheck(provider: 'anthropic');

      expect(client.calls.single.method, 'setup.runtime_check');
      expect(client.calls.single.params, <String, dynamic>{
        'provider': 'anthropic',
      });
    });

    test('maps all fields to RuntimeCheck domain model', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'provider': 'anthropic',
          'model': 'claude-3-5-sonnet-20250219',
          'source': 'env',
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.runtimeCheck();

      expect(result.ok, isTrue);
      expect(result.provider, 'anthropic');
      expect(result.model, 'claude-3-5-sonnet-20250219');
      expect(result.source, 'env');
      expect(result.error, isNull);
    });

    test('includes error when present', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': false,
          'provider': 'anthropic',
          'model': '',
          'source': 'env',
          'error': 'Invalid API key',
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.runtimeCheck();

      expect(result.ok, isFalse);
      expect(result.error, 'Invalid API key');
    });
  });

  group('verificationStatus (ticket P4-06)', () {
    test('sends verification.status with empty params when no sessionId/cwd',
        () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'verification': <String, dynamic>{
            'status': 'verified',
          },
        },
      );
      repository = HealthRepositoryImpl(client);

      await repository.verificationStatus();

      expect(client.calls.single.method, 'verification.status');
      expect(client.calls.single.params, <String, dynamic>{});
    });

    test('includes session_id when provided', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'verification': <String, dynamic>{
            'status': 'verified',
          },
        },
      );
      repository = HealthRepositoryImpl(client);

      await repository.verificationStatus(sessionId: 'abc123');

      expect(client.calls.single.method, 'verification.status');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'abc123',
      });
    });

    test('includes cwd when provided', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'verification': <String, dynamic>{
            'status': 'verified',
          },
        },
      );
      repository = HealthRepositoryImpl(client);

      await repository.verificationStatus(cwd: '/home/user/project');

      expect(client.calls.single.method, 'verification.status');
      expect(client.calls.single.params, <String, dynamic>{
        'cwd': '/home/user/project',
      });
    });

    test('reads nested verification.status field', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'verification': <String, dynamic>{
            'status': 'verified',
            'evidence': <String, dynamic>{'file': 'CLAUDE.md'},
          },
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.verificationStatus();

      expect(result, 'verified');
    });

    test('defaults to "unknown" when verification field is missing', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{},
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.verificationStatus();

      expect(result, 'unknown');
    });

    test('defaults to "unknown" when status field is missing', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'verification': <String, dynamic>{
            'evidence': <String, dynamic>{'file': 'CLAUDE.md'},
          },
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.verificationStatus();

      expect(result, 'unknown');
    });

    test('defaults to "unknown" when verification is not a map', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'verification': 'not a map',
        },
      );
      repository = HealthRepositoryImpl(client);

      final result = await repository.verificationStatus();

      expect(result, 'unknown');
    });
  });
}
