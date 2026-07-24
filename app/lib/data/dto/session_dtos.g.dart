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
  running: json['running'] as bool?,
  status: json['status'] as String?,
  info: json['info'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SessionResumeResultDtoToJson(
  SessionResumeResultDto instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'resumed': instance.resumed,
  'session_key': instance.sessionKey,
  'messages': instance.messages,
  'message_count': instance.messageCount,
  'running': instance.running,
  'status': instance.status,
  'info': instance.info,
};
