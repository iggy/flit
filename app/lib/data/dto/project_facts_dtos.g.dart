// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_facts_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectFactsDto _$ProjectFactsDtoFromJson(Map<String, dynamic> json) =>
    ProjectFactsDto(
      root: json['root'] as String?,
      manifests:
          (json['manifests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      packageManagers:
          (json['packageManagers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      verifyCommands:
          (json['verifyCommands'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      contextFiles:
          (json['contextFiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ProjectFactsDtoToJson(ProjectFactsDto instance) =>
    <String, dynamic>{
      'root': instance.root,
      'manifests': instance.manifests,
      'packageManagers': instance.packageManagers,
      'verifyCommands': instance.verifyCommands,
      'contextFiles': instance.contextFiles,
    };

ProjectFactsResultDto _$ProjectFactsResultDtoFromJson(
  Map<String, dynamic> json,
) => ProjectFactsResultDto(
  facts: json['facts'] == null
      ? null
      : ProjectFactsDto.fromJson(json['facts'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProjectFactsResultDtoToJson(
  ProjectFactsResultDto instance,
) => <String, dynamic>{'facts': instance.facts};
