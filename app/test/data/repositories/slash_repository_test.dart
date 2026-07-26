// P3-01/02/03 acceptance: SlashRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names from
// docs/reference/08-agent-transparency-wire-shapes.md and the DTO→domain
// mapping for all slash command RPCs.

import 'package:flit/data/repositories/slash_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/command_dispatch.dart';
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
  group('SlashRepositoryImpl.catalog (wire §commands.catalog)', () {
    test('sends commands.catalog with no params and parses pairs', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'pairs': <List<dynamic>>[
            <String>['/model', 'Switch model'],
            <String>['/new', 'New session'],
          ],
          'sub': <String, dynamic>{
            '/plugin': <String>['list', 'add'],
          },
          'canon': <String, String>{'/m': '/model', '/n': '/new'},
          'categories': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Session',
              'pairs': <List<dynamic>>[
                <String>['/new', 'New session'],
              ],
            },
          ],
          'skill_count': 3,
          'warning': '',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final catalog = await repository.catalog();

      expect(client.calls.single.method, 'commands.catalog');
      expect(client.calls.single.params, isEmpty);
      expect(catalog.allCommands.length, 2);
      expect(catalog.allCommands[0].command, '/model');
      expect(catalog.allCommands[0].description, 'Switch model');
      expect(catalog.allCommands[1].command, '/new');
      expect(catalog.canon['/m'], '/model');
      expect(catalog.categories.length, 1);
      expect(catalog.categories[0].name, 'Session');
      expect(catalog.categories[0].commands.length, 1);
      expect(catalog.categories[0].commands[0].category, 'Session');
      expect(catalog.skillCount, 3);
      expect(catalog.warning, '');
    });

    test('handles empty catalog', () async {
      final repository = SlashRepositoryImpl(FakeGatewayRpcClient());

      final catalog = await repository.catalog();

      expect(catalog.allCommands, isEmpty);
      expect(catalog.categories, isEmpty);
      expect(catalog.canon, isEmpty);
      expect(catalog.skillCount, 0);
    });
  });

  group('SlashRepositoryImpl.resolve (wire §command.resolve)', () {
    test('sends command.resolve with {name} and parses result', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'canonical': '/model',
          'description': 'Switch model',
          'category': 'Chat',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final resolution = await repository.resolve('/m');

      expect(client.calls.single.method, 'command.resolve');
      expect(client.calls.single.params, <String, dynamic>{'name': '/m'});
      expect(resolution.canonical, '/model');
      expect(resolution.description, 'Switch model');
      expect(resolution.category, 'Chat');
    });
  });

  group('SlashRepositoryImpl.completeSlash (wire §complete.slash)', () {
    test(
      'sends complete.slash with {text} and parses items+replace_from',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'text': '/model ',
                'display': '/model',
                'meta': 'Switch model',
              },
            ],
            'replace_from': 1,
          },
        );
        final repository = SlashRepositoryImpl(client);

        final result = await repository.completeSlash('/m');

        expect(client.calls.single.method, 'complete.slash');
        expect(client.calls.single.params, <String, dynamic>{'text': '/m'});
        expect(result.items.length, 1);
        expect(result.items[0].text, '/model ');
        expect(result.items[0].display, '/model');
        expect(result.items[0].meta, 'Switch model');
        expect(result.replaceFrom, 1);
      },
    );

    test('handles empty items and missing replace_from', () async {
      final repository = SlashRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.completeSlash('x');

      expect(result.items, isEmpty);
      expect(result.replaceFrom, 0);
    });
  });

  group('SlashRepositoryImpl.completePath (wire §complete.path)', () {
    test('sends complete.path with {word} and parses items', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'text': '@file:foo.txt',
              'display': 'foo.txt',
              'meta': '',
            },
            <String, dynamic>{
              'text': '@folder:bar/',
              'display': 'bar/',
              'meta': 'dir',
            },
          ],
        },
      );
      final repository = SlashRepositoryImpl(client);

      final items = await repository.completePath('@f');

      expect(client.calls.single.method, 'complete.path');
      expect(client.calls.single.params, <String, dynamic>{'word': '@f'});
      expect(items.length, 2);
      expect(items[0].text, '@file:foo.txt');
      expect(items[1].meta, 'dir');
    });
  });

  group('SlashRepositoryImpl.dispatch (wire §command.dispatch)', () {
    test('sends {name, arg, session_id} and parses type=exec', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'exec',
          'output': 'Command executed.',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/test',
        arg: 'foo',
        sessionId: 'abc123',
      );

      expect(client.calls.single.method, 'command.dispatch');
      expect(client.calls.single.params, <String, dynamic>{
        'name': '/test',
        'arg': 'foo',
        'session_id': 'abc123',
      });
      expect(result, isA<DispatchExec>());
      final exec = result as DispatchExec;
      expect(exec.output, 'Command executed.');
      expect(exec.isPlugin, false);
    });

    test('parses type=plugin', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'plugin',
          'output': 'Plugin output.',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/foo',
        arg: '',
        sessionId: 'x',
      );

      expect(result, isA<DispatchExec>());
      final exec = result as DispatchExec;
      expect(exec.output, 'Plugin output.');
      expect(exec.isPlugin, true);
    });

    test('parses type=alias', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'alias',
          'target': '/model',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/m',
        arg: '',
        sessionId: 'x',
      );

      expect(result, isA<DispatchAlias>());
      expect((result as DispatchAlias).target, '/model');
    });

    test('parses type=skill', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'skill',
          'message': 'Skill invoked.',
          'name': 'test-skill',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/skill',
        arg: 'arg',
        sessionId: 'x',
      );

      expect(result, isA<DispatchSkill>());
      final skill = result as DispatchSkill;
      expect(skill.message, 'Skill invoked.');
      expect(skill.name, 'test-skill');
    });

    test('parses type=send', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'send',
          'message': 'Send this',
          'notice': 'System notice',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/send',
        arg: '',
        sessionId: 'x',
      );

      expect(result, isA<DispatchSend>());
      final send = result as DispatchSend;
      expect(send.message, 'Send this');
      expect(send.notice, 'System notice');
    });

    test('parses type=prefill', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'prefill',
          'message': 'Prefill this',
          'notice': 'Notice text',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/prefill',
        arg: '',
        sessionId: 'x',
      );

      expect(result, isA<DispatchPrefill>());
      final prefill = result as DispatchPrefill;
      expect(prefill.message, 'Prefill this');
      expect(prefill.notice, 'Notice text');
    });

    test('parses unknown type defensively', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'type': 'unknown_future_type'},
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.dispatch(
        name: '/x',
        arg: '',
        sessionId: 'x',
      );

      expect(result, isA<DispatchUnknown>());
      expect((result as DispatchUnknown).rawType, 'unknown_future_type');
    });
  });

  group('SlashRepositoryImpl.exec (wire §slash.exec)', () {
    test('sends {command, session_id} and parses plain output', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'output': 'Execution result.',
          'warning': 'Optional warning.',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.exec(
        command: '/test foo',
        sessionId: 'abc123',
      );

      expect(client.calls.single.method, 'slash.exec');
      expect(client.calls.single.params, <String, dynamic>{
        'command': '/test foo',
        'session_id': 'abc123',
      });
      expect(result, isA<SlashExecOutput>());
      final output = result as SlashExecOutput;
      expect(output.output, 'Execution result.');
      expect(output.warning, 'Optional warning.');
    });

    test('parses re-routed dispatch (type field present)', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'type': 'send',
          'message': 'Re-routed message',
        },
      );
      final repository = SlashRepositoryImpl(client);

      final result = await repository.exec(command: '/send', sessionId: 'x');

      expect(result, isA<SlashExecDispatch>());
      final dispatch = (result as SlashExecDispatch).dispatch;
      expect(dispatch, isA<DispatchSend>());
      expect((dispatch as DispatchSend).message, 'Re-routed message');
    });
  });
}
