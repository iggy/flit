// P1-11 acceptance: ModelRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from
// docs/reference/03-mvp-wire-shapes.md §8–§9 (esp. the
// `config.set` value string "<model> --provider <slug>" and the
// `confirm_expensive_model:true` re-send), plus the DTO→domain mapping of
// the §8 example.

import 'package:flit/data/repositories/model_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/repositories/model_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake (same pattern as session_repository_test.dart):
/// subclasses [GatewayRpcClient] and overrides ONLY `request` — the single
/// surface the repository uses. Records every call and answers from
/// [handler].
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

/// The verbatim §8 `model.options` result.
const optionsResult = <String, dynamic>{
  'model': 'hermes-4-405b',
  'provider': 'nous',
  'providers': <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Nous Portal',
      'slug': 'nous',
      'authenticated': true,
      'is_current': true,
      'auth_type': 'oauth',
      'key_env': 'NOUS_API_KEY',
      'models': <String>['hermes-4-405b', 'hermes-4-70b'],
      'total_models': 2,
    },
    <String, dynamic>{
      'name': 'OpenRouter',
      'slug': 'openrouter',
      'authenticated': false,
      'key_env': 'OPENROUTER_API_KEY',
      'models': <String>[],
      'warning': 'no key',
    },
  ],
};

void main() {
  late FakeGatewayRpcClient client;
  late ModelRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = ModelRepositoryImpl(client);
  });

  group('options (wire §8)', () {
    test('sends model.options with EMPTY params', () async {
      await repository.options();

      expect(client.calls.single.method, 'model.options');
      expect(client.calls.single.params, isEmpty);
    });

    test('maps the §8 example: current, providers, warning, auth', () async {
      client = FakeGatewayRpcClient(handler: (_, _) => optionsResult);
      repository = ModelRepositoryImpl(client);

      final result = await repository.options();

      expect(result.current.model, 'hermes-4-405b');
      expect(result.current.provider, 'nous');

      expect(result.providers, hasLength(2));
      final nous = result.providers[0];
      expect(nous.name, 'Nous Portal');
      expect(nous.slug, 'nous');
      expect(nous.authenticated, isTrue);
      expect(nous.isCurrent, isTrue);
      expect(nous.authType, 'oauth');
      expect(nous.keyEnv, 'NOUS_API_KEY');
      expect(nous.models, <String>['hermes-4-405b', 'hermes-4-70b']);
      expect(nous.totalModels, 2);
      expect(nous.warning, isNull);

      final openrouter = result.providers[1];
      expect(openrouter.name, 'OpenRouter');
      expect(openrouter.slug, 'openrouter');
      expect(openrouter.authenticated, isFalse);
      expect(openrouter.isCurrent, isFalse);
      expect(openrouter.keyEnv, 'OPENROUTER_API_KEY');
      expect(openrouter.models, isEmpty);
      expect(openrouter.warning, 'no key');
    });
  });

  group('setModel (wire §9)', () {
    test(
      'sends config.set with key:"model" and value "<model> --provider <slug>"',
      () async {
        client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'value': 'hermes-4-70b',
            'info': <String, dynamic>{},
          },
        );
        repository = ModelRepositoryImpl(client);

        final outcome = await repository.setModel(
          model: 'hermes-4-70b',
          providerSlug: 'nous',
        );

        // Setting the model is NOT a model.* RPC (02-rpc-index.md).
        expect(client.calls.single.method, 'config.set');
        expect(client.calls.single.params, <String, dynamic>{
          'key': 'model',
          'value': 'hermes-4-70b --provider nous',
        });
        expect(outcome, const ModelSetApplied(value: 'hermes-4-70b'));
      },
    );

    test('maps confirm_required to ModelSetNeedsConfirm', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'confirm_required': true,
          'confirm_message': 'This model is \$X/Mtok. Continue?',
        },
      );
      repository = ModelRepositoryImpl(client);

      final outcome = await repository.setModel(
        model: 'hermes-4-405b',
        providerSlug: 'nous',
      );

      expect(
        outcome,
        const ModelSetNeedsConfirm(
          message: 'This model is \$X/Mtok. Continue?',
        ),
      );
    });
  });

  group('setModelConfirmed (wire §9 re-send)', () {
    test('re-sends the SAME value plus confirm_expensive_model:true', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'value': 'hermes-4-70b'},
      );
      repository = ModelRepositoryImpl(client);

      final outcome = await repository.setModelConfirmed(
        model: 'hermes-4-70b',
        providerSlug: 'nous',
      );

      expect(client.calls.single.method, 'config.set');
      expect(client.calls.single.params, <String, dynamic>{
        'key': 'model',
        'value': 'hermes-4-70b --provider nous',
        'confirm_expensive_model': true,
      });
      expect(outcome, const ModelSetApplied(value: 'hermes-4-70b'));
    });
  });

  group('saveKey (ticket P4-01)', () {
    test('sends model.save_key with slug and api_key', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'provider': <String, dynamic>{
            'name': 'Nous Portal',
            'slug': 'nous',
            'authenticated': true,
            'is_current': false,
            'auth_type': 'api_key',
            'models': <String>['hermes-4-405b'],
            'total_models': 1,
          },
        },
      );
      repository = ModelRepositoryImpl(client);

      final provider = await repository.saveKey(
        slug: 'nous',
        apiKey: 'test-key-123',
      );

      expect(client.calls.single.method, 'model.save_key');
      expect(client.calls.single.params, <String, dynamic>{
        'slug': 'nous',
        'api_key': 'test-key-123',
      });
      expect(provider.name, 'Nous Portal');
      expect(provider.slug, 'nous');
      expect(provider.authenticated, isTrue);
    });

    test('maps the nested provider object via DTO', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'provider': <String, dynamic>{
            'name': 'OpenRouter',
            'slug': 'openrouter',
            'authenticated': true,
            'is_current': false,
            'auth_type': 'api_key',
            'key_env': 'OPENROUTER_API_KEY',
            'models': <String>['model-a', 'model-b'],
            'total_models': 2,
          },
        },
      );
      repository = ModelRepositoryImpl(client);

      final provider = await repository.saveKey(
        slug: 'openrouter',
        apiKey: 'sk-abc123',
      );

      expect(provider.name, 'OpenRouter');
      expect(provider.slug, 'openrouter');
      expect(provider.authenticated, isTrue);
      expect(provider.keyEnv, 'OPENROUTER_API_KEY');
      expect(provider.models, <String>['model-a', 'model-b']);
      expect(provider.totalModels, 2);
    });
  });

  group('disconnectProvider (ticket P4-01)', () {
    test('sends model.disconnect with slug', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'slug': 'nous',
          'name': 'Nous Portal',
          'disconnected': true,
        },
      );
      repository = ModelRepositoryImpl(client);

      await repository.disconnectProvider(slug: 'nous');

      expect(client.calls.single.method, 'model.disconnect');
      expect(client.calls.single.params, <String, dynamic>{'slug': 'nous'});
    });
  });
}
