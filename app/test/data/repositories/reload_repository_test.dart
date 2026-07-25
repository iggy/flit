// P4-05 acceptance: ReloadRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping (confirm_required vs reloaded).

import 'package:flit/data/repositories/reload_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/repositories/reload_repository.dart';
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
  group('ReloadRepositoryImpl.reloadMcp (wire reload.mcp)', () {
    test('sends reload.mcp with session_id when provided', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'reloaded',
          'loaded_rev': 1,
        },
      );
      final repository = ReloadRepositoryImpl(client);

      final outcome =
          await repository.reloadMcp(sessionId: 'sess_abc', confirm: false);

      expect(client.calls.single.method, 'reload.mcp');
      expect(
        client.calls.single.params,
        <String, dynamic>{'session_id': 'sess_abc'},
      );
      expect(outcome, isA<ReloadMcpDone>());
      expect((outcome as ReloadMcpDone).coalesced, false);
    });

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'reloaded',
        },
      );
      final repository = ReloadRepositoryImpl(client);

      await repository.reloadMcp();

      expect(client.calls.single.params, isEmpty);
    });

    test('includes confirm:true when confirm is true', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'reloaded',
        },
      );
      final repository = ReloadRepositoryImpl(client);

      await repository.reloadMcp(sessionId: 'sess_abc', confirm: true);

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'confirm': true,
      });
    });

    test('maps status:confirm_required to ReloadMcpConfirmRequired', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'confirm_required',
          'message': 'This will reload all MCP servers. Continue?',
        },
      );
      final repository = ReloadRepositoryImpl(client);

      final outcome = await repository.reloadMcp();

      expect(outcome, isA<ReloadMcpConfirmRequired>());
      expect(
        (outcome as ReloadMcpConfirmRequired).message,
        'This will reload all MCP servers. Continue?',
      );
    });

    test('maps status:reloaded to ReloadMcpDone', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'reloaded',
          'loaded_rev': 2,
          'coalesced': true,
        },
      );
      final repository = ReloadRepositoryImpl(client);

      final outcome = await repository.reloadMcp();

      expect(outcome, isA<ReloadMcpDone>());
      expect((outcome as ReloadMcpDone).coalesced, true);
    });

    test('absent message in confirm_required falls back to empty string',
        () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'confirm_required',
        },
      );
      final repository = ReloadRepositoryImpl(client);

      final outcome = await repository.reloadMcp();

      expect(outcome, isA<ReloadMcpConfirmRequired>());
      expect((outcome as ReloadMcpConfirmRequired).message, '');
    });

    test('absent coalesced in reloaded falls back to false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'reloaded',
        },
      );
      final repository = ReloadRepositoryImpl(client);

      final outcome = await repository.reloadMcp();

      expect(outcome, isA<ReloadMcpDone>());
      expect((outcome as ReloadMcpDone).coalesced, false);
    });
  });

  group('ReloadRepositoryImpl.reloadEnv (wire reload.env)', () {
    test('sends reload.env and reads updated count', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'updated': 5,
        },
      );
      final repository = ReloadRepositoryImpl(client);

      final count = await repository.reloadEnv();

      expect(client.calls.single.method, 'reload.env');
      expect(client.calls.single.params, isEmpty);
      expect(count, 5);
    });

    test('absent updated field falls back to 0', () async {
      final repository = ReloadRepositoryImpl(FakeGatewayRpcClient());

      final count = await repository.reloadEnv();

      expect(count, 0);
    });
  });
}
