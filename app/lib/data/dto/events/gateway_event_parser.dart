import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/usage.dart';

part 'gateway_event_parser.freezed.dart';

/// The typed event union over [GatewayEvent] (ticket P1-03).
///
/// Variant fields come straight from docs/reference/03-mvp-wire-shapes.md
/// and 01-gateway-protocol.md §6–§8; snake_case wire keys are absorbed by
/// [parseGatewayEvent]. Anything unrecognized or malformed falls back to
/// [UnknownEvent] — parsing NEVER throws.
@freezed
sealed class TypedGatewayEvent with _$TypedGatewayEvent {
  /// `gateway.ready` (wire §1): [skin] IS the payload dict (the TS nesting
  /// under `payload.skin` is wrong — 00-overview.md divergences).
  const factory TypedGatewayEvent.gatewayReady({
    required Map<String, dynamic> skin,
  }) = GatewayReady;

  /// `session.info` (§6): model/usage/tools refresh after a turn.
  /// [info] IS the payload dict — its shape is not pinned by the docs.
  const factory TypedGatewayEvent.sessionInfo({
    required String? sessionId,
    required Map<String, dynamic> info,
  }) = SessionInfo;

  /// `message.start` (§6): a streaming assistant message begins.
  const factory TypedGatewayEvent.messageStart({required String? sessionId}) =
      MessageStart;

  /// `message.delta` (§6): accumulated into the streaming bubble (§5).
  const factory TypedGatewayEvent.messageDelta({
    required String? sessionId,
    required String text,
    String? rendered,
  }) = MessageDelta;

  /// `message.complete` (§6): turn-terminal. [text] is the FULL final text;
  /// [status] comes from `payload.status` (∈ complete|interrupted|error —
  /// a divergence the TS types miss, 00-overview.md).
  const factory TypedGatewayEvent.messageComplete({
    required String? sessionId,
    required String text,
    String? rendered,
    String? reasoning,
    Usage? usage,
    required MessageTerminalStatus status,
  }) = MessageComplete;

  /// `error` (§6): the OTHER turn-terminal frame, sent instead of
  /// `message.complete` on a fatal turn error.
  const factory TypedGatewayEvent.turnError({
    required String? sessionId,
    String? message,
  }) = TurnError;

  /// `tool.start` (§7). [todos] is not pinned by the docs — kept raw.
  const factory TypedGatewayEvent.toolStart({
    required String? sessionId,
    required String toolId,
    required String name,
    String? context,
    String? argsText,
    List<dynamic>? todos,
  }) = ToolStart;

  /// `tool.progress` (§7): an incremental progress line.
  const factory TypedGatewayEvent.toolProgress({
    required String? sessionId,
    required String name,
    required String preview,
  }) = ToolProgress;

  /// `tool.complete` (§7): correlate to `tool.start` by [toolId].
  /// [result] is polymorphic (parsed JSON dict/list OR raw string);
  /// [args]/[todos] shapes are not pinned by the docs — kept raw.
  const factory TypedGatewayEvent.toolComplete({
    required String? sessionId,
    required String toolId,
    required String name,
    dynamic args,
    dynamic result,
    double? durationS,
    String? summary,
    String? resultText,
    String? inlineDiff,
    List<dynamic>? todos,
    String? error,
  }) = ToolComplete;

  /// `approval.request` (§8.2/wire §10): correlated by SESSION (no
  /// request id on the wire).
  const factory TypedGatewayEvent.approvalRequest({
    required String? sessionId,
    required String command,
    required String description,
    String? patternKey,
    required List<String> patternKeys,
    required bool allowPermanent,
  }) = ApprovalRequestEvent;

  /// `clarify.request` (§8.1/wire §11): correlated by [requestId].
  /// [choices] null means free-text.
  const factory TypedGatewayEvent.clarifyRequest({
    required String? sessionId,
    required String question,
    List<String>? choices,
    required String requestId,
  }) = ClarifyRequestEvent;

  /// `status.update` (§6): transient status line `{kind, text}`.
  const factory TypedGatewayEvent.statusUpdate({
    required String? sessionId,
    String? kind,
    String? text,
  }) = StatusUpdate;

  /// Fallback for any event type the MVP doesn't consume — keeps the raw
  /// frame so nothing is ever lost or thrown.
  const factory TypedGatewayEvent.unknown({
    required String type,
    required String? sessionId,
    required Map<String, dynamic> payload,
  }) = UnknownEvent;
}

