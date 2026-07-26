// P1-14 acceptance: PluginRepositoryImpl against a fake RPC client.
// Asserts the EXACT method name from docs/reference/03-mvp-wire-shapes.md
// §13 and the DTO→domain mapping (missing `version` → '?').

import 'package:flit/data/repositories/plugin_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/plugin_info.dart';
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

  group('PluginRepositoryImpl.manageList (P5-08)', () {
    test('sends plugins.manage {action:list} and parses the result', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'plugins': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'kanban',
              'version': '1.0.0',
              'description': 'Kanban board plugin',
              'source': 'bundled',
              'status': 'enabled',
            },
            <String, dynamic>{
              'name': 'spotify',
              'version': '0.5.0',
              'description': 'Spotify integration',
              'source': 'user',
              'status': 'disabled',
            },
          ],
          'user_count': 1,
          'bundled_count': 1,
        },
      );
      final repository = PluginRepositoryImpl(client);

      final plugins = await repository.manageList();

      expect(client.calls.single.method, 'plugins.manage');
      expect(client.calls.single.params, <String, dynamic>{'action': 'list'});
      expect(plugins.length, 2);
      expect(plugins[0].name, 'kanban');
      expect(plugins[0].version, '1.0.0');
      expect(plugins[0].description, 'Kanban board plugin');
      expect(plugins[0].source, 'bundled');
      expect(plugins[0].status, 'enabled');
      expect(plugins[0].isEnabled, true);
      expect(plugins[1].name, 'spotify');
      expect(plugins[1].status, 'disabled');
      expect(plugins[1].isEnabled, false);
    });

    test('absent plugins key yields empty list', () async {
      final repository = PluginRepositoryImpl(FakeGatewayRpcClient());

      expect(await repository.manageList(), isEmpty);
    });
  });

  group('PluginRepositoryImpl.toggle (P5-08)', () {
    test(
      'sends plugins.manage {action:toggle, name, enable} and parses result',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'ok': true,
            'unchanged': false,
            'name': 'kanban',
            'plugin': <String, dynamic>{
              'name': 'kanban',
              'version': '1.0.0',
              'description': 'Kanban board',
              'source': 'bundled',
              'status': 'enabled',
            },
          },
        );
        final repository = PluginRepositoryImpl(client);

        final plugin = await repository.toggle('kanban', true);

        expect(client.calls.single.method, 'plugins.manage');
        // Wire field is `enable`, NOT `enabled`.
        expect(client.calls.single.params, <String, dynamic>{
          'action': 'toggle',
          'name': 'kanban',
          'enable': true,
        });
        expect(plugin, isNotNull);
        expect(plugin!.name, 'kanban');
        expect(plugin.status, 'enabled');
        expect(plugin.isEnabled, true);
      },
    );

    test('returns null when plugin is absent', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'unchanged': false,
          'name': 'missing',
        },
      );
      final repository = PluginRepositoryImpl(client);

      final plugin = await repository.toggle('missing', true);

      expect(plugin, isNull);
    });
  });
}
