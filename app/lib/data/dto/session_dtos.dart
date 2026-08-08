import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_dtos.g.dart';

/// Wire DTOs for `session.create` / `session.list` / `session.active_list` /
/// `session.resume` (docs/reference/03-mvp-wire-shapes.md §2–§5).
///
/// The two-session-ids quirk (protocol §9) is absorbed here: domain models
/// see a clean `liveId` (short) and `durableId` (stored/session_key).

/// `session.create` result (§2).
@JsonSerializable()
class SessionCreateResultDto {
  const SessionCreateResultDto({
    this.sessionId,
    this.storedSessionId,
    this.sessionKey,
    this.info,
  });

  factory SessionCreateResultDto.fromJson(Map<String, dynamic> json) =>
      _$SessionCreateResultDtoFromJson(json);

  /// SHORT live id — use for prompt/interrupt.
  @JsonKey(name: 'session_id')
  final String? sessionId;

  /// Durable id — use for list/resume/delete.
  @JsonKey(name: 'stored_session_id')
  final String? storedSessionId;

  /// Durable id echo (same value family as [storedSessionId]).
  @JsonKey(name: 'session_key')
  final String? sessionKey;

  /// Opaque info dict (e.g. `{"model":..., "provider":..., "lazy":true}`).
  final Map<String, dynamic>? info;

  Map<String, dynamic> toJson() => _$SessionCreateResultDtoToJson(this);

  /// Fold into the clean domain model.
  SessionCreateResult toDomain() {
    return SessionCreateResult(
      liveId: sessionId ?? '',
      durableId: storedSessionId ?? sessionKey ?? '',
      info: info,
    );
  }
}

/// One entry of the `session.list` result (§3). `id` is a DURABLE id.
@JsonSerializable()
class SessionSummaryDto {
  const SessionSummaryDto({
    this.id,
    this.title,
    this.preview,
    this.messageCount,
    this.startedAt,
    this.source,
  });

  factory SessionSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryDtoFromJson(json);

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'preview')
  final String? preview;

  @JsonKey(name: 'message_count')
  final int? messageCount;

  /// Epoch SECONDS on the wire.
  @JsonKey(name: 'started_at')
  final int? startedAt;

  @JsonKey(name: 'source')
  final String? source;

  Map<String, dynamic> toJson() => _$SessionSummaryDtoToJson(this);

  SessionSummary toDomain() {
    return SessionSummary(
      durableId: id ?? '',
      title: title ?? '',
      preview: preview ?? '',
      messageCount: messageCount ?? 0,
      startedAt: _epochSecondsToDateTime(startedAt),
      source: source,
    );
  }
}

/// `session.list` result (§3).
@JsonSerializable()
class SessionListResultDto {
  const SessionListResultDto({this.sessions = const <SessionSummaryDto>[]});

  factory SessionListResultDto.fromJson(Map<String, dynamic> json) =>
      _$SessionListResultDtoFromJson(json);

  @JsonKey(name: 'sessions')
  final List<SessionSummaryDto> sessions;

  Map<String, dynamic> toJson() => _$SessionListResultDtoToJson(this);

  List<SessionSummary> toDomain() {
    return sessions.map((dto) => dto.toDomain()).toList();
  }
}

/// One entry of the `session.active_list` result (§4). `id` is a SHORT
/// live id.
@JsonSerializable()
class ActiveSessionDto {
  const ActiveSessionDto({
    this.id,
    this.status,
    this.current,
    this.model,
    this.title,
    this.preview,
    this.lastActive,
    this.messageCount,
  });

  factory ActiveSessionDto.fromJson(Map<String, dynamic> json) =>
      _$ActiveSessionDtoFromJson(json);

  @JsonKey(name: 'id')
  final String? id;

  /// `idle|starting|waiting|working`; parsed tolerantly in the mapper.
  @JsonKey(name: 'status')
  final String? status;

  /// Echoes the client-passed `current_session_id` (protocol §9: the
  /// gateway doesn't own "current").
  @JsonKey(name: 'current')
  final bool? current;