/// Map a raw [GatewayEvent] (`params.type`/`session_id`/`payload`) to its
/// [TypedGatewayEvent] variant.
///
/// NEVER throws: unknown `type` strings, malformed payloads, and missing
/// fields fall back to nulls/defaults or [UnknownEvent].
TypedGatewayEvent parseGatewayEvent(GatewayEvent raw) {
  try {
    final payload = raw.payload;
    final sessionId = raw.sessionId;
    switch (raw.type) {
      case 'gateway.ready':
        // No session_id on this frame (protocol §4); payload IS the skin.
        return TypedGatewayEvent.gatewayReady(skin: payload);
      case 'session.info':
        return TypedGatewayEvent.sessionInfo(
          sessionId: sessionId,
          info: payload,
        );
      case 'message.start':
        return TypedGatewayEvent.messageStart(sessionId: sessionId);
      case 'message.delta':
        return TypedGatewayEvent.messageDelta(
          sessionId: sessionId,
          text: _asString(payload['text']) ?? '',
          rendered: _asString(payload['rendered']),
        );
      case 'message.complete':
        return TypedGatewayEvent.messageComplete(
          sessionId: sessionId,
          text: _asString(payload['text']) ?? '',
          rendered: _asString(payload['rendered']),
          reasoning: _asString(payload['reasoning']),
          usage: _parseUsage(payload),
          status: _parseTerminalStatus(payload['status']),
        );
      case 'error':
        return TypedGatewayEvent.turnError(
          sessionId: sessionId,
          message: _asString(payload['message']),
        );
      case 'tool.start':
        return TypedGatewayEvent.toolStart(
          sessionId: sessionId,
          toolId: _asString(payload['tool_id']) ?? '',
          name: _asString(payload['name']) ?? '',
          context: _asString(payload['context']),
          argsText: _asString(payload['args_text']),
          todos: _asList(payload['todos']),
        );
      case 'tool.progress':
        return TypedGatewayEvent.toolProgress(
          sessionId: sessionId,
          name: _asString(payload['name']) ?? '',
          preview: _asString(payload['preview']) ?? '',
        );
      case 'tool.complete':
        return TypedGatewayEvent.toolComplete(
          sessionId: sessionId,
          toolId: _asString(payload['tool_id']) ?? '',
          name: _asString(payload['name']) ?? '',
          args: payload['args'],
          result: payload['result'],
          durationS: _asDouble(payload['duration_s']),
          summary: _asString(payload['summary']),
          resultText: _asString(payload['result_text']),
          inlineDiff: _asString(payload['inline_diff']),
          todos: _asList(payload['todos']),
          error: _asString(payload['error']),
        );
      case 'approval.request':
        return TypedGatewayEvent.approvalRequest(
          sessionId: sessionId,
          command: _asString(payload['command']) ?? '',
          description: _asString(payload['description']) ?? '',
          patternKey: _asString(payload['pattern_key']),
          patternKeys: _asStringList(payload['pattern_keys']) ?? const [],
          allowPermanent: _asBool(payload['allow_permanent']) ?? false,
        );
      case 'clarify.request':
        return TypedGatewayEvent.clarifyRequest(
          sessionId: sessionId,
          question: _asString(payload['question']) ?? '',
          choices: _asStringList(payload['choices']),
          requestId: _asString(payload['request_id']) ?? '',
        );
      case 'status.update':
        return TypedGatewayEvent.statusUpdate(
          sessionId: sessionId,
          kind: _asString(payload['kind']),
          text: _asString(payload['text']),
        );
      default:
        return _unknown(raw);
    }
  } on Object {
    return _unknown(raw);
  }
}

TypedGatewayEvent _unknown(GatewayEvent raw) {
  return TypedGatewayEvent.unknown(
    type: raw.type,
    sessionId: raw.sessionId,
    payload: raw.payload,
  );
}

String? _asString(Object? value) => value is String ? value : null;

bool? _asBool(Object? value) => value is bool ? value : null;

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

List<dynamic>? _asList(Object? value) {
  return value is List ? List<dynamic>.of(value) : null;
}

List<String>? _asStringList(Object? value) {
  return value is List ? value.whereType<String>().toList() : null;
}

/// `message.complete.payload.status` ∈ complete|interrupted|error;
/// unknown or missing → complete (the frame is turn-terminal regardless).
MessageTerminalStatus _parseTerminalStatus(Object? status) {
  return switch (status) {
    'interrupted' => MessageTerminalStatus.interrupted,
    'error' => MessageTerminalStatus.error,
    _ => MessageTerminalStatus.complete,
  };
}

/// `usage:{input, output, cost_usd}` (wire §7) → [Usage]; absent/malformed
/// → null.
Usage? _parseUsage(Map<String, dynamic> payload) {
  final usage = payload['usage'];
  if (usage is! Map) {
    return null;
  }
  final input = usage['input'];
  final output = usage['output'];
  final cost = usage['cost_usd'];
  return Usage(
    input: input is num ? input.toInt() : 0,
    output: output is num ? output.toInt() : 0,
    costUsd: cost is num ? cost.toDouble() : null,
  );
}
