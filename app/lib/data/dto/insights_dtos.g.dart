// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsightsResultDto _$InsightsResultDtoFromJson(Map<String, dynamic> json) =>
    InsightsResultDto(
      days: (json['days'] as num?)?.toInt(),
      sessions: (json['sessions'] as num?)?.toInt(),
      messages: (json['messages'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InsightsResultDtoToJson(InsightsResultDto instance) =>
    <String, dynamic>{
      'days': instance.days,
      'sessions': instance.sessions,
      'messages': instance.messages,
    };