  @JsonKey(name: 'model')
  final String? model;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'preview')
  final String? preview;

  /// Epoch SECONDS on the wire.
  @JsonKey(name: 'last_active')
  final int? lastActive;

  @JsonKey(name: 'message_count')
  final int? messageCount;

  Map<String, dynamic> toJson() => _$ActiveSessionDtoToJson(this);

  ActiveSession toDomain() {
    return ActiveSession(
      liveId: id ?? '',
      status: SessionStatus.parse(status),
      model: model,
      title: title,
      preview: preview,
      lastActive: _epochSecondsToDateTime(lastActive),
      messageCount: messageCount,
      isCurrent: current ?? false,
    );
  }
}

/// `session.active_list` result (§4).
@JsonSerializable()
class ActiveSessionListResultDto {
  const ActiveSessionListResultDto({
    this.sessions = const <ActiveSessionDto>[],
  });

  factory ActiveSessionListResultDto.fromJson(Map<String, dynamic> json) =>
      _$ActiveSessionListResultDtoFromJson(json);

  @JsonKey(name: 'sessions')
  final List<ActiveSessionDto> sessions;

  Map<String, dynamic> toJson() => _$ActiveSessionListResultDtoToJson(this);

  List<ActiveSession> toDomain() {
    return sessions.map((dto) => dto.toDomain()).toList();
  }
}

/// One replayed message of the `session.resume` result (§5): `{role, text}`.
@JsonSerializable()
class ResumeMessageDto {
  const ResumeMessageDto({this.role, this.text});

  factory ResumeMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ResumeMessageDtoFromJson(json);

  @JsonKey(name: 'role')
  final String? role;

  @JsonKey(name: 'text')
  final String? text;

  Map<String, dynamic> toJson() => _$ResumeMessageDtoToJson(this);

  ChatMessage toDomain() {
    return ChatMessage(role: _parseRole(role), text: text ?? '');
  }
}

/// Inflight turn from `session.resume` (P2-02, §inflight).
@JsonSerializable()
class InflightTurnDto {
  const InflightTurnDto({this.user, this.assistant, this.streaming});

  factory InflightTurnDto.fromJson(Map<String, dynamic> json) =>
      _$InflightTurnDtoFromJson(json);

  @JsonKey(name: 'user')
  final String? user;

  @JsonKey(name: 'assistant')
  final String? assistant;

  @JsonKey(name: 'streaming')
  final bool? streaming;

  Map<String, dynamic> toJson() => _$InflightTurnDtoToJson(this);

  InflightTurn toDomain() {
    return InflightTurn(
      user: user ?? '',
      assistant: assistant ?? '',
      streaming: streaming ?? false,
    );
  }
}

/// `session.resume` result (§5).
@JsonSerializable()
class SessionResumeResultDto {
  const SessionResumeResultDto({
    this.sessionId,
    this.resumed,
    this.sessionKey,
    this.messages = const <ResumeMessageDto>[],
    this.messageCount,
    this.running,
    this.status,
    this.info,
    this.inflight,
  });

  factory SessionResumeResultDto.fromJson(Map<String, dynamic> json) =>
      _$SessionResumeResultDtoFromJson(json);

  /// NEW short live id.
  @JsonKey(name: 'session_id')
  final String? sessionId;

  /// The durable id that was passed in.
  @JsonKey(name: 'resumed')
  final String? resumed;

  /// Durable id echo.
  @JsonKey(name: 'session_key')
  final String? sessionKey;

  @JsonKey(name: 'messages')
  final List<ResumeMessageDto> messages;

  @JsonKey(name: 'message_count')
  final int? messageCount;

  @JsonKey(name: 'running')
  final bool? running;

  @JsonKey(name: 'status')
  final String? status;

  /// Opaque info dict — shape not pinned by the docs.
  final Map<String, dynamic>? info;

  /// Inflight turn (P2-02) — both null and missing treated as no inflight.
  @JsonKey(name: 'inflight')
  final InflightTurnDto? inflight;

  Map<String, dynamic> toJson() => _$SessionResumeResultDtoToJson(this);

  SessionResumeResult toDomain() {
    return SessionResumeResult(
      liveId: sessionId ?? '',
      durableId: sessionKey ?? resumed ?? '',
      messages: messages.map((dto) => dto.toDomain()).toList(),
      messageCount: messageCount ?? messages.length,
      running: running ?? false,
      status: SessionStatus.parse(status),
      info: info,
      inflight: inflight?.toDomain(),
    );
  }
}

