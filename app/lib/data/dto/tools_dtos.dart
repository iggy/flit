import 'package:flit/domain/models/tool_catalog.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tools_dtos.g.dart';

/// Wire DTO for `tools.list` and `toolsets.list` results.
@JsonSerializable()
class ToolsListResultDto {
  const ToolsListResultDto({
    this.toolsets = const <ToolsetDto>[],
  });

  factory ToolsListResultDto.fromJson(Map<String, dynamic> json) =>
      _$ToolsListResultDtoFromJson(json);

  @JsonKey(name: 'toolsets')
  final List<ToolsetDto> toolsets;

  Map<String, dynamic> toJson() => _$ToolsListResultDtoToJson(this);

  List<Toolset> toDomain() {
    return toolsets.map((dto) => dto.toDomain()).toList();
  }
}

/// One toolset entry from `tools.list` or `toolsets.list`.
@JsonSerializable()
class ToolsetDto {
  const ToolsetDto({
    this.name,
    this.description,
    this.toolCount,
    this.enabled,
    this.tools,
  });

  factory ToolsetDto.fromJson(Map<String, dynamic> json) =>
      _$ToolsetDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'tool_count')
  final int? toolCount;

  @JsonKey(name: 'enabled')
  final bool? enabled;

  @JsonKey(name: 'tools')
  final List<String>? tools;

  Map<String, dynamic> toJson() => _$ToolsetDtoToJson(this);

  Toolset toDomain() {
    return Toolset(
      name: name ?? '',
      description: description ?? '',
      toolCount: toolCount ?? 0,
      enabled: enabled ?? false,
      tools: tools ?? const <String>[],
    );
  }
}

/// Wire DTO for `tools.show` result.
@JsonSerializable()
class ToolsShowResultDto {
  const ToolsShowResultDto({
    this.sections = const <ToolShowSectionDto>[],
    this.total,
  });

  factory ToolsShowResultDto.fromJson(Map<String, dynamic> json) =>
      _$ToolsShowResultDtoFromJson(json);

  @JsonKey(name: 'sections')
  final List<ToolShowSectionDto> sections;

  @JsonKey(name: 'total')
  final int? total;

  Map<String, dynamic> toJson() => _$ToolsShowResultDtoToJson(this);

  ToolsShow toDomain() {
    return ToolsShow(
      sections: sections.map((dto) => dto.toDomain()).toList(),
      total: total ?? 0,
    );
  }
}

/// One section entry from `tools.show`.
@JsonSerializable()
class ToolShowSectionDto {
  const ToolShowSectionDto({
    this.name,
    this.tools = const <ToolInfoDto>[],
  });

  factory ToolShowSectionDto.fromJson(Map<String, dynamic> json) =>
      _$ToolShowSectionDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'tools')
  final List<ToolInfoDto> tools;

  Map<String, dynamic> toJson() => _$ToolShowSectionDtoToJson(this);

  ToolSection toDomain() {
    return ToolSection(
      name: name ?? '',
      tools: tools.map((dto) => dto.toDomain()).toList(),
    );
  }
}

/// One tool entry from `tools.show`.
@JsonSerializable()
class ToolInfoDto {
  const ToolInfoDto({
    this.name,
    this.description,
  });

  factory ToolInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ToolInfoDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'description')
  final String? description;

  Map<String, dynamic> toJson() => _$ToolInfoDtoToJson(this);

  ToolInfo toDomain() {
    return ToolInfo(
      name: name ?? '',
      description: description ?? '',
    );
  }
}

/// Wire DTO for `tools.configure` result.
@JsonSerializable()
class ToolsConfigureResultDto {
  const ToolsConfigureResultDto({
    this.changed = const <String>[],
    this.enabledToolsets = const <String>[],
    this.missingServers = const <String>[],
    this.reset,
    this.unknown = const <String>[],
    this.info,
  });

  factory ToolsConfigureResultDto.fromJson(Map<String, dynamic> json) =>
      _$ToolsConfigureResultDtoFromJson(json);

  @JsonKey(name: 'changed')
  final List<String> changed;

  @JsonKey(name: 'enabled_toolsets')
  final List<String> enabledToolsets;

  @JsonKey(name: 'missing_servers')
  final List<String> missingServers;

  @JsonKey(name: 'reset')
  final bool? reset;

  @JsonKey(name: 'unknown')
  final List<String> unknown;

  @JsonKey(name: 'info')
  final Object? info;

  Map<String, dynamic> toJson() => _$ToolsConfigureResultDtoToJson(this);

  ToolsConfigureResult toDomain() {
    return ToolsConfigureResult(
      changed: changed,
      enabledToolsets: enabledToolsets,
      missingServers: missingServers,
      reset: reset ?? false,
      unknown: unknown,
    );
  }
}
