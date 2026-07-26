// P4-03/P4-04 acceptance: ToolsRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/data/repositories/tools_repository.dart';
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
  group('ToolsRepositoryImpl.listTools (wire tools.list)', () {
    test('sends tools.list with session_id when provided', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'toolsets': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'filesystem',
              'description': 'File operations',
              'tool_count': 5,
              'enabled': true,
              'tools': <String>['read', 'write', 'list'],
            },
          ],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      final toolsets = await repository.listTools(sessionId: 'sess_abc');

      expect(client.calls.single.method, 'tools.list');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
      });
      expect(toolsets.length, 1);
      expect(toolsets[0].name, 'filesystem');
      expect(toolsets[0].description, 'File operations');
      expect(toolsets[0].toolCount, 5);
      expect(toolsets[0].enabled, true);
      expect(toolsets[0].tools, <String>['read', 'write', 'list']);
    });

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'toolsets': <Map<String, dynamic>>[],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      await repository.listTools();

      expect(client.calls.single.params, isEmpty);
    });

    test('absent toolsets key yields empty list', () async {
      final repository = ToolsRepositoryImpl(FakeGatewayRpcClient());

      final toolsets = await repository.listTools();

      expect(toolsets, isEmpty);
    });
  });

  group('ToolsRepositoryImpl.listToolsets (wire toolsets.list)', () {
    test('sends toolsets.list with session_id when provided', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'toolsets': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'web',
              'description': 'Web tools',
              'tool_count': 3,
              'enabled': false,
            },
          ],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      final toolsets = await repository.listToolsets(sessionId: 'sess_xyz');

      expect(client.calls.single.method, 'toolsets.list');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_xyz',
      });
      expect(toolsets.length, 1);
      expect(toolsets[0].name, 'web');
      expect(toolsets[0].tools, isEmpty);
    });

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'toolsets': <Map<String, dynamic>>[],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      await repository.listToolsets();

      expect(client.calls.single.params, isEmpty);
    });
  });

  group('ToolsRepositoryImpl.showTools (wire tools.show)', () {
    test(
      'sends tools.show with session_id when provided and parses sections',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'sections': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'Core Tools',
                'tools': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'name': 'read',
                    'description': 'Read a file',
                  },
                  <String, dynamic>{
                    'name': 'write',
                    'description': 'Write a file',
                  },
                ],
              },
            ],
            'total': 2,
          },
        );
        final repository = ToolsRepositoryImpl(client);

        final show = await repository.showTools(sessionId: 'sess_abc');

        expect(client.calls.single.method, 'tools.show');
        expect(client.calls.single.params, <String, dynamic>{
          'session_id': 'sess_abc',
        });
        expect(show.sections.length, 1);
        expect(show.sections[0].name, 'Core Tools');
        expect(show.sections[0].tools.length, 2);
        expect(show.sections[0].tools[0].name, 'read');
        expect(show.sections[0].tools[0].description, 'Read a file');
        expect(show.sections[0].tools[1].name, 'write');
        expect(show.total, 2);
      },
    );

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'sections': <Map<String, dynamic>>[],
          'total': 0,
        },
      );
      final repository = ToolsRepositoryImpl(client);

      await repository.showTools();

      expect(client.calls.single.params, isEmpty);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = ToolsRepositoryImpl(FakeGatewayRpcClient());

      final show = await repository.showTools();

      expect(show.sections, isEmpty);
      expect(show.total, 0);
    });
  });

  group('ToolsRepositoryImpl.configure (wire tools.configure)', () {
    test('sends tools.configure with action, names, and session_id', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'changed': <String>['filesystem'],
          'enabled_toolsets': <String>['filesystem', 'web'],
          'missing_servers': <String>[],
          'reset': false,
          'unknown': <String>[],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      final result = await repository.configure(
        action: 'enable',
        names: <String>['filesystem'],
        sessionId: 'sess_abc',
      );

      expect(client.calls.single.method, 'tools.configure');
      expect(client.calls.single.params, <String, dynamic>{
        'action': 'enable',
        'names': <String>['filesystem'],
        'session_id': 'sess_abc',
      });
      expect(result.changed, <String>['filesystem']);
      expect(result.enabledToolsets, <String>['filesystem', 'web']);
      expect(result.missingServers, isEmpty);
      expect(result.reset, false);
      expect(result.unknown, isEmpty);
    });

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'changed': <String>[],
          'enabled_toolsets': <String>[],
          'missing_servers': <String>[],
          'reset': false,
          'unknown': <String>[],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      await repository.configure(action: 'disable', names: <String>['web']);

      expect(client.calls.single.params, <String, dynamic>{
        'action': 'disable',
        'names': <String>['web'],
      });
    });

    test('parses missing_servers warning', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'changed': <String>[],
          'enabled_toolsets': <String>[],
          'missing_servers': <String>['mcp:filesystem'],
          'reset': false,
          'unknown': <String>[],
        },
      );
      final repository = ToolsRepositoryImpl(client);

      final result = await repository.configure(
        action: 'enable',
        names: <String>['filesystem'],
      );

      expect(result.missingServers, <String>['mcp:filesystem']);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = ToolsRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.configure(
        action: 'enable',
        names: <String>['test'],
      );

      expect(result.changed, isEmpty);
      expect(result.enabledToolsets, isEmpty);
      expect(result.missingServers, isEmpty);
      expect(result.reset, false);
      expect(result.unknown, isEmpty);
    });
  });
}