/// Epoch seconds (wire) → [DateTime] (domain). UTC by definition of epoch.
DateTime? _epochSecondsToDateTime(int? epochSeconds) {
  if (epochSeconds == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true);
}

/// Wire role string → [MessageRole]. Unknown roles fall back to
/// [MessageRole.system] so they never render as user/assistant bubbles.
MessageRole _parseRole(String? role) {
  return switch (role) {
    'user' => MessageRole.user,
    'assistant' => MessageRole.assistant,
    _ => MessageRole.system,
  };
}

/// `session.usage` result (Phase 2, §session.usage).
@JsonSerializable()
class SessionUsageDto {
  const SessionUsageDto({
    this.model,
    this.input,
    this.output,
    this.total,
    this.calls,
    this.reasoning,
    this.contextUsed,
    this.contextMax,
    this.contextPercent,
    this.compressions,
  });

  factory SessionUsageDto.fromJson(Map<String, dynamic> json) =>
      _$SessionUsageDtoFromJson(json);

  @JsonKey(name: 'model')
  final String? model;

  @JsonKey(name: 'input')
  final int? input;

  @JsonKey(name: 'output')
  final int? output;

  @JsonKey(name: 'total')
  final int? total;

  @JsonKey(name: 'calls')
  final int? calls;

  @JsonKey(name: 'reasoning')
  final int? reasoning;

  @JsonKey(name: 'context_used')
  final int? contextUsed;

  @JsonKey(name: 'context_max')
  final int? contextMax;

  @JsonKey(name: 'context_percent')
  final int? contextPercent;

  @JsonKey(name: 'compressions')
  final int? compressions;

  Map<String, dynamic> toJson() => _$SessionUsageDtoToJson(this);

  SessionUsageStats toDomain() {
    return SessionUsageStats(
      model: model ?? '',
      input: input ?? 0,
      output: output ?? 0,
      total: total ?? 0,
      calls: calls ?? 0,
      reasoning: reasoning,
      contextUsed: contextUsed,
      contextMax: contextMax,
      contextPercent: contextPercent,
      compressions: compressions,
    );
  }
}

/// One category entry from `session.context_breakdown` (Phase 2).
@JsonSerializable()
class ContextCategoryDto {
  const ContextCategoryDto({this.id, this.label, this.tokens, this.color});

  factory ContextCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$ContextCategoryDtoFromJson(json);

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'tokens')
  final int? tokens;

  @JsonKey(name: 'color')
  final String? color;

  Map<String, dynamic> toJson() => _$ContextCategoryDtoToJson(this);

  ContextCategory toDomain() {
    return ContextCategory(
      id: id ?? '',
      label: label ?? '',
      tokens: tokens ?? 0,
      color: color ?? '',
    );
  }
}

/// `session.context_breakdown` result (Phase 2, §session.context_breakdown).
@JsonSerializable()
class ContextBreakdownDto {
  const ContextBreakdownDto({
    this.categories = const <ContextCategoryDto>[],
    this.contextMax,
    this.contextPercent,
    this.contextUsed,
    this.estimatedTotal,
    this.model,
  });

  factory ContextBreakdownDto.fromJson(Map<String, dynamic> json) =>
      _$ContextBreakdownDtoFromJson(json);

  @JsonKey(name: 'categories')
  final List<ContextCategoryDto> categories;

  @JsonKey(name: 'context_max')
  final int? contextMax;

  @JsonKey(name: 'context_percent')
  final int? contextPercent;

  @JsonKey(name: 'context_used')
  final int? contextUsed;

  @JsonKey(name: 'estimated_total')
  final int? estimatedTotal;

  @JsonKey(name: 'model')
  final String? model;

  Map<String, dynamic> toJson() => _$ContextBreakdownDtoToJson(this);

  ContextBreakdown toDomain() {
    return ContextBreakdown(
      categories: categories.map((dto) => dto.toDomain()).toList(),
      contextMax: contextMax ?? 0,
      contextPercent: contextPercent ?? 0,
      contextUsed: contextUsed ?? 0,
      estimatedTotal: estimatedTotal ?? 0,
      model: model ?? '',
    );
  }
}

