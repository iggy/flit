import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/usage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// `reasoning.delta` (§6): a chunk of the model's extended-thinking stream,
  /// interleaved with `message.delta` while the turn runs (coalesced ~30fps
  /// like the text deltas — §5). The full reasoning also arrives on
  /// `message.complete.reasoning`, so this is the LIVE view of the same text.
  ///
  /// [verbose] is the gateway's "the user asked for unclamped reasoning" hint
  /// (`/reasoning full`); flit renders the stream either way.
  const factory TypedGatewayEvent.reasoningDelta({
    required String? sessionId,
    required String text,
    required bool verbose,
  }) = ReasoningDelta;

  /// `reasoning.available` (§6): the NON-streaming sibling of
  /// `reasoning.delta` — providers that hand reasoning back in one block emit
  /// this once instead of a delta stream, so it is a fallback: ignore it when
  /// deltas already arrived (mirroring the TUI's `recordReasoningAvailable`).
  const factory TypedGatewayEvent.reasoningAvailable({
    required String? sessionId,
    required String text,
    required bool verbose,
  }) = ReasoningAvailable;

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

  /// `sudo.request` (protocol §8.1 / P3-08): correlated by [requestId].
  /// The agent needs a sudo password. Payload carries only the request id.
  const factory TypedGatewayEvent.sudoRequest({
    required String? sessionId,
    required String requestId,
  }) = SudoRequestEvent;

  /// `secret.request` (protocol §8.1 / P3-08): correlated by [requestId].
  /// The agent needs a secret value (e.g. an API key) for [envVar].
  const factory TypedGatewayEvent.secretRequest({
    required String? sessionId,
    required String envVar,
    required String prompt,
    required String requestId,
  }) = SecretRequestEvent;

  /// `terminal.read.request` (P3-08): correlated by [requestId]. The agent
  /// asks the client to return terminal buffer contents. [start]/[count] are
  /// optional line-range hints.
  const factory TypedGatewayEvent.terminalReadRequest({
    required String? sessionId,
    required String requestId,
    int? start,
    int? count,
  }) = TerminalReadRequestEvent;

  /// `subagent.*` (P3-04): the subagent/delegation event stream folded into a
  /// spawn tree keyed by [subagentId]/[parentId]. [type] is the wire type
  /// (e.g. `subagent.start`). Fields not present on a given event type are
  /// null/default (see docs/reference/08-agent-transparency-wire-shapes.md).
  const factory TypedGatewayEvent.subagentEvent({
    required String? sessionId,
    required String type,
    required String goal,
    required int taskCount,
    required int taskIndex,
    String? subagentId,
    String? parentId,
    String? childSessionId,
    int? depth,
    String? model,
    int? toolCount,
    List<String>? toolsets,
    int? inputTokens,
    int? outputTokens,
    int? reasoningTokens,
    int? apiCalls,
    List<String>? filesRead,
    List<String>? filesWritten,
    String? toolName,
    String? toolPreview,
    String? text,
    String? status,
    String? summary,
    double? durationSeconds,
    double? costUsd,
  }) = SubagentEvent;

  /// `status.update` (§6): transient status line `{kind, text}`.
  const factory TypedGatewayEvent.statusUpdate({
    required String? sessionId,
    String? kind,
    String? text,
  }) = StatusUpdate;

  /// `background.complete` (P5-02): a detached `prompt.background` run
  /// finished. Emitted on the PARENT session_id. [text] is the final
  /// response, or "error: ..." on failure.
  const factory TypedGatewayEvent.backgroundComplete({
    required String? sessionId,
    required String taskId,
    required String text,
  }) = BackgroundCompleteEvent;

  /// `voice.status` (P7-05): server-side mic state ∈ idle|listening|transcribing.
  const factory TypedGatewayEvent.voiceStatus({
    required String? sessionId,
    required String state,
  }) = VoiceStatusEvent;

  /// `voice.transcript` (P7-05): a finished transcript to drop into the composer,
  /// OR a no-speech-limit signal (three silent captures) when [noSpeechLimit].
  const factory TypedGatewayEvent.voiceTranscript({
    required String? sessionId,
    String? text,
    required bool noSpeechLimit,
  }) = VoiceTranscriptEvent;

  /// `skin.changed` (P9-07): the gateway's active skin moved (a name switch OR
  /// an in-place color edit). Session-LESS global broadcast; [skin] IS the
  /// payload dict — the same shape as `gateway.ready`'s payload
  /// (`resolve_skin()` in tui_gateway/server.py). `{}` on gateway-side failure.
  const factory TypedGatewayEvent.skinChanged({
    required Map<String, dynamic> skin,
  }) = SkinChanged;

  /// `browser.progress` (P9-05): a CDP connect progress line, emitted only when
  /// `browser.manage` was called WITH a `session_id`. [level] ∈ info|error.
  const factory TypedGatewayEvent.browserProgress({
    required String? sessionId,
    required String message,
    required String level,
  }) = BrowserProgressEvent;

  /// `preview.restart.progress` (P9-05): a progress line from the hidden
  /// preview-restart agent, correlated by [taskId]. [level] defaults to `info`
  /// (the first frame omits it).
  const factory TypedGatewayEvent.previewRestartProgress({
    required String? sessionId,
    required String taskId,
    required String text,
    required String level,
  }) = PreviewRestartProgressEvent;

  /// `preview.restart.complete` (P9-05): the restart agent finished. [text] is
  /// its final response, or `error: …` on failure.
  const factory TypedGatewayEvent.previewRestartComplete({
    required String? sessionId,
    required String taskId,
    required String text,
  }) = PreviewRestartCompleteEvent;

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
      case 'reasoning.delta':
        return TypedGatewayEvent.reasoningDelta(
          sessionId: sessionId,
          text: _asString(payload['text']) ?? '',
          verbose: _asBool(payload['verbose']) ?? false,
        );
      case 'reasoning.available':
        return TypedGatewayEvent.reasoningAvailable(
          sessionId: sessionId,
          text: _asString(payload['text']) ?? '',
          verbose: _asBool(payload['verbose']) ?? false,
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
      case 'sudo.request':
        return TypedGatewayEvent.sudoRequest(
          sessionId: sessionId,
          requestId: _asString(payload['request_id']) ?? '',
        );
      case 'secret.request':
        return TypedGatewayEvent.secretRequest(
          sessionId: sessionId,
          envVar: _asString(payload['env_var']) ?? '',
          prompt: _asString(payload['prompt']) ?? '',
          requestId: _asString(payload['request_id']) ?? '',
        );
      case 'terminal.read.request':
        return TypedGatewayEvent.terminalReadRequest(
          sessionId: sessionId,
          requestId: _asString(payload['request_id']) ?? '',
          start: _asInt(payload['start']),
          count: _asInt(payload['count']),
        );
      case 'subagent.spawn_requested':
      case 'subagent.start':
      case 'subagent.thinking':
      case 'subagent.tool':
      case 'subagent.progress':
      case 'subagent.complete':
        return TypedGatewayEvent.subagentEvent(
          sessionId: sessionId,
          type: raw.type,
          goal: _asString(payload['goal']) ?? '',
          taskCount: _asInt(payload['task_count']) ?? 1,
          taskIndex: _asInt(payload['task_index']) ?? 0,
          subagentId: _asString(payload['subagent_id']),
          parentId: _asString(payload['parent_id']),
          childSessionId: _asString(payload['child_session_id']),
          depth: _asInt(payload['depth']),
          model: _asString(payload['model']),
          toolCount: _asInt(payload['tool_count']),
          toolsets: _asStringList(payload['toolsets']),
          inputTokens: _asInt(payload['input_tokens']),
          outputTokens: _asInt(payload['output_tokens']),
          reasoningTokens: _asInt(payload['reasoning_tokens']),
          apiCalls: _asInt(payload['api_calls']),
          filesRead: _asStringList(payload['files_read']),
          filesWritten: _asStringList(payload['files_written']),
          toolName: _asString(payload['tool_name']),
          toolPreview: _asString(payload['tool_preview']),
          text: _asString(payload['text']),
          status: _asString(payload['status']),
          summary: _asString(payload['summary']),
          durationSeconds: _asDouble(payload['duration_seconds']),
          costUsd: _asDouble(payload['cost_usd']),
        );
      case 'background.complete':
        return TypedGatewayEvent.backgroundComplete(
          sessionId: sessionId,
          taskId: _asString(payload['task_id']) ?? '',
          text: _asString(payload['text']) ?? '',
        );
      case 'status.update':
        return TypedGatewayEvent.statusUpdate(
          sessionId: sessionId,
          kind: _asString(payload['kind']),
          text: _asString(payload['text']),
        );
      case 'voice.status':
        return TypedGatewayEvent.voiceStatus(
          sessionId: sessionId,
          state: _asString(payload['state']) ?? '',
        );
      case 'voice.transcript':
        return TypedGatewayEvent.voiceTranscript(
          sessionId: sessionId,
          text: _asString(payload['text']),
          noSpeechLimit: _asBool(payload['no_speech_limit']) ?? false,
        );
      case 'skin.changed':
        // Session-less global broadcast; payload IS the skin (P9-07).
        return TypedGatewayEvent.skinChanged(skin: payload);
      case 'browser.progress':
        return TypedGatewayEvent.browserProgress(
          sessionId: sessionId,
          message: _asString(payload['message']) ?? '',
          level: _asString(payload['level']) ?? 'info',
        );
      case 'preview.restart.progress':
        return TypedGatewayEvent.previewRestartProgress(
          sessionId: sessionId,
          taskId: _asString(payload['task_id']) ?? '',
          text: _asString(payload['text']) ?? '',
          level: _asString(payload['level']) ?? 'info',
        );
      case 'preview.restart.complete':
        return TypedGatewayEvent.previewRestartComplete(
          sessionId: sessionId,
          taskId: _asString(payload['task_id']) ?? '',
          text: _asString(payload['text']) ?? '',
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

int? _asInt(Object? value) => value is num ? value.toInt() : null;

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
