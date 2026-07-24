import 'package:hermes/data/dto/events/gateway_event_parser.dart';

/// Intent-level chat operations (ticket P1-05).
///
/// The two interactive-prompt correlation models (protocol §8) are NOT
/// crossed: approvals answer by **session**, clarifications by **request_id**.
abstract interface class ChatRepository {
  /// `prompt.submit` (wire §6): fire-and-forget for content — the reply
  /// arrives as turn events on [turnEvents]. Expects `{status:"streaming"}`.
  Future<void> submitPrompt(String liveId, String text);

  /// The typed turn event stream for one live session: the client's raw
  /// event stream filtered to `session_id == liveId` (null-session events
  /// such as `gateway.ready` are EXCLUDED — they are not turn events) and
  /// parsed into [TypedGatewayEvent]s.
  Stream<TypedGatewayEvent> turnEvents(String liveId);

  /// `approval.respond` (wire §10) — correlated BY SESSION (protocol §8.2);
  /// the event carried no request id. [choice] ∈ approve / deny /
  /// approve-and-remember — passed through verbatim.
  Future<void> respondApproval(String liveId, String choice);

  /// `clarify.respond` (wire §11) — correlated BY REQUEST_ID
  /// (protocol §8.1). Expects `{status:"ok"}`.
  Future<void> respondClarify(String requestId, String answer);
}
