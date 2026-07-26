// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceToggleResultDto _$VoiceToggleResultDtoFromJson(
  Map<String, dynamic> json,
) => VoiceToggleResultDto(
  enabled: json['enabled'] as bool?,
  recordKey: json['record_key'] as String?,
  tts: json['tts'] as bool?,
  available: json['available'] as bool?,
  audioAvailable: json['audio_available'] as bool?,
  sttAvailable: json['stt_available'] as bool?,
  details: json['details'] as String?,
);

Map<String, dynamic> _$VoiceToggleResultDtoToJson(
  VoiceToggleResultDto instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'record_key': instance.recordKey,
  'tts': instance.tts,
  'available': instance.available,
  'audio_available': instance.audioAvailable,
  'stt_available': instance.sttAvailable,
  'details': instance.details,
};

VoiceRecordResultDto _$VoiceRecordResultDtoFromJson(
  Map<String, dynamic> json,
) => VoiceRecordResultDto(status: json['status'] as String?);

Map<String, dynamic> _$VoiceRecordResultDtoToJson(
  VoiceRecordResultDto instance,
) => <String, dynamic>{'status': instance.status};

VoiceTtsResultDto _$VoiceTtsResultDtoFromJson(Map<String, dynamic> json) =>
    VoiceTtsResultDto(status: json['status'] as String?);

Map<String, dynamic> _$VoiceTtsResultDtoToJson(VoiceTtsResultDto instance) =>
    <String, dynamic>{'status': instance.status};
