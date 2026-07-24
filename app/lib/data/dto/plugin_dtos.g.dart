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
