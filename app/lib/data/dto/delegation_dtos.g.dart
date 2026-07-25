// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationStatusResultDto _$DelegationStatusResultDtoFromJson(
  Map<String, dynamic> json,
) => DelegationStatusResultDto(
  active:
      (json['active'] as List<dynamic>?)
          ?.map((e) => ActiveSubagentDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ActiveSubagentDto>[],
  paused: json['paused'] as bool?,
  maxSpawnDepth: (json['max_spawn_depth'] as num?)?.toInt(),
  maxConcurrentChildren: (json['max_concurrent_children'] as num?)?.toInt(),
);

Map<String, dynamic> _$DelegationStatusResultDtoToJson(
  DelegationStatusResultDto instance,
) => <String, dynamic>{
  'active': instance.active,
  'paused': instance.paused,
  'max_spawn_depth': instance.maxSpawnDepth,
  'max_concurrent_children': instance.maxConcurrentChildren,
};

ActiveSubagentDto _$ActiveSubagentDtoFromJson(Map<String, dynamic> json) =>
    ActiveSubagentDto(
      subagentId: json['subagent_id'] as String?,
      parentId: json['parent_id'] as String?,
      depth: (json['depth'] as num?)?.toInt(),
      goal: json['goal'] as String?,
      model: json['model'] as String?,
      startedAt: json['started_at'] as num?,
      status: json['status'] as String?,
      toolCount: (json['tool_count'] as num?)?.toInt(),
      lastTool: json['last_tool'] as String?,
    );

Map<String, dynamic> _$ActiveSubagentDtoToJson(ActiveSubagentDto instance) =>
    <String, dynamic>{
      'subagent_id': instance.subagentId,
      'parent_id': instance.parentId,
      'depth': instance.depth,
      'goal': instance.goal,
      'model': instance.model,
      'started_at': instance.startedAt,
      'status': instance.status,
      'tool_count': instance.toolCount,
      'last_tool': instance.lastTool,
    };

DelegationPauseResultDto _$DelegationPauseResultDtoFromJson(
  Map<String, dynamic> json,
) => DelegationPauseResultDto(paused: json['paused'] as bool?);

Map<String, dynamic> _$DelegationPauseResultDtoToJson(
  DelegationPauseResultDto instance,
) => <String, dynamic>{'paused': instance.paused};

SubagentInterruptResultDto _$SubagentInterruptResultDtoFromJson(
  Map<String, dynamic> json,
) => SubagentInterruptResultDto(
  found: json['found'] as bool?,
  subagentId: json['subagent_id'] as String?,
);

Map<String, dynamic> _$SubagentInterruptResultDtoToJson(
  SubagentInterruptResultDto instance,
) => <String, dynamic>{
  'found': instance.found,
  'subagent_id': instance.subagentId,
};

AgentsListResultDto _$AgentsListResultDtoFromJson(Map<String, dynamic> json) =>
    AgentsListResultDto(
      processes:
          (json['processes'] as List<dynamic>?)
              ?.map((e) => AgentProcessDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AgentProcessDto>[],
    );

Map<String, dynamic> _$AgentsListResultDtoToJson(
  AgentsListResultDto instance,
) => <String, dynamic>{'processes': instance.processes};

AgentProcessDto _$AgentProcessDtoFromJson(Map<String, dynamic> json) =>
    AgentProcessDto(
      sessionId: json['session_id'] as String?,
      command: json['command'] as String?,
      status: json['status'] as String?,
      uptime: json['uptime'] as num?,
    );

Map<String, dynamic> _$AgentProcessDtoToJson(AgentProcessDto instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'command': instance.command,
      'status': instance.status,
      'uptime': instance.uptime,
    };
