// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillsListResultDto _$SkillsListResultDtoFromJson(Map<String, dynamic> json) =>
    SkillsListResultDto(
      skills: (json['skills'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$SkillsListResultDtoToJson(
  SkillsListResultDto instance,
) => <String, dynamic>{'skills': instance.skills};

SkillsBrowseResultDto _$SkillsBrowseResultDtoFromJson(
  Map<String, dynamic> json,
) => SkillsBrowseResultDto(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SkillBrowseItemDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SkillBrowseItemDto>[],
  page: (json['page'] as num?)?.toInt(),
  totalPages: (json['total_pages'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toInt(),
);

Map<String, dynamic> _$SkillsBrowseResultDtoToJson(
  SkillsBrowseResultDto instance,
) => <String, dynamic>{
  'items': instance.items,
  'page': instance.page,
  'total_pages': instance.totalPages,
  'total': instance.total,
};

SkillBrowseItemDto _$SkillBrowseItemDtoFromJson(Map<String, dynamic> json) =>
    SkillBrowseItemDto(
      name: json['name'] as String?,
      description: json['description'] as String?,
      source: json['source'] as String?,
      trust: json['trust'] as String?,
      identifier: json['identifier'] as String?,
    );

Map<String, dynamic> _$SkillBrowseItemDtoToJson(SkillBrowseItemDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'source': instance.source,
      'trust': instance.trust,
      'identifier': instance.identifier,
    };

SkillsReloadResultDto _$SkillsReloadResultDtoFromJson(
  Map<String, dynamic> json,
) => SkillsReloadResultDto(
  output: json['output'] as String?,
  result: json['result'] == null
      ? null
      : SkillsReloadResultDetailDto.fromJson(
          json['result'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SkillsReloadResultDtoToJson(
  SkillsReloadResultDto instance,
) => <String, dynamic>{'output': instance.output, 'result': instance.result};

SkillsReloadResultDetailDto _$SkillsReloadResultDetailDtoFromJson(
  Map<String, dynamic> json,
) => SkillsReloadResultDetailDto(
  added: (json['added'] as List<dynamic>?)
      ?.map((e) => SkillChangeDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  removed: (json['removed'] as List<dynamic>?)
      ?.map((e) => SkillChangeDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  unchanged: (json['unchanged'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  total: (json['total'] as num?)?.toInt(),
  commands: (json['commands'] as num?)?.toInt(),
);

Map<String, dynamic> _$SkillsReloadResultDetailDtoToJson(
  SkillsReloadResultDetailDto instance,
) => <String, dynamic>{
  'added': instance.added,
  'removed': instance.removed,
  'unchanged': instance.unchanged,
  'total': instance.total,
  'commands': instance.commands,
};

SkillChangeDto _$SkillChangeDtoFromJson(Map<String, dynamic> json) =>
    SkillChangeDto(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$SkillChangeDtoToJson(SkillChangeDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };
