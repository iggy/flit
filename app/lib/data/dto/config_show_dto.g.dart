// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_show_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigShowResultDto _$ConfigShowResultDtoFromJson(Map<String, dynamic> json) =>
    ConfigShowResultDto(
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => ConfigSectionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ConfigSectionDto>[],
    );

Map<String, dynamic> _$ConfigShowResultDtoToJson(
  ConfigShowResultDto instance,
) => <String, dynamic>{'sections': instance.sections};

ConfigSectionDto _$ConfigSectionDtoFromJson(Map<String, dynamic> json) =>
    ConfigSectionDto(
      title: json['title'] as String?,
      rows:
          (json['rows'] as List<dynamic>?)
              ?.map((e) => e as List<dynamic>)
              .toList() ??
          const <List<dynamic>>[],
    );

Map<String, dynamic> _$ConfigSectionDtoToJson(ConfigSectionDto instance) =>
    <String, dynamic>{'title': instance.title, 'rows': instance.rows};
