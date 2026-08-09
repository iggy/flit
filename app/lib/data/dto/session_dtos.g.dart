// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionCreateResultDto _$SessionCreateResultDtoFromJson(
  Map<String, dynamic> json,
) => SessionCreateResultDto(
  sessionId: json['session_id'] as String?,
  storedSessionId: json['stored_session_id'] as String?,
  sessionKey: json['session_key'] as String?,
  info: json['info'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SessionCreateResultDtoToJson(
  SessionCreateResultDto instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'stored_session_id': instance.storedSessionId,
  'session_key': instance.sessionKey,
  'info': instance.info,
};

SessionSummaryDto _$SessionSummaryDtoFromJson(Map<String, dynamic> json) =>
    SessionSummaryDto(
      id: json['id'] as String?,
      title: json['title'] as String?,
      preview: json['preview'] as String?,
      messageCount: (json['message_count'] as num?)?.toInt(),
      startedAt: (json['started_at'] as num?)?.toInt(),
      source: json['source'] as String?,
    );

Map<String, dynamic> _$SessionSummaryDtoToJson(SessionSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'preview': instance.preview,
      'message_count': instance.messageCount,
      'started_at': instance.startedAt,
      'source': instance.source,
    };

SessionListResultDto _$SessionListResultDtoFromJson(
  Map<String, dynamic> json,
) => SessionListResultDto(
  sessions:
      (json['sessions'] as List<dynamic>?)
          ?.map((e) => SessionSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SessionSummaryDto>[],
);

Map<String, dynamic> _$SessionListResultDtoToJson(
  SessionListResultDto instance,
) => <String, dynamic>{'sessions': instance.sessions};

ActiveSessionDto _$ActiveSessionDtoFromJson(Map<String, dynamic> json) =>
    ActiveSessionDto(
      id: json['id'] as String?,
      status: json['status'] as String?,
      current: json['current'] as bool?,
      model: json['model'] as String?,
      title: json['title'] as String?,
      preview: json['preview'] as String?,
      lastActive: (json['last_active'] as num?)?.toInt(),
      messageCount: (json['message_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ActiveSessionDtoToJson(ActiveSessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'current': instance.current,
      'model': instance.model,
      'title': instance.title,
      'preview': instance.preview,
      'last_active': instance.lastActive,
      'message_count': instance.messageCount,
    };

ActiveSessionListResultDto _$ActiveSessionListResultDtoFromJson(
  Map<String, dynamic> json,
) => ActiveSessionListResultDto(
  sessions:
      (json['sessions'] as List<dynamic>?)
          ?.map((e) => ActiveSessionDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ActiveSessionDto>[],
);

Map<String, dynamic> _$ActiveSessionListResultDtoToJson(
  ActiveSessionListResultDto instance,
) => <String, dynamic>{'sessions': instance.sessions};

ResumeMessageDto _$ResumeMessageDtoFromJson(Map<String, dynamic> json) =>
    ResumeMessageDto(
      role: json['role'] as String?,
      text: json['text'] as String?,
    );

Map<String, dynamic> _$ResumeMessageDtoToJson(ResumeMessageDto instance) =>
    <String, dynamic>{'role': instance.role, 'text': instance.text};

InflightTurnDto _$InflightTurnDtoFromJson(Map<String, dynamic> json) =>
    InflightTurnDto(
      user: json['user'] as String?,
      assistant: json['assistant'] as String?,
      streaming: json['streaming'] as bool?,
    );

Map<String, dynamic> _$InflightTurnDtoToJson(InflightTurnDto instance) =>
    <String, dynamic>{
      'user': instance.user,
      'assistant': instance.assistant,
      'streaming': instance.streaming,
    };

AutoContinueDto _$AutoContinueDtoFromJson(Map<String, dynamic> json) =>
    AutoContinueDto(
      attempt: (json['attempt'] as num?)?.toInt(),
      interruptedAt: (json['interrupted_at'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AutoContinueDtoToJson(AutoContinueDto instance) =>
    <String, dynamic>{
      'attempt': instance.attempt,
      'interrupted_at': instance.interruptedAt,
    };

SessionResumeResultDto _$SessionResumeResultDtoFromJson(
  Map<String, dynamic> json,
) => SessionResumeResultDto(
  sessionId: json['session_id'] as String?,
  resumed: json['resumed'] as String?,
  sessionKey: json['session_key'] as String?,
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => ResumeMessageDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResumeMessageDto>[],
  messageCount: (json['message_count'] as num?)?.toInt(),
  messagesOmitted: json['messages_omitted'] as bool?,
  running: json['running'] as bool?,
  status: json['status'] as String?,
  info: json['info'] as Map<String, dynamic>?,
  inflight: json['inflight'] == null
      ? null
      : InflightTurnDto.fromJson(json['inflight'] as Map<String, dynamic>),
  autoContinue: json['auto_continue'] == null
      ? null
      : AutoContinueDto.fromJson(json['auto_continue'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SessionResumeResultDtoToJson(
  SessionResumeResultDto instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'resumed': instance.resumed,
  'session_key': instance.sessionKey,
  'messages': instance.messages,
  'message_count': instance.messageCount,
  'messages_omitted': instance.messagesOmitted,
  'running': instance.running,
  'status': instance.status,
  'info': instance.info,
  'inflight': instance.inflight,
  'auto_continue': instance.autoContinue,
};

SessionUsageDto _$SessionUsageDtoFromJson(Map<String, dynamic> json) =>
    SessionUsageDto(
      model: json['model'] as String?,
      input: (json['input'] as num?)?.toInt(),
      output: (json['output'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      calls: (json['calls'] as num?)?.toInt(),
      reasoning: (json['reasoning'] as num?)?.toInt(),
      contextUsed: (json['context_used'] as num?)?.toInt(),
      contextMax: (json['context_max'] as num?)?.toInt(),
      contextPercent: (json['context_percent'] as num?)?.toInt(),
      compressions: (json['compressions'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SessionUsageDtoToJson(SessionUsageDto instance) =>
    <String, dynamic>{
      'model': instance.model,
      'input': instance.input,
      'output': instance.output,
      'total': instance.total,
      'calls': instance.calls,
      'reasoning': instance.reasoning,
      'context_used': instance.contextUsed,
      'context_max': instance.contextMax,
      'context_percent': instance.contextPercent,
      'compressions': instance.compressions,
    };

ContextCategoryDto _$ContextCategoryDtoFromJson(Map<String, dynamic> json) =>
    ContextCategoryDto(
      id: json['id'] as String?,
      label: json['label'] as String?,
      tokens: (json['tokens'] as num?)?.toInt(),
      color: json['color'] as String?,
    );

Map<String, dynamic> _$ContextCategoryDtoToJson(ContextCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'tokens': instance.tokens,
      'color': instance.color,
    };

ContextBreakdownDto _$ContextBreakdownDtoFromJson(Map<String, dynamic> json) =>
    ContextBreakdownDto(
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map(
                (e) => ContextCategoryDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ContextCategoryDto>[],
      contextMax: (json['context_max'] as num?)?.toInt(),
      contextPercent: (json['context_percent'] as num?)?.toInt(),
      contextUsed: (json['context_used'] as num?)?.toInt(),
      estimatedTotal: (json['estimated_total'] as num?)?.toInt(),
      model: json['model'] as String?,
    );

Map<String, dynamic> _$ContextBreakdownDtoToJson(
  ContextBreakdownDto instance,
) => <String, dynamic>{
  'categories': instance.categories,
  'context_max': instance.contextMax,
  'context_percent': instance.contextPercent,
  'context_used': instance.contextUsed,
  'estimated_total': instance.estimatedTotal,
  'model': instance.model,
};

CompressResultDto _$CompressResultDtoFromJson(Map<String, dynamic> json) =>
    CompressResultDto(
      status: json['status'] as String?,
      removed: (json['removed'] as num?)?.toInt(),
      beforeMessages: (json['before_messages'] as num?)?.toInt(),
      afterMessages: (json['after_messages'] as num?)?.toInt(),
      beforeTokens: (json['before_tokens'] as num?)?.toInt(),
      afterTokens: (json['after_tokens'] as num?)?.toInt(),
      compressed: json['compressed'] as bool?,
      lockHeld: json['lock_held'] as bool?,
      message: json['message'] as String?,
      summary: json['summary'] as Map<String, dynamic>?,
      usage: json['usage'] as Map<String, dynamic>?,
      info: json['info'] as Map<String, dynamic>?,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => ResumeMessageDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ResumeMessageDto>[],
    );

Map<String, dynamic> _$CompressResultDtoToJson(CompressResultDto instance) =>
    <String, dynamic>{
      'status': instance.status,
      'removed': instance.removed,
      'before_messages': instance.beforeMessages,
      'after_messages': instance.afterMessages,
      'before_tokens': instance.beforeTokens,
      'after_tokens': instance.afterTokens,
      'compressed': instance.compressed,
      'lock_held': instance.lockHeld,
      'message': instance.message,
      'summary': instance.summary,
      'usage': instance.usage,
      'info': instance.info,
      'messages': instance.messages,
    };

BranchResultDto _$BranchResultDtoFromJson(Map<String, dynamic> json) =>
    BranchResultDto(
      sessionId: json['session_id'] as String?,
      title: json['title'] as String?,
      parent: json['parent'] as String?,
    );

Map<String, dynamic> _$BranchResultDtoToJson(BranchResultDto instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'title': instance.title,
      'parent': instance.parent,
    };

MostRecentSessionDto _$MostRecentSessionDtoFromJson(
  Map<String, dynamic> json,
) => MostRecentSessionDto(
  sessionId: json['session_id'] as String?,
  title: json['title'] as String?,
  startedAt: (json['started_at'] as num?)?.toInt(),
  source: json['source'] as String?,
);

Map<String, dynamic> _$MostRecentSessionDtoToJson(
  MostRecentSessionDto instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'title': instance.title,
  'started_at': instance.startedAt,
  'source': instance.source,
};
