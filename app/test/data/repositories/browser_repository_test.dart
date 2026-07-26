// P9-05 acceptance: BrowserRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/data/repositories/browser_repository_impl.dart';
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
  group(
    'BrowserRepositoryImpl.status (wire browser.manage action: status)',
    () {
      test('sends browser.manage with action=status only', () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'connected': true,
            'url': 'ws://localhost:9222/devtools/browser/abc',
          },
        );
        final repository = BrowserRepositoryImpl(client);

        final status = await repository.status();

        expect(client.calls.single.method, 'browser.manage');
        expect(client.calls.single.params, <String, dynamic>{
          'action': 'status',
        });
        expect(status.connected, true);
        expect(status.url, 'ws://localhost:9222/devtools/browser/abc');
        expect(status.messages, isEmpty);
      });

      test('parses connected: false with no url', () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{'connected': false},
        );
        final repository = BrowserRepositoryImpl(client);

        final status = await repository.status();

        expect(status.connected, false);
        expect(status.url, isNull);
        expect(status.messages, isEmpty);
      });

      test('absent connected field defaults to false', () async {
        final repository = BrowserRepositoryImpl(FakeGatewayRpcClient());

        final status = await repository.status();

        expect(status.connected, false);
        expect(status.url, isNull);
        expect(status.messages, isEmpty);
      });
    },
  );

  group(
    'BrowserRepositoryImpl.connect (wire browser.manage action: connect)',
    () {
      test(
        'sends browser.manage with action=connect, omitting url and session_id',
        () async {
          final client = FakeGatewayRpcClient(
            handler: (_, _) => const <String, dynamic>{
              'connected': true,
              'url': 'ws://localhost:9222/devtools/browser/xyz',
            },
          );
          final repository = BrowserRepositoryImpl(client);

          final status = await repository.connect();

          expect(client.calls.single.method, 'browser.manage');
          expect(client.calls.single.params, <String, dynamic>{
            'action': 'connect',
          });
          expect(status.connected, true);
          expect(status.url, 'ws://localhost:9222/devtools/browser/xyz');
          expect(status.messages, isEmpty);
        },
      );

      test(
        'sends browser.manage with action=connect and url when provided',
        () async {
          final client = FakeGatewayRpcClient(
            handler: (_, _) => const <String, dynamic>{
              'connected': true,
              'url': 'ws://custom:9333/devtools/browser/foo',
            },
          );
          final repository = BrowserRepositoryImpl(client);

          final status = await repository.connect(
            url: 'ws://custom:9333/devtools/browser/foo',
          );

          expect(client.calls.single.method, 'browser.manage');
          expect(client.calls.single.params, <String, dynamic>{
            'action': 'connect',
            'url': 'ws://custom:9333/devtools/browser/foo',
          });
          expect(status.connected, true);
          expect(status.url, 'ws://custom:9333/devtools/browser/foo');
        },
      );

      test(
        'sends browser.manage with action=connect, url, and session_id',
        () async {
          final client = FakeGatewayRpcClient(
            handler: (_, _) => const <String, dynamic>{
              'connected': true,
              'url': 'ws://localhost:9222/devtools/browser/bar',
            },
          );
          final repository = BrowserRepositoryImpl(client);

          final status = await repository.connect(
            url: 'ws://localhost:9222/devtools/browser/bar',
            sessionId: 'sess_abc',
          );

          expect(client.calls.single.method, 'browser.manage');
          expect(client.calls.single.params, <String, dynamic>{
            'action': 'connect',
            'url': 'ws://localhost:9222/devtools/browser/bar',
            'session_id': 'sess_abc',
          });
          expect(status.connected, true);
          expect(status.url, 'ws://localhost:9222/devtools/browser/bar');
        },
      );

      test(
        'parses connected: false with messages (successful result, not error)',
        () async {
          final client = FakeGatewayRpcClient(
            handler: (_, _) => const <String, dynamic>{
              'connected': false,
              'url': 'ws://localhost:9222/devtools/browser/failed',
              'messages': <String>[
                'Failed to launch browser',
                'Timeout waiting for CDP',
              ],
            },
          );
          final repository = BrowserRepositoryImpl(client);

          final status = await repository.connect();

          expect(status.connected, false);
          expect(status.url, 'ws://localhost:9222/devtools/browser/failed');
          expect(status.messages, <String>[
            'Failed to launch browser',
            'Timeout waiting for CDP',
          ]);
        },
      );

      test('absent messages field defaults to empty list', () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{'connected': false},
        );
        final repository = BrowserRepositoryImpl(client);

        final status = await repository.connect();

        expect(status.connected, false);
        expect(status.messages, isEmpty);
      });
    },
  );

  group(
    'BrowserRepositoryImpl.disconnect (wire browser.manage action: disconnect)',
    () {
      test('sends browser.manage with action=disconnect only', () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{'connected': false},
        );
        final repository = BrowserRepositoryImpl(client);

        final status = await repository.disconnect();

        expect(client.calls.single.method, 'browser.manage');
        expect(client.calls.single.params, <String, dynamic>{
          'action': 'disconnect',
        });
        expect(status.connected, false);
      });
    },
  );

  group('BrowserRepositoryImpl.restartPreview (wire preview.restart)', () {
    test('sends preview.restart with required session_id and url', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'task_id': 'preview_abc123'},
      );
      final repository = BrowserRepositoryImpl(client);

      final taskId = await repository.restartPreview(
        sessionId: 'sess_abc',
        url: 'http://localhost:3000',
      );

      expect(client.calls.single.method, 'preview.restart');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'url': 'http://localhost:3000',
      });
      expect(taskId, 'preview_abc123');
    });

    test(
      'sends preview.restart with session_id, url, cwd, and context',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'task_id': 'preview_def456',
          },
        );
        final repository = BrowserRepositoryImpl(client);

        final taskId = await repository.restartPreview(
          sessionId: 'sess_xyz',
          url: 'http://localhost:8080/app',
          cwd: '/home/user/project',
          context: 'Development environment',
        );

        expect(client.calls.single.method, 'preview.restart');
        expect(client.calls.single.params, <String, dynamic>{
          'session_id': 'sess_xyz',
          'url': 'http://localhost:8080/app',
          'cwd': '/home/user/project',
          'context': 'Development environment',
        });
        expect(taskId, 'preview_def456');
      },
    );

    test('omits cwd and context when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'task_id': 'preview_ghi789'},
      );
      final repository = BrowserRepositoryImpl(client);

      final taskId = await repository.restartPreview(
        sessionId: 'sess_123',
        url: 'http://example.com',
        cwd: null,
        context: null,
      );

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_123',
        'url': 'http://example.com',
      });
      expect(taskId, 'preview_ghi789');
    });

    test('absent task_id field falls back to empty string', () async {
      final repository = BrowserRepositoryImpl(FakeGatewayRpcClient());

      final taskId = await repository.restartPreview(
        sessionId: 'sess_abc',
        url: 'http://localhost:3000',
      );

      expect(taskId, '');
    });
  });
}
