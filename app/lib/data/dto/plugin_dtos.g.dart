// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginsListResultDto _$PluginsListResultDtoFromJson(
  Map<String, dynamic> json,
) => PluginsListResultDto(
  plugins:
      (json['plugins'] as List<dynamic>?)
          ?.map((e) => PluginInfoDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PluginInfoDto>[],
);

Map<String, dynamic> _$PluginsListResultDtoToJson(
  PluginsListResultDto instance,
) => <String, dynamic>{'plugins': instance.plugins};

PluginInfoDto _$PluginInfoDtoFromJson(Map<String, dynamic> json) =>
    PluginInfoDto(
      name: json['name'] as String?,
      version: json['version'] as String?,
      enabled: json['enabled'] as bool?,
    );

Map<String, dynamic> _$PluginInfoDtoToJson(PluginInfoDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'enabled': instance.enabled,
    };

PluginsManageResultDto _$PluginsManageResultDtoFromJson(
  Map<String, dynamic> json,
) => PluginsManageResultDto(
  plugins:
      (json['plugins'] as List<dynamic>?)
          ?.map((e) => PluginDetailDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PluginDetailDto>[],
  userCount: (json['user_count'] as num?)?.toInt(),
  bundledCount: (json['bundled_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$PluginsManageResultDtoToJson(
  PluginsManageResultDto instance,
) => <String, dynamic>{
  'plugins': instance.plugins,
  'user_count': instance.userCount,
  'bundled_count': instance.bundledCount,
};

PluginDetailDto _$PluginDetailDtoFromJson(Map<String, dynamic> json) =>
    PluginDetailDto(
      name: json['name'] as String?,
      version: json['version'] as String?,
      description: json['description'] as String?,
      source: json['source'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$PluginDetailDtoToJson(PluginDetailDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
      'source': instance.source,
      'status': instance.status,
    };

PluginToggleResultDto _$PluginToggleResultDtoFromJson(
  Map<String, dynamic> json,
) => PluginToggleResultDto(
  ok: json['ok'] as bool?,
  unchanged: json['unchanged'] as bool?,
  name: json['name'] as String?,
  plugin: json['plugin'] == null
      ? null
      : PluginDetailDto.fromJson(json['plugin'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PluginToggleResultDtoToJson(
  PluginToggleResultDto instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'unchanged': instance.unchanged,
  'name': instance.name,
  'plugin': instance.plugin,
};
