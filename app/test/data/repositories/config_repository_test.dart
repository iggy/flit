// P4-02 acceptance: ConfigRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params for the agent settings methods
// (getFast, setFast, getPersonality, setPersonality, getPrompt, setPrompt),
// including the fact that getPrompt reads `result['prompt']` not
// `result['value']`, and setPrompt sends `value:"clear"` when the prompt is
// empty.

import 'package:flit/data/repositories/config_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/repositories/config_repository.dart';
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
  late ConfigRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = ConfigRepositoryImpl(client);
  });

  group('getFast (ticket P4-02)', () {
    test('sends config.get with key:"fast"', () async {
      await repository.getFast();

      expect(client.calls.single.method, 'config.get');
      expect(client.calls.single.params, <String, dynamic>{'key': 'fast'});
    });

    test('returns true when value is "fast"', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'value': 'fast'},
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getFast();

      expect(result, isTrue);
    });

    test('returns false when value is "normal"', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'value': 'normal'},
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getFast();

      expect(result, isFalse);
    });
  });

  group('setFast (ticket P4-02)', () {
    test('sends config.set with value:"fast" when true', () async {
      await repository.setFast(true);

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'fast',
        'value': 'fast',
      });
    });

    test('sends config.set with value:"normal" when false', () async {
      await repository.setFast(false);

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'fast',
        'value': 'normal',
      });
    });
  });

  group('getPersonality (ticket P4-02)', () {
    test('sends config.get with key:"personality"', () async {
      await repository.getPersonality();

      expect(client.calls.single.method, 'config.get');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'personality',
      });
    });

    test('returns the value when present', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'value': 'helpful'},
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getPersonality();

      expect(result, 'helpful');
    });

    test('returns null when value is absent', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{},
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getPersonality();

      expect(result, isNull);
    });
  });

  group('setPersonality (ticket P4-02)', () {
    test('sends config.set with key:"personality" and the value', () async {
      await repository.setPersonality('helpful');

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'personality',
        'value': 'helpful',
      });
    });
  });

  group('getPrompt (ticket P4-02)', () {
    test('sends config.get with key:"prompt"', () async {
      await repository.getPrompt();

      expect(client.calls.single.method, 'config.get');
      expect(client.calls.single.params, <String, dynamic>{'key': 'prompt'});
    });

    test('reads result["prompt"] not result["value"]', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'prompt': 'You are a helpful assistant.',
        },
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getPrompt();

      expect(result, 'You are a helpful assistant.');
    });

    test('returns null when prompt is absent', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{},
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getPrompt();

      expect(result, isNull);
    });
  });

  group('setPrompt (ticket P4-02)', () {
    test('sends config.set with value:"clear" when prompt is empty', () async {
      await repository.setPrompt('');

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'prompt',
        'value': 'clear',
      });
    });

    test('sends config.set with the text when prompt is non-empty', () async {
      await repository.setPrompt('Be concise.');

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'prompt',
        'value': 'Be concise.',
      });
    });
  });

  group('showConfig (ticket P4-06)', () {
    test('sends config.show with empty params', () async {
      await repository.showConfig();

      expect(client.calls.single.method, 'config.show');
      expect(client.calls.single.params, <String, dynamic>{});
    });

    test('maps sections and rows to domain', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'sections': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Agent Settings',
              'rows': <List<dynamic>>[
                <dynamic>['Model', 'sonnet'],
                <dynamic>['Fast', 'true'],
              ],
            },
            <String, dynamic>{
              'title': 'System',
              'rows': <List<dynamic>>[
                <dynamic>['Version', '1.0.0'],
              ],
            },
          ],
        },
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.showConfig();

      expect(result.length, 2);
      expect(result[0].title, 'Agent Settings');
      expect(result[0].rows.length, 2);
      expect(result[0].rows[0].label, 'Model');
      expect(result[0].rows[0].value, 'sonnet');
      expect(result[0].rows[1].label, 'Fast');
      expect(result[0].rows[1].value, 'true');
      expect(result[1].title, 'System');
      expect(result[1].rows.length, 1);
      expect(result[1].rows[0].label, 'Version');
      expect(result[1].rows[0].value, '1.0.0');
    });
  });

  group('getKey (ticket P4-06)', () {
    test('sends config.get with key only when no sessionId', () async {
      await repository.getKey('model');

      expect(client.calls.single.method, 'config.get');
      expect(client.calls.single.params, <String, dynamic>{'key': 'model'});
    });

    test('includes session_id when provided', () async {
      await repository.getKey('model', sessionId: 'abc123');

      expect(client.calls.single.method, 'config.get');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'model',
        'session_id': 'abc123',
      });
    });

    test('returns raw result map', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'value': 'sonnet',
          'info': <String, dynamic>{'source': 'config'},
        },
      );
      repository = ConfigRepositoryImpl(client);

      final result = await repository.getKey('model');

      expect(result, <String, dynamic>{
        'value': 'sonnet',
        'info': <String, dynamic>{'source': 'config'},
      });
    });
  });

  group('setKey (ticket P4-06)', () {
    test('sends config.set with key and value', () async {
      await repository.setKey('model', 'opus');

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'model',
        'value': 'opus',
      });
    });

    test('includes session_id when provided', () async {
      await repository.setKey('model', 'opus', sessionId: 'abc123');

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'model',
        'value': 'opus',
        'session_id': 'abc123',
      });
    });

    test(
      'includes confirm_expensive_model when confirmExpensive is true',
      () async {
        await repository.setKey('model', 'opus', confirmExpensive: true);

        expect(client.calls.single.method, 'config.set');
        expect(client.calls.single.params, <String, dynamic>{
          'key': 'model',
          'value': 'opus',
          'confirm_expensive_model': true,
        });
      },
    );

    test('maps ConfigSetApplied to ConfigKeyApplied with warning', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'value': 'opus',
          'warning': 'API key may need updating',
        },
      );
      repository = ConfigRepositoryImpl(client);

      final outcome = await repository.setKey('model', 'opus');

      expect(outcome, isA<ConfigKeyApplied>());
      final applied = outcome as ConfigKeyApplied;
      expect(applied.value, 'opus');
      expect(applied.warning, 'API key may need updating');
    });

    test('maps ConfigSetApplied to ConfigKeyApplied without warning', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'value': 'sonnet'},
      );
      repository = ConfigRepositoryImpl(client);

      final outcome = await repository.setKey('model', 'sonnet');

      expect(outcome, isA<ConfigKeyApplied>());
      final applied = outcome as ConfigKeyApplied;
      expect(applied.value, 'sonnet');
      expect(applied.warning, isNull);
    });

    test('maps ConfigSetConfirmRequired to ConfigKeyNeedsConfirm', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'confirm_required': true,
          'confirm_message': 'This model costs \$10/Mtok. Continue?',
        },
      );
      repository = ConfigRepositoryImpl(client);

      final outcome = await repository.setKey('model', 'opus');

      expect(outcome, isA<ConfigKeyNeedsConfirm>());
      final confirm = outcome as ConfigKeyNeedsConfirm;
      expect(confirm.message, 'This model costs \$10/Mtok. Continue?');
    });

    test('re-sends with confirmExpensive after confirmation', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'value': 'opus'},
      );
      repository = ConfigRepositoryImpl(client);

      await repository.setKey('model', 'opus', confirmExpensive: true);

      expect(client.calls.single.params['confirm_expensive_model'], true);
    });
  });
}
