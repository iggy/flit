// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tools_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolsListResultDto _$ToolsListResultDtoFromJson(Map<String, dynamic> json) =>
    ToolsListResultDto(
      toolsets:
          (json['toolsets'] as List<dynamic>?)
              ?.map((e) => ToolsetDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ToolsetDto>[],
    );

Map<String, dynamic> _$ToolsListResultDtoToJson(ToolsListResultDto instance) =>
    <String, dynamic>{'toolsets': instance.toolsets};

ToolsetDto _$ToolsetDtoFromJson(Map<String, dynamic> json) => ToolsetDto(
  name: json['name'] as String?,
  description: json['description'] as String?,
  toolCount: (json['tool_count'] as num?)?.toInt(),
  enabled: json['enabled'] as bool?,
  tools: (json['tools'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ToolsetDtoToJson(ToolsetDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'tool_count': instance.toolCount,
      'enabled': instance.enabled,
      'tools': instance.tools,
    };

ToolsShowResultDto _$ToolsShowResultDtoFromJson(Map<String, dynamic> json) =>
    ToolsShowResultDto(
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map(
                (e) => ToolShowSectionDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ToolShowSectionDto>[],
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ToolsShowResultDtoToJson(ToolsShowResultDto instance) =>
    <String, dynamic>{'sections': instance.sections, 'total': instance.total};

ToolShowSectionDto _$ToolShowSectionDtoFromJson(Map<String, dynamic> json) =>
    ToolShowSectionDto(
      name: json['name'] as String?,
      tools:
          (json['tools'] as List<dynamic>?)
              ?.map((e) => ToolInfoDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ToolInfoDto>[],
    );

Map<String, dynamic> _$ToolShowSectionDtoToJson(ToolShowSectionDto instance) =>
    <String, dynamic>{'name': instance.name, 'tools': instance.tools};

ToolInfoDto _$ToolInfoDtoFromJson(Map<String, dynamic> json) => ToolInfoDto(
  name: json['name'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ToolInfoDtoToJson(ToolInfoDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };

ToolsConfigureResultDto _$ToolsConfigureResultDtoFromJson(
  Map<String, dynamic> json,
) => ToolsConfigureResultDto(
  changed:
      (json['changed'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  enabledToolsets:
      (json['enabled_toolsets'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  missingServers:
      (json['missing_servers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  reset: json['reset'] as bool?,
  unknown:
      (json['unknown'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  info: json['info'],
);

Map<String, dynamic> _$ToolsConfigureResultDtoToJson(
  ToolsConfigureResultDto instance,
) => <String, dynamic>{
  'changed': instance.changed,
  'enabled_toolsets': instance.enabledToolsets,
  'missing_servers': instance.missingServers,
  'reset': instance.reset,
  'unknown': instance.unknown,
  'info': instance.info,
};
