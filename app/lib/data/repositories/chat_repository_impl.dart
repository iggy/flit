import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/dto/status_result_dto.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/repositories/chat_repository.dart';

/// [ChatRepository] over [GatewayRpcClient] (ticket P1-05).
///
/// Method names/params come VERBATIM from
/// docs/reference/03-mvp-wire-shapes.md §6, §10, §11. The two correlation
/// models (protocol §8) are kept strictly separate.
final class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<void> submitPrompt(String liveId, String text) async {
    // Wire §6: the result is `{"status":"streaming"}` — NOT `{ok:true}`.
    // Defensive: a missing/unexpected status still succeeds; the reply
    // arrives as turn events regardless, and those are the source of truth.
    final result = await _client.request('prompt.submit', <String, dynamic>{
      'session_id': liveId,
      'text': text,
    });
    _expectStatus(result, 'streaming');
  }

  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) {
    // Filter to events FOR this session. `e.sessionId == liveId` excludes
    // null-session events (gateway.ready — protocol §4), which are
    // connection-level, not turn events.
    return _client.events
        .where((event) => event.sessionId == liveId)
        .map(parseGatewayEvent);
  }

  @override
  Future<void> respondApproval(String liveId, String choice) async {
    // Wire §10: correlated BY SESSION (protocol §8.2) — no request_id.
    // The choice string (approve / deny / approve-and-remember when
    // allow_permanent) is passed through verbatim.
    await _client.request('approval.respond', <String, dynamic>{
      'session_id': liveId,
      'choice': choice,
    });
  }

  @override
  Future<void> respondClarify(String requestId, String answer) async {
    // Wire §11: correlated BY REQUEST_ID (protocol §8.1) — no session_id.
    // Success shape is `{"status":"ok"}`; an already-resolved request comes
    // back as a JSON-RPC error (code 4009) → GatewayRpcException.
    final result = await _client.request('clarify.respond', <String, dynamic>{
      'request_id': requestId,
      'answer': answer,
    });
    _expectStatus(result, 'ok');
  }

  @override
  Future<void> respondSudo(String requestId, String password) async {
    // P3-08: correlated BY REQUEST_ID — no session_id.
    // Success shape is `{"status":"ok"}`; an already-resolved request comes
    // back as a JSON-RPC error (code 4009) → GatewayRpcException.
    final result = await _client.request('sudo.respond', <String, dynamic>{
      'request_id': requestId,
      'password': password,
    });
    _expectStatus(result, 'ok');
  }

  @override
  Future<void> respondSecret(String requestId, String value) async {
    // P3-08: correlated BY REQUEST_ID — no session_id.
    // Success shape is `{"status":"ok"}`; an already-resolved request comes
    // back as a JSON-RPC error (code 4009) → GatewayRpcException.
    final result = await _client.request('secret.respond', <String, dynamic>{
      'request_id': requestId,
      'value': value,
    });
    _expectStatus(result, 'ok');
  }

  @override
  Future<void> respondTerminalRead(String requestId, String text) async {
    // P3-08: correlated BY REQUEST_ID — no session_id.
    // Success shape is `{"status":"ok"}`; an already-resolved request comes
    // back as a JSON-RPC error (code 4009) → GatewayRpcException.
    final result =
        await _client.request('terminal.read.respond', <String, dynamic>{
      'request_id': requestId,
      'text': text,
    });
    _expectStatus(result, 'ok');
  }

  /// Asserts the normal-path acknowledgement without enforcing it (see the
  /// defensive note at [submitPrompt]).
  static void _expectStatus(Map<String, dynamic> result, String expected) {
    final status = StatusResultDto.fromJson(result).status;
    assert(status == expected, 'expected status "$expected", got "$status"');
  }
}
