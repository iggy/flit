// P5-09 acceptance: SkillsRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/data/repositories/skills_repository.dart';
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
  group('SkillsRepositoryImpl.list (P5-09)', () {
    test('sends skills.manage {action:list} and parses the catalog', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'skills': <String, dynamic>{
            'built-in': <String>['loop', 'run', 'simplify'],
            'project': <String>['custom-skill'],
          },
        },
      );
      final repository = SkillsRepositoryImpl(client);

      final catalog = await repository.list();

      expect(client.calls.single.method, 'skills.manage');
      expect(client.calls.single.params, <String, dynamic>{'action': 'list'});
      expect(catalog.groups.length, 2);
      expect(catalog.groups[0].category, 'built-in');
      expect(catalog.groups[0].names, <String>['loop', 'run', 'simplify']);
      expect(catalog.groups[1].category, 'project');
      expect(catalog.groups[1].names, <String>['custom-skill']);
    });

    test('absent skills key yields empty catalog', () async {
      final repository = SkillsRepositoryImpl(FakeGatewayRpcClient());

      final catalog = await repository.list();

      expect(catalog.groups, isEmpty);
    });
  });

  group('SkillsRepositoryImpl.browse (P5-09)', () {
    test(
      'sends skills.manage {action:browse, page, page_size} and parses items',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'loop',
                'description': 'Run recurring tasks',
                'source': 'built-in',
                'trust': 'high',
                'identifier': 'loop-1',
              },
            ],
            'page': 1,
            'total_pages': 3,
            'total': 42,
          },
        );
        final repository = SkillsRepositoryImpl(client);

        final result = await repository.browse(page: 1, pageSize: 20);

        expect(client.calls.single.method, 'skills.manage');
        expect(client.calls.single.params, <String, dynamic>{
          'action': 'browse',
          'page': 1,
          'page_size': 20,
        });
        expect(result.items.length, 1);
        expect(result.items[0].name, 'loop');
        expect(result.items[0].description, 'Run recurring tasks');
        expect(result.items[0].source, 'built-in');
        expect(result.items[0].trust, 'high');
        expect(result.items[0].identifier, 'loop-1');
        expect(result.page, 1);
        expect(result.totalPages, 3);
        expect(result.total, 42);
      },
    );

    test('absent fields fall back to safe defaults', () async {
      final repository = SkillsRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.browse();

      expect(result.items, isEmpty);
      expect(result.page, 1);
      expect(result.totalPages, 0);
      expect(result.total, 0);
    });
  });

  group('SkillsRepositoryImpl.reload (P5-09)', () {
    test('sends skills.reload and parses the result', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'output': 'Reload complete',
          'result': <String, dynamic>{
            'added': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'new-skill',
                'description': 'A new skill',
              },
            ],
            'removed': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'old-skill',
                'description': 'An old skill',
              },
            ],
            'unchanged': <String>['stable-skill'],
            'total': 5,
            'commands': 3,
          },
        },
      );
      final repository = SkillsRepositoryImpl(client);

      final result = await repository.reload();

      expect(client.calls.single.method, 'skills.reload');
      expect(client.calls.single.params, isEmpty);
      expect(result.output, 'Reload complete');
      expect(result.added.length, 1);
      expect(result.added[0].name, 'new-skill');
      expect(result.added[0].description, 'A new skill');
      expect(result.removed.length, 1);
      expect(result.removed[0].name, 'old-skill');
      expect(result.unchanged, <String>['stable-skill']);
      expect(result.total, 5);
      expect(result.commands, 3);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = SkillsRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.reload();

      expect(result.output, '');
      expect(result.added, isEmpty);
      expect(result.removed, isEmpty);
      expect(result.unchanged, isEmpty);
      expect(result.total, 0);
      expect(result.commands, 0);
    });
  });
}
