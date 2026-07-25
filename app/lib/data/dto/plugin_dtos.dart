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