/// `session.compress` result (Phase 2, §session.compress LOCAL success path).
///
/// Gateway 0.18→0.20 (docs/updates/gateway-0.18-to-0.20-required.md #1): the
/// result now carries `summary` (incl. its `aborted` flag — compression was
/// refused because a tool was mid-flight or the model declined), opaque
/// `usage` / `info` dicts, and the post-compression canonical `messages`
/// list (same shape `session.resume` returns).
@JsonSerializable()
class CompressResultDto {
  const CompressResultDto({
    this.status,
    this.removed,
    this.beforeMessages,
    this.afterMessages,
    this.beforeTokens,
    this.afterTokens,
    this.compressed,
    this.lockHeld,
    this.message,
    this.summary,
    this.usage,
    this.info,
    this.messages = const <ResumeMessageDto>[],
  });

  factory CompressResultDto.fromJson(Map<String, dynamic> json) =>
      _$CompressResultDtoFromJson(json);

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'removed')
  final int? removed;

  @JsonKey(name: 'before_messages')
  final int? beforeMessages;

  @JsonKey(name: 'after_messages')
  final int? afterMessages;

  @JsonKey(name: 'before_tokens')
  final int? beforeTokens;

  @JsonKey(name: 'after_tokens')
  final int? afterTokens;

  /// Lock-held detection (wire `compressed` bool).
  @JsonKey(name: 'compressed')
  final bool? compressed;

  @JsonKey(name: 'lock_held')
  final bool? lockHeld;

  @JsonKey(name: 'message')
  final String? message;

  /// Opaque compress summary dict (`{"aborted": bool, …}` — the other keys
  /// are not pinned by the docs).
  final Map<String, dynamic>? summary;

  /// Opaque session usage dict (same shape as `session.usage`).
  final Map<String, dynamic>? usage;

  /// Full `_session_info` dict — see `session.info` event payload
  /// (docs/reference/07-session-depth-wire-shapes.md).
  final Map<String, dynamic>? info;

  /// Canonical message list, post-compression (same shape `session.resume`
  /// returns — `_history_to_messages`).
  @JsonKey(name: 'messages')
  final List<ResumeMessageDto> messages;

  Map<String, dynamic> toJson() => _$CompressResultDtoToJson(this);

  CompressResult toDomain() {
    return CompressResult(
      status: status ?? '',
      removed: removed,
      beforeMessages: beforeMessages,
      afterMessages: afterMessages,
      beforeTokens: beforeTokens,
      afterTokens: afterTokens,
      lockHeld: lockHeld ?? false,
      message: message,
      summary: summary,
      usage: usage,
      info: info,
      messages: messages.map((dto) => dto.toDomain()).toList(),
      aborted: summary?['aborted'] == true || status == 'aborted',
    );
  }
}

/// `session.branch` result (Phase 2, §session.branch).
@JsonSerializable()
class BranchResultDto {
  const BranchResultDto({this.sessionId, this.title, this.parent});

  factory BranchResultDto.fromJson(Map<String, dynamic> json) =>
      _$BranchResultDtoFromJson(json);

  @JsonKey(name: 'session_id')
  final String? sessionId;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'parent')
  final String? parent;

  Map<String, dynamic> toJson() => _$BranchResultDtoToJson(this);

  BranchResult toDomain() {
    return BranchResult(
      liveId: sessionId ?? '',
      title: title ?? '',
      parentDurableId: parent ?? '',
    );
  }
}

/// `session.most_recent` result (Phase 2, §session.most_recent).
@JsonSerializable()
class MostRecentSessionDto {
  const MostRecentSessionDto({
    this.sessionId,
    this.title,
    this.startedAt,
    this.source,
  });

  factory MostRecentSessionDto.fromJson(Map<String, dynamic> json) =>
      _$MostRecentSessionDtoFromJson(json);

  @JsonKey(name: 'session_id')
  final String? sessionId;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'started_at')
  final int? startedAt;

  @JsonKey(name: 'source')
  final String? source;

  Map<String, dynamic> toJson() => _$MostRecentSessionDtoToJson(this);

  /// Returns null when sessionId is null (the "not found" wire shape).
  MostRecentSession? toDomainOrNull() {
    if (sessionId == null) {
      return null;
    }
    return MostRecentSession(
      durableId: sessionId!,
      title: title ?? '',
      startedAt: _epochSecondsToDateTime(startedAt),
      source: source ?? '',
    );
  }
}
