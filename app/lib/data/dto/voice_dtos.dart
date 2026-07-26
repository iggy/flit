/// DTOs for voice RPCs (ticket P7-05): voice.toggle, voice.record, voice.tts.
library;

import 'package:flit/domain/models/voice_state.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_dtos.g.dart';

/// DTO for `voice.toggle` result.
@JsonSerializable()
final class VoiceToggleResultDto {
  const VoiceToggleResultDto({
    this.enabled,
    @JsonKey(name: 'record_key') this.recordKey,
    this.tts,
    this.available,
    @JsonKey(name: 'audio_available') this.audioAvailable,
    @JsonKey(name: 'stt_available') this.sttAvailable,
    this.details,
  });

  factory VoiceToggleResultDto.fromJson(Map<String, dynamic> json) =>
      _$VoiceToggleResultDtoFromJson(json);

  final bool? enabled;
  final String? recordKey;
  final bool? tts;
  final bool? available;
  final bool? audioAvailable;
  final bool? sttAvailable;
  final String? details;

  Map<String, dynamic> toJson() => _$VoiceToggleResultDtoToJson(this);

  VoiceToggleResult toDomain() {
    return VoiceToggleResult(
      enabled: enabled ?? false,
      recordKey: recordKey ?? '',
      tts: tts ?? false,
      available: available,
      audioAvailable: audioAvailable,
      sttAvailable: sttAvailable,
      details: details,
    );
  }
}

/// DTO for `voice.record` result.
@JsonSerializable()
final class VoiceRecordResultDto {
  const VoiceRecordResultDto({this.status});

  factory VoiceRecordResultDto.fromJson(Map<String, dynamic> json) =>
      _$VoiceRecordResultDtoFromJson(json);

  final String? status;

  Map<String, dynamic> toJson() => _$VoiceRecordResultDtoToJson(this);

  VoiceRecordResult toDomain() {
    return VoiceRecordResult(status: status ?? '');
  }
}

/// DTO for `voice.tts` result.
@JsonSerializable()
final class VoiceTtsResultDto {
  const VoiceTtsResultDto({this.status});

  factory VoiceTtsResultDto.fromJson(Map<String, dynamic> json) =>
      _$VoiceTtsResultDtoFromJson(json);

  final String? status;

  Map<String, dynamic> toJson() => _$VoiceTtsResultDtoToJson(this);

  VoiceTtsResult toDomain() {
    return VoiceTtsResult(status: status ?? '');
  }
}
