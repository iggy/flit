// P1-14 acceptance: PluginRepositoryImpl against a fake RPC client.
// Asserts the EXACT method name from docs/reference/03-mvp-wire-shapes.md
// §13 and the DTO→domain mapping (missing `version` → '?').

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/data/repositories/plugin_repository.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/plugin_info.dart';

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
  group('PluginRepositoryImpl.list (wire §13)', () {
    test(
      'sends plugins.list with empty params and parses the result',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'plugins': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'kanban',
                'version': '1.0.0',
                'enabled': true,
              },
              <String, dynamic>{'name': 'spotify', 'enabled': false},
            ],
          },
        );
        final repository = PluginRepositoryImpl(client);

        final plugins = await repository.list();

        expect(client.calls.single.method, 'plugins.list');
        expect(client.calls.single.params, isEmpty);
        expect(plugins, <PluginInfo>[
          const PluginInfo(name: 'kanban', version: '1.0.0', enabled: true),
          // Missing version falls back to '?' (§13).
          const PluginInfo(name: 'spotify', version: '?', enabled: false),
        ]);
      },
    );

    test('an absent plugins key yields an empty list', () async {
      final repository = PluginRepositoryImpl(FakeGatewayRpcClient());

      expect(await repository.list(), isEmpty);
    });
  });
}
