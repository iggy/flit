import 'package:flit/domain/models/plugin_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_dtos.g.dart';

/// Wire DTO for the `plugins.list` result
/// (docs/reference/03-mvp-wire-shapes.md §13).
@JsonSerializable()
class PluginsListResultDto {
  const PluginsListResultDto({this.plugins = const <PluginInfoDto>[]});

  factory PluginsListResultDto.fromJson(Map<String, dynamic> json) =>
      _$PluginsListResultDtoFromJson(json);

  @JsonKey(name: 'plugins')
  final List<PluginInfoDto> plugins;

  Map<String, dynamic> toJson() => _$PluginsListResultDtoToJson(this);

  List<PluginInfo> toDomain() {
    return plugins.map((dto) => dto.toDomain()).toList();
  }
}

/// One plugin entry (§13): `{name, version, enabled}`.
@JsonSerializable()
class PluginInfoDto {
  const PluginInfoDto({this.name, this.version, this.enabled});

  factory PluginInfoDto.fromJson(Map<String, dynamic> json) =>
      _$PluginInfoDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  /// Missing on some plugins → domain falls back to `'?'` (§13).
  @JsonKey(name: 'version')
  final String? version;

  @JsonKey(name: 'enabled')
  final bool? enabled;

  Map<String, dynamic> toJson() => _$PluginInfoDtoToJson(this);

  PluginInfo toDomain() {
    return PluginInfo(
      name: name ?? '',
      version: version ?? '?',
      enabled: enabled ?? false,
    );
  }
}

/// Wire DTO for `plugins.manage {action:'list'}` result (P5-08).
@JsonSerializable()
class PluginsManageResultDto {
  const PluginsManageResultDto({
    this.plugins = const <PluginDetailDto>[],
    this.userCount,
    this.bundledCount,
  });

  factory PluginsManageResultDto.fromJson(Map<String, dynamic> json) =>
      _$PluginsManageResultDtoFromJson(json);

  @JsonKey(name: 'plugins')
  final List<PluginDetailDto> plugins;

  @JsonKey(name: 'user_count')
  final int? userCount;

  @JsonKey(name: 'bundled_count')
  final int? bundledCount;

  Map<String, dynamic> toJson() => _$PluginsManageResultDtoToJson(this);

  List<PluginDetail> toDomain() {
    return plugins.map((dto) => dto.toDomain()).toList();
  }
}

/// One plugin detail row from `plugins.manage` (P5-08).
@JsonSerializable()
class PluginDetailDto {
  const PluginDetailDto({
    this.name,
    this.version,
    this.description,
    this.source,
    this.status,
  });

  factory PluginDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PluginDetailDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'version')
  final String? version;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'source')
  final String? source;

  @JsonKey(name: 'status')
  final String? status;

  Map<String, dynamic> toJson() => _$PluginDetailDtoToJson(this);

  PluginDetail toDomain() {
    return PluginDetail(
      name: name ?? '',
      version: version ?? '?',
      description: description ?? '',
      source: source ?? '',
      status: status ?? 'disabled',
    );
  }
}

/// Wire DTO for `plugins.manage {action:'toggle'}` result (P5-08).
@JsonSerializable()
class PluginToggleResultDto {
  const PluginToggleResultDto({
    this.ok,
    this.unchanged,
    this.name,
    this.plugin,
  });

  factory PluginToggleResultDto.fromJson(Map<String, dynamic> json) =>
      _$PluginToggleResultDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'unchanged')
  final bool? unchanged;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'plugin')
  final PluginDetailDto? plugin;

  Map<String, dynamic> toJson() => _$PluginToggleResultDtoToJson(this);

  PluginDetail? toDomain() {
    return plugin?.toDomain();
  }
}
