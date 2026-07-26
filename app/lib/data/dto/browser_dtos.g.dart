// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrowserManageResultDto _$BrowserManageResultDtoFromJson(
  Map<String, dynamic> json,
) => BrowserManageResultDto(
  connected: json['connected'] as bool?,
  url: json['url'] as String?,
  messages: (json['messages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$BrowserManageResultDtoToJson(
  BrowserManageResultDto instance,
) => <String, dynamic>{
  'connected': instance.connected,
  'url': instance.url,
  'messages': instance.messages,
};

PreviewRestartResultDto _$PreviewRestartResultDtoFromJson(
  Map<String, dynamic> json,
) => PreviewRestartResultDto(taskId: json['task_id'] as String?);

Map<String, dynamic> _$PreviewRestartResultDtoToJson(
  PreviewRestartResultDto instance,
) => <String, dynamic>{'task_id': instance.taskId};
