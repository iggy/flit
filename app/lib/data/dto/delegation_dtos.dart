import 'package:flit/domain/models/agent_process.dart';
import 'package:flit/domain/models/delegation_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delegation_dtos.g.dart';

/// Wire DTO for `delegation.status` result
/// (docs/reference/08-agent-transparency-wire-shapes.md §delegation.status).
@JsonSerializable()
class DelegationStatusResultDto {
  const DelegationStatusResultDto({
    this.active = const <ActiveSubagentDto>[],
    this.paused,
    this.maxSpawnDepth,
    this.maxConcurrentChildren,
  });

  factory DelegationStatusResultDto.fromJson(Map<String, dynamic> json) =>
      _$DelegationStatusResultDtoFromJson(json);

  @JsonKey(name: 'active')
  final List<ActiveSubagentDto> active;

  @JsonKey(name: 'paused')
  final bool? paused;

  @JsonKey(name: 'max_spawn_depth')
  final int? maxSpawnDepth;

  @JsonKey(name: 'max_concurrent_children')
  final int? maxConcurrentChildren;

  Map<String, dynamic> toJson() => _$DelegationStatusResultDtoToJson(this);

  DelegationStatus toDomain() {
    return DelegationStatus(
      active: active.map((dto) => dto.toDomain()).toList(),
      paused: paused ?? false,
      maxSpawnDepth: maxSpawnDepth ?? 0,
      maxConcurrentChildren: maxConcurrentChildren ?? 0,
    );
  }
}

/// One active subagent entry from `delegation.status`.
@JsonSerializable()
class ActiveSubagentDto {
  const ActiveSubagentDto({
    this.subagentId,
    this.parentId,
    this.depth,
    this.goal,
    this.model,
    this.startedAt,
    this.status,
    this.toolCount,
    this.lastTool,
  });

  factory ActiveSubagentDto.fromJson(Map<String, dynamic> json) =>
      _$ActiveSubagentDtoFromJson(json);

  @JsonKey(name: 'subagent_id')
  final String? subagentId;

  @JsonKey(name: 'parent_id')
  final String? parentId;

  @JsonKey(name: 'depth')
  final int? depth;

  @JsonKey(name: 'goal')
  final String? goal;

  @JsonKey(name: 'model')
  final String? model;

  @JsonKey(name: 'started_at')
  final num? startedAt;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'tool_count')
  final int? toolCount;

  @JsonKey(name: 'last_tool')
  final String? lastTool;

  Map<String, dynamic> toJson() => _$ActiveSubagentDtoToJson(this);

  ActiveSubagent toDomain() {
    return ActiveSubagent(
      id: subagentId ?? '',
      parentId: parentId,
      depth: depth ?? 0,
      goal: goal ?? '',
      model: model,
      startedAt: (startedAt ?? 0).toDouble(),
      status: status ?? '',
      toolCount: toolCount ?? 0,
      lastTool: lastTool,
    );
  }
}

/// Wire DTO for `delegation.pause` result.
@JsonSerializable()
class DelegationPauseResultDto {
  const DelegationPauseResultDto({this.paused});

  factory DelegationPauseResultDto.fromJson(Map<String, dynamic> json) =>
      _$DelegationPauseResultDtoFromJson(json);

  @JsonKey(name: 'paused')
  final bool? paused;

  Map<String, dynamic> toJson() => _$DelegationPauseResultDtoToJson(this);
}

/// Wire DTO for `subagent.interrupt` result.
@JsonSerializable()
class SubagentInterruptResultDto {
  const SubagentInterruptResultDto({this.found, this.subagentId});

  factory SubagentInterruptResultDto.fromJson(Map<String, dynamic> json) =>
      _$SubagentInterruptResultDtoFromJson(json);

  @JsonKey(name: 'found')
  final bool? found;

  @JsonKey(name: 'subagent_id')
  final String? subagentId;

  Map<String, dynamic> toJson() => _$SubagentInterruptResultDtoToJson(this);
}

/// Wire DTO for `agents.list` result.
@JsonSerializable()
class AgentsListResultDto {
  const AgentsListResultDto({this.processes = const <AgentProcessDto>[]});

  factory AgentsListResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentsListResultDtoFromJson(json);

  @JsonKey(name: 'processes')
  final List<AgentProcessDto> processes;

  Map<String, dynamic> toJson() => _$AgentsListResultDtoToJson(this);

  List<AgentProcess> toDomain() {
    return processes.map((dto) => dto.toDomain()).toList();
  }
}

/// One agent process entry from `agents.list`.
@JsonSerializable()
class AgentProcessDto {
  const AgentProcessDto({
    this.sessionId,
    this.command,
    this.status,
    this.uptime,
  });

  factory AgentProcessDto.fromJson(Map<String, dynamic> json) =>
      _$AgentProcessDtoFromJson(json);

  @JsonKey(name: 'session_id')
  final String? sessionId;

  @JsonKey(name: 'command')
  final String? command;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'uptime')
  final num? uptime;

  Map<String, dynamic> toJson() => _$AgentProcessDtoToJson(this);

  AgentProcess toDomain() {
    return AgentProcess(
      sessionId: sessionId ?? '',
      command: command ?? '',
      status: status ?? '',
      uptime: (uptime ?? 0).toDouble(),
    );
  }
}
