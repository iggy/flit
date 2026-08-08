import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/submit_prompt_result.dart';

/// Intent-level chat operations (ticket P1-05).
///
/// The two interactive-prompt correlation models (protocol §8) are NOT
/// crossed: approvals answer by **session**, clarifications by **request_id**.
abstract interface class ChatRepository {
  /// `prompt.submit` (wire §6): fire-and-forget for content — the reply
  /// arrives as turn events on [turnEvents]. Returns the gateway's
  /// disposition: `streaming` when the turn started immediately, or the
  /// busy-session outcome `steered` / `redirected` / `queued` (gateway 0.20
  /// `_handle_busy_submit`) when the session was mid-turn.
  ///
  /// [truncateBeforeUserOrdinal] (rewind/regenerate/edit) requires
  /// [confirmTruncate] = true, and [confirmEmptyTruncate] = true when the cut
  /// would wipe the whole transcript (ordinal 0) — otherwise the gateway
  /// refuses with JSON-RPC 4028/4029.
  Future<SubmitPromptResult> submitPrompt(
    String liveId,
    String text, {
    int? truncateBeforeUserOrdinal,
    bool confirmTruncate = false,
    bool confirmEmptyTruncate = false,
  });

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

  /// `sudo.respond` (P3-08) — correlated BY REQUEST_ID. Expects `{status:"ok"}`.
  Future<void> respondSudo(String requestId, String password);

  /// `secret.respond` (P3-08) — correlated BY REQUEST_ID. Expects `{status:"ok"}`.
  Future<void> respondSecret(String requestId, String value);

  /// `terminal.read.respond` (P3-08) — correlated BY REQUEST_ID.
  /// Expects `{status:"ok"}`.
  Future<void> respondTerminalRead(String requestId, String text);
}
