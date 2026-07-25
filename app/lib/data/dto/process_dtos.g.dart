// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessListResultDto _$ProcessListResultDtoFromJson(
  Map<String, dynamic> json,
) => ProcessListResultDto(
  processes:
      (json['processes'] as List<dynamic>?)
          ?.map((e) => BackgroundProcessDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BackgroundProcessDto>[],
);

Map<String, dynamic> _$ProcessListResultDtoToJson(
  ProcessListResultDto instance,
) => <String, dynamic>{'processes': instance.processes};

BackgroundProcessDto _$BackgroundProcessDtoFromJson(
  Map<String, dynamic> json,
) => BackgroundProcessDto(
  sessionId: json['session_id'] as String?,
  command: json['command'] as String?,
  cwd: json['cwd'] as String?,
  pid: (json['pid'] as num?)?.toInt(),
  startedAt: json['started_at'] as String?,
  uptimeSeconds: (json['uptime_seconds'] as num?)?.toInt(),
  status: json['status'] as String?,
  outputTail: json['output_tail'] as String?,
  outputPreview: json['output_preview'] as String?,
  exitCode: (json['exit_code'] as num?)?.toInt(),
);

Map<String, dynamic> _$BackgroundProcessDtoToJson(
  BackgroundProcessDto instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'command': instance.command,
  'cwd': instance.cwd,
  'pid': instance.pid,
  'started_at': instance.startedAt,
  'uptime_seconds': instance.uptimeSeconds,
  'status': instance.status,
  'output_tail': instance.outputTail,
  'output_preview': instance.outputPreview,
  'exit_code': instance.exitCode,
};

ProcessKillResultDto _$ProcessKillResultDtoFromJson(
  Map<String, dynamic> json,
) => ProcessKillResultDto(
  status: json['status'] as String?,
  output: json['output'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$ProcessKillResultDtoToJson(
  ProcessKillResultDto instance,
) => <String, dynamic>{
  'status': instance.status,
  'output': instance.output,
  'error': instance.error,
};

ProcessStopResultDto _$ProcessStopResultDtoFromJson(
  Map<String, dynamic> json,
) => ProcessStopResultDto(killed: (json['killed'] as num?)?.toInt());

Map<String, dynamic> _$ProcessStopResultDtoToJson(
  ProcessStopResultDto instance,
) => <String, dynamic>{'killed': instance.killed};

ShellExecResultDto _$ShellExecResultDtoFromJson(Map<String, dynamic> json) =>
    ShellExecResultDto(
      stdout: json['stdout'] as String?,
      stderr: json['stderr'] as String?,
      code: (json['code'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShellExecResultDtoToJson(ShellExecResultDto instance) =>
    <String, dynamic>{
      'stdout': instance.stdout,
      'stderr': instance.stderr,
      'code': instance.code,
    };
