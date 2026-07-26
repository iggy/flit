import 'package:flit/domain/models/rollback.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rollback_dtos.g.dart';

/// Wire DTO for a single checkpoint entry.
@JsonSerializable()
class CheckpointDto {
  const CheckpointDto({this.hash, this.timestamp, this.message});

  factory CheckpointDto.fromJson(Map<String, dynamic> json) =>
      _$CheckpointDtoFromJson(json);

  @JsonKey(name: 'hash')
  final String? hash;

  @JsonKey(name: 'timestamp')
  final String? timestamp;

  @JsonKey(name: 'message')
  final String? message;

  Map<String, dynamic> toJson() => _$CheckpointDtoToJson(this);

  Checkpoint toDomain() {
    return Checkpoint(
      hash: hash ?? '',
      timestamp: timestamp ?? '',
      message: message ?? '',
    );
  }
}

/// Wire DTO for `rollback.list` result.
@JsonSerializable()
class RollbackListResultDto {
  const RollbackListResultDto({
    this.enabled,
    this.checkpoints = const <CheckpointDto>[],
  });

  factory RollbackListResultDto.fromJson(Map<String, dynamic> json) =>
      _$RollbackListResultDtoFromJson(json);

  @JsonKey(name: 'enabled')
  final bool? enabled;

  @JsonKey(name: 'checkpoints')
  final List<CheckpointDto> checkpoints;

  Map<String, dynamic> toJson() => _$RollbackListResultDtoToJson(this);

  CheckpointList toDomain() {
    return CheckpointList(
      enabled: enabled ?? false,
      checkpoints: checkpoints.map((dto) => dto.toDomain()).toList(),
    );
  }
}

/// Wire DTO for `rollback.diff` result.
@JsonSerializable()
class RollbackDiffResultDto {
  const RollbackDiffResultDto({this.stat, this.diff});

  factory RollbackDiffResultDto.fromJson(Map<String, dynamic> json) =>
      _$RollbackDiffResultDtoFromJson(json);

  @JsonKey(name: 'stat')
  final String? stat;

  @JsonKey(name: 'diff')
  final String? diff;

  Map<String, dynamic> toJson() => _$RollbackDiffResultDtoToJson(this);

  CheckpointDiff toDomain() {
    return CheckpointDiff(stat: stat ?? '', diff: diff ?? '');
  }
}

/// Wire DTO for `rollback.restore` result.
@JsonSerializable()
class RollbackRestoreResultDto {
  const RollbackRestoreResultDto({
    this.success,
    this.restoredTo,
    this.reason,
    this.directory,
    this.file,
    this.historyRemoved,
    this.error,
  });

  factory RollbackRestoreResultDto.fromJson(Map<String, dynamic> json) =>
      _$RollbackRestoreResultDtoFromJson(json);

  @JsonKey(name: 'success')
  final bool? success;

  @JsonKey(name: 'restored_to')
  final String? restoredTo;

  @JsonKey(name: 'reason')
  final String? reason;

  @JsonKey(name: 'directory')
  final String? directory;

  @JsonKey(name: 'file')
  final String? file;

  @JsonKey(name: 'history_removed')
  final int? historyRemoved;

  @JsonKey(name: 'error')
  final String? error;

  Map<String, dynamic> toJson() => _$RollbackRestoreResultDtoToJson(this);

  RestoreResult toDomain() {
    return RestoreResult(
      success: success ?? false,
      restoredTo: restoredTo,
      reason: reason,
      directory: directory,
      file: file,
      historyRemoved: historyRemoved,
      error: error,
    );
  }
}
