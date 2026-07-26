import 'package:flit/domain/models/background_process.dart';
import 'package:json_annotation/json_annotation.dart';

part 'process_dtos.g.dart';

/// Wire DTO for `process.list` result.
@JsonSerializable()
class ProcessListResultDto {
  const ProcessListResultDto({this.processes = const <BackgroundProcessDto>[]});

  factory ProcessListResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProcessListResultDtoFromJson(json);

  @JsonKey(name: 'processes')
  final List<BackgroundProcessDto> processes;

  Map<String, dynamic> toJson() => _$ProcessListResultDtoToJson(this);

  List<BackgroundProcess> toDomain() {
    return processes.map((dto) => dto.toDomain()).toList();
  }
}

/// One process entry from `process.list`.
@JsonSerializable()
class BackgroundProcessDto {
  const BackgroundProcessDto({
    this.sessionId,
    this.command,
    this.cwd,
    this.pid,
    this.startedAt,
    this.uptimeSeconds,
    this.status,
    this.outputTail,
    this.outputPreview,
    this.exitCode,
  });

  factory BackgroundProcessDto.fromJson(Map<String, dynamic> json) =>
      _$BackgroundProcessDtoFromJson(json);

  @JsonKey(name: 'session_id')
  final String? sessionId;

  @JsonKey(name: 'command')
  final String? command;

  @JsonKey(name: 'cwd')
  final String? cwd;

  @JsonKey(name: 'pid')
  final int? pid;

  @JsonKey(name: 'started_at')
  final String? startedAt;

  @JsonKey(name: 'uptime_seconds')
  final int? uptimeSeconds;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'output_tail')
  final String? outputTail;

  @JsonKey(name: 'output_preview')
  final String? outputPreview;

  @JsonKey(name: 'exit_code')
  final int? exitCode;

  Map<String, dynamic> toJson() => _$BackgroundProcessDtoToJson(this);

  BackgroundProcess toDomain() {
    return BackgroundProcess(
      processId: sessionId ?? '',
      command: command,
      cwd: cwd,
      pid: pid,
      startedAt: startedAt,
      uptimeSeconds: uptimeSeconds,
      status: status,
      outputTail: outputTail,
      outputPreview: outputPreview,
      exitCode: exitCode,
    );
  }
}

/// Wire DTO for `process.kill` result (polymorphic keyed by status).
@JsonSerializable()
class ProcessKillResultDto {
  const ProcessKillResultDto({this.status, this.output, this.error});

  factory ProcessKillResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProcessKillResultDtoFromJson(json);

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'output')
  final String? output;

  @JsonKey(name: 'error')
  final String? error;

  Map<String, dynamic> toJson() => _$ProcessKillResultDtoToJson(this);

  ProcessKillResult toDomain() {
    return ProcessKillResult(
      status: status ?? 'unknown',
      output: output,
      error: error,
    );
  }
}

/// Wire DTO for `process.stop` result.
@JsonSerializable()
class ProcessStopResultDto {
  const ProcessStopResultDto({this.killed});

  factory ProcessStopResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProcessStopResultDtoFromJson(json);

  @JsonKey(name: 'killed')
  final int? killed;

  Map<String, dynamic> toJson() => _$ProcessStopResultDtoToJson(this);

  int toDomain() {
    return killed ?? 0;
  }
}

/// Wire DTO for `shell.exec` result.
@JsonSerializable()
class ShellExecResultDto {
  const ShellExecResultDto({this.stdout, this.stderr, this.code});

  factory ShellExecResultDto.fromJson(Map<String, dynamic> json) =>
      _$ShellExecResultDtoFromJson(json);

  @JsonKey(name: 'stdout')
  final String? stdout;

  @JsonKey(name: 'stderr')
  final String? stderr;

  @JsonKey(name: 'code')
  final int? code;

  Map<String, dynamic> toJson() => _$ShellExecResultDtoToJson(this);

  ShellExecResult toDomain() {
    return ShellExecResult(
      stdout: stdout ?? '',
      stderr: stderr ?? '',
      code: code ?? 0,
    );
  }
}
