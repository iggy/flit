import 'package:flit/domain/models/skill_catalog.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skills_dtos.g.dart';

/// Wire DTO for `skills.manage {action:'list'}` result (P5-09).
/// Wire shape: `{skills: {category: [name-str]}}` — a map of category to
/// skill names.
@JsonSerializable()
class SkillsListResultDto {
  const SkillsListResultDto({this.skills});

  factory SkillsListResultDto.fromJson(Map<String, dynamic> json) =>
      _$SkillsListResultDtoFromJson(json);

  @JsonKey(name: 'skills')
  final Map<String, List<String>>? skills;

  Map<String, dynamic> toJson() => _$SkillsListResultDtoToJson(this);

  SkillCatalog toDomain() {
    final skillsMap = skills ?? <String, List<String>>{};
    final groups = skillsMap.entries
        .map((entry) => SkillGroup(category: entry.key, names: entry.value))
        .toList();
    return SkillCatalog(groups: groups);
  }
}

/// Wire DTO for `skills.manage {action:'browse'}` result (P5-09).
@JsonSerializable()
class SkillsBrowseResultDto {
  const SkillsBrowseResultDto({
    this.items = const <SkillBrowseItemDto>[],
    this.page,
    this.totalPages,
    this.total,
  });

  factory SkillsBrowseResultDto.fromJson(Map<String, dynamic> json) =>
      _$SkillsBrowseResultDtoFromJson(json);

  @JsonKey(name: 'items')
  final List<SkillBrowseItemDto> items;

  @JsonKey(name: 'page')
  final int? page;

  @JsonKey(name: 'total_pages')
  final int? totalPages;

  @JsonKey(name: 'total')
  final int? total;

  Map<String, dynamic> toJson() => _$SkillsBrowseResultDtoToJson(this);

  SkillBrowseResult toDomain() {
    return SkillBrowseResult(
      items: items.map((dto) => dto.toDomain()).toList(),
      page: page ?? 1,
      totalPages: totalPages ?? 0,
      total: total ?? 0,
    );
  }
}

/// One browse item from `skills.manage {action:'browse'}` (P5-09).
@JsonSerializable()
class SkillBrowseItemDto {
  const SkillBrowseItemDto({
    this.name,
    this.description,
    this.source,
    this.trust,
    this.identifier,
  });

  factory SkillBrowseItemDto.fromJson(Map<String, dynamic> json) =>
      _$SkillBrowseItemDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'source')
  final String? source;

  @JsonKey(name: 'trust')
  final String? trust;

  @JsonKey(name: 'identifier')
  final String? identifier;

  Map<String, dynamic> toJson() => _$SkillBrowseItemDtoToJson(this);

  SkillBrowseItem toDomain() {
    return SkillBrowseItem(
      name: name ?? '',
      description: description ?? '',
      source: source ?? '',
      trust: trust ?? '',
      identifier: identifier ?? '',
    );
  }
}

/// Wire DTO for `skills.reload` result (P5-09).
@JsonSerializable()
class SkillsReloadResultDto {
  const SkillsReloadResultDto({this.output, this.result});

  factory SkillsReloadResultDto.fromJson(Map<String, dynamic> json) =>
      _$SkillsReloadResultDtoFromJson(json);

  @JsonKey(name: 'output')
  final String? output;

  @JsonKey(name: 'result')
  final SkillsReloadResultDetailDto? result;

  Map<String, dynamic> toJson() => _$SkillsReloadResultDtoToJson(this);

  SkillReloadResult toDomain() {
    final res = result;
    return SkillReloadResult(
      output: output ?? '',
      added:
          res?.added?.map((dto) => dto.toDomain()).toList() ?? <SkillChange>[],
      removed:
          res?.removed?.map((dto) => dto.toDomain()).toList() ??
          <SkillChange>[],
      unchanged: res?.unchanged ?? <String>[],
      total: res?.total ?? 0,
      commands: res?.commands ?? 0,
    );
  }
}

/// Inner `result` payload from `skills.reload` (P5-09).
@JsonSerializable()
class SkillsReloadResultDetailDto {
  const SkillsReloadResultDetailDto({
    this.added,
    this.removed,
    this.unchanged,
    this.total,
    this.commands,
  });

  factory SkillsReloadResultDetailDto.fromJson(Map<String, dynamic> json) =>
      _$SkillsReloadResultDetailDtoFromJson(json);

  @JsonKey(name: 'added')
  final List<SkillChangeDto>? added;

  @JsonKey(name: 'removed')
  final List<SkillChangeDto>? removed;

  @JsonKey(name: 'unchanged')
  final List<String>? unchanged;

  @JsonKey(name: 'total')
  final int? total;

  @JsonKey(name: 'commands')
  final int? commands;

  Map<String, dynamic> toJson() => _$SkillsReloadResultDetailDtoToJson(this);
}

/// One skill change (added/removed) from `skills.reload` (P5-09).
@JsonSerializable()
class SkillChangeDto {
  const SkillChangeDto({this.name, this.description});

  factory SkillChangeDto.fromJson(Map<String, dynamic> json) =>
      _$SkillChangeDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'description')
  final String? description;

  Map<String, dynamic> toJson() => _$SkillChangeDtoToJson(this);

  SkillChange toDomain() {
    return SkillChange(name: name ?? '', description: description ?? '');
  }
}
