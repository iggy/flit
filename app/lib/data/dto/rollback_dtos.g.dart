// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rollback_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointDto _$CheckpointDtoFromJson(Map<String, dynamic> json) =>
    CheckpointDto(
      hash: json['hash'] as String?,
      timestamp: json['timestamp'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$CheckpointDtoToJson(CheckpointDto instance) =>
    <String, dynamic>{
      'hash': instance.hash,
      'timestamp': instance.timestamp,
      'message': instance.message,
    };

RollbackListResultDto _$RollbackListResultDtoFromJson(
  Map<String, dynamic> json,
) => RollbackListResultDto(
  enabled: json['enabled'] as bool?,
  checkpoints:
      (json['checkpoints'] as List<dynamic>?)
          ?.map((e) => CheckpointDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CheckpointDto>[],
);

Map<String, dynamic> _$RollbackListResultDtoToJson(
  RollbackListResultDto instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'checkpoints': instance.checkpoints,
};

RollbackDiffResultDto _$RollbackDiffResultDtoFromJson(
  Map<String, dynamic> json,
) => RollbackDiffResultDto(
  stat: json['stat'] as String?,
  diff: json['diff'] as String?,
);

Map<String, dynamic> _$RollbackDiffResultDtoToJson(
  RollbackDiffResultDto instance,
) => <String, dynamic>{'stat': instance.stat, 'diff': instance.diff};

RollbackRestoreResultDto _$RollbackRestoreResultDtoFromJson(
  Map<String, dynamic> json,
) => RollbackRestoreResultDto(
  success: json['success'] as bool?,
  restoredTo: json['restored_to'] as String?,
  reason: json['reason'] as String?,
  directory: json['directory'] as String?,
  file: json['file'] as String?,
  historyRemoved: (json['history_removed'] as num?)?.toInt(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$RollbackRestoreResultDtoToJson(
  RollbackRestoreResultDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'restored_to': instance.restoredTo,
  'reason': instance.reason,
  'directory': instance.directory,
  'file': instance.file,
  'history_removed': instance.historyRemoved,
  'error': instance.error,
};
