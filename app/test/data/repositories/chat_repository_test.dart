// P1-05 acceptance: ChatRepositoryImpl against a fake RPC client.
// Asserts the EXACT frames from docs/reference/03-mvp-wire-shapes.md
// §6/§10/§11, the turnEvents session filter, and that the two correlation
// models (protocol §8) are never crossed.

import 'dart:async';

import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/repositories/chat_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY the
/// two surfaces the repository uses — `request` (recorded, answered from
/// [handler]) and `events` (fed by [emit]).
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  final Map<String, dynamic> Function(
    String method,
    Map<String, dynamic> params,
  )?
  handler;

  final List<({String method, Map<String, dynamic> params})> calls =
      <({String method, Map<String, dynamic> params})>[];

  final StreamController<GatewayEvent> _events =
      StreamController<GatewayEvent>.broadcast();

  @override
  Stream<GatewayEvent> get events => _events.stream;

  /// Push a raw (unparsed) server event.
  void emit(GatewayEvent event) => _events.add(event);

  @override
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const <String, dynamic>{},
  ]) async {
    calls.add((method: method, params: params));
    final answer = handler;
    return answer == null ? const <String, dynamic>{} : answer(method, params);
  }

  Future<void> dispose() => _events.close();
}

void main() {
  late FakeGatewayRpcClient client;
  late ChatRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = ChatRepositoryImpl(client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('submitPrompt (wire §6)', () {
    test('sends prompt.submit with the exact frame', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'streaming'},
      );
      repository = ChatRepositoryImpl(client);

      await repository.submitPrompt('a1b2c3d4', 'List the files in the repo.');

      expect(client.calls.single.method, 'prompt.submit');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'text': 'List the files in the repo.',
      });
    });
  });

  group('turnEvents', () {
    test('filters by session id and parses to TypedGatewayEvent', () async {
      final seen = <TypedGatewayEvent>[];
      final sub = repository.turnEvents('a1b2c3d4').listen(seen.add);

      // For this session → delivered, parsed.
      client.emit(
        const GatewayEvent(
          type: 'message.delta',
          sessionId: 'a1b2c3d4',
          payload: <String, dynamic>{'text': "I'll "},
        ),
      );
      // For ANOTHER session → excluded.
      client.emit(
        const GatewayEvent(
          type: 'message.delta',
          sessionId: 'e5f6a7b8',
          payload: <String, dynamic>{'text': 'wrong session'},
        ),
      );
      // Null session id (gateway.ready) → EXCLUDED: not a turn event.
      client.emit(
        const GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{'name': 'hermes'},
        ),
      );
      await pumpEventQueue();

      expect(seen, hasLength(1));
      expect(seen.single, isA<MessageDelta>());
      final delta = seen.single as MessageDelta;
      expect(delta.sessionId, 'a1b2c3d4');
      expect(delta.text, "I'll ");

      await sub.cancel();
    });
  });

  group('respondApproval (wire §10)', () {
    test('is correlated BY SESSION, choice passed through verbatim', () async {
      await repository.respondApproval('a1b2c3d4', 'approve');

      expect(client.calls.single.method, 'approval.respond');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'choice': 'approve',
      });
      // No request_id — approvals don't carry one (protocol §8.2).
      expect(client.calls.single.params.containsKey('request_id'), isFalse);
    });

    test('passes through the permanent variant when allowed', () async {
      await repository.respondApproval('a1b2c3d4', 'approve-and-remember');

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'choice': 'approve-and-remember',
      });
    });
  });

  group('respondClarify (wire §11)', () {
    test('is correlated BY REQUEST_ID — never by session', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'ok'},
      );
      repository = ChatRepositoryImpl(client);

      await repository.respondClarify('9f3a1c2b', 'staging');

      expect(client.calls.single.method, 'clarify.respond');
      expect(client.calls.single.params, <String, dynamic>{
        'request_id': '9f3a1c2b',
        'answer': 'staging',
      });
      // No session_id — clarifies are request-correlated (protocol §8.1).
      expect(client.calls.single.params.containsKey('session_id'), isFalse);
    });
  });
}
