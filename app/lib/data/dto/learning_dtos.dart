import 'package:flit/domain/models/learning_journey.dart';
import 'package:json_annotation/json_annotation.dart';

part 'learning_dtos.g.dart';

/// Wire DTO for axis labels.
@JsonSerializable()
class LearningAxisDto {
  const LearningAxisDto({this.start, this.end});

  factory LearningAxisDto.fromJson(Map<String, dynamic> json) =>
      _$LearningAxisDtoFromJson(json);

  @JsonKey(name: 'start')
  final String? start;

  @JsonKey(name: 'end')
  final String? end;

  Map<String, dynamic> toJson() => _$LearningAxisDtoToJson(this);

  ({String start, String end}) toDomain() {
    return (start: start ?? '', end: end ?? '');
  }
}

/// Wire DTO for a learning node.
@JsonSerializable()
class LearningNodeDto {
  const LearningNodeDto({
    this.id,
    this.glyph,
    this.label,
    this.fullLabel,
    this.meta,
    this.body,
    this.style,
  });

  factory LearningNodeDto.fromJson(Map<String, dynamic> json) =>
      _$LearningNodeDtoFromJson(json);

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'glyph')
  final String? glyph;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'fullLabel')
  final String? fullLabel;

  @JsonKey(name: 'meta')
  final String? meta;

  @JsonKey(name: 'body')
  final String? body;

  @JsonKey(name: 'style')
  final String? style;

  Map<String, dynamic> toJson() => _$LearningNodeDtoToJson(this);

  LearningNode toDomain() {
    return LearningNode(
      id: id ?? '',
      glyph: glyph ?? '',
      label: label ?? '',
      fullLabel: fullLabel ?? '',
      meta: meta ?? '',
      body: body ?? '',
      style: style ?? '',
    );
  }
}

/// Wire DTO for a bucket.
@JsonSerializable()
class LearningBucketDto {
  const LearningBucketDto({
    this.index,
    this.label,
    this.date,
    this.skills,
    this.memories,
    this.total,
    this.category,
    this.color,
    this.nodes = const <LearningNodeDto>[],
  });

  factory LearningBucketDto.fromJson(Map<String, dynamic> json) =>
      _$LearningBucketDtoFromJson(json);

  @JsonKey(name: 'index')
  final int? index;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'date')
  final String? date;

  @JsonKey(name: 'skills')
  final int? skills;

  @JsonKey(name: 'memories')
  final int? memories;

  @JsonKey(name: 'total')
  final int? total;

  @JsonKey(name: 'category')
  final String? category;

  @JsonKey(name: 'color')
  final String? color;

  @JsonKey(name: 'nodes')
  final List<LearningNodeDto> nodes;

  Map<String, dynamic> toJson() => _$LearningBucketDtoToJson(this);

  LearningBucket toDomain() {
    return LearningBucket(
      index: index ?? 0,
      label: label ?? '',
      date: date ?? '',
      skills: skills ?? 0,
      memories: memories ?? 0,
      total: total ?? 0,
      category: category,
      color: color,
      nodes: nodes.map((dto) => dto.toDomain()).toList(),
    );
  }
}

/// Wire DTO for a legend entry.
@JsonSerializable()
class LearningLegendDto {
  const LearningLegendDto({
    this.glyph,
    this.style,
    this.label,
  });

  factory LearningLegendDto.fromJson(Map<String, dynamic> json) =>
      _$LearningLegendDtoFromJson(json);

  @JsonKey(name: 'glyph')
  final String? glyph;

  @JsonKey(name: 'style')
  final String? style;

  @JsonKey(name: 'label')
  final String? label;

  Map<String, dynamic> toJson() => _$LearningLegendDtoToJson(this);

  LearningLegend toDomain() {
    return LearningLegend(
      glyph: glyph ?? '',
      style: style ?? '',
      label: label ?? '',
    );
  }
}

/// Wire DTO for a category entry.
@JsonSerializable()
class LearningCategoryDto {
  const LearningCategoryDto({
    this.glyph,
    this.color,
    this.label,
  });

  factory LearningCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$LearningCategoryDtoFromJson(json);

  @JsonKey(name: 'glyph')
  final String? glyph;

  @JsonKey(name: 'color')
  final String? color;

  @JsonKey(name: 'label')
  final String? label;

  Map<String, dynamic> toJson() => _$LearningCategoryDtoToJson(this);

  LearningCategory toDomain() {
    return LearningCategory(
      glyph: glyph ?? '',
      color: color ?? '',
      label: label ?? '',
    );
  }
}

/// Wire DTO for `learning.frames` result.
@JsonSerializable()
class LearningFramesResultDto {
  const LearningFramesResultDto({
    this.buckets = const <LearningBucketDto>[],
    this.summary = const <String>[],
    this.legend = const <LearningLegendDto>[],
    this.categories = const <LearningCategoryDto>[],
    this.axis,
    this.count,
  });

  factory LearningFramesResultDto.fromJson(Map<String, dynamic> json) =>
      _$LearningFramesResultDtoFromJson(json);

  @JsonKey(name: 'buckets')
  final List<LearningBucketDto> buckets;

  @JsonKey(name: 'summary')
  final List<String> summary;

  @JsonKey(name: 'legend')
  final List<LearningLegendDto> legend;

  @JsonKey(name: 'categories')
  final List<LearningCategoryDto> categories;

  @JsonKey(name: 'axis')
  final LearningAxisDto? axis;

  @JsonKey(name: 'count')
  final int? count;

  Map<String, dynamic> toJson() => _$LearningFramesResultDtoToJson(this);

  LearningJourney toDomain() {
    return LearningJourney(
      buckets: buckets.map((dto) => dto.toDomain()).toList(),
      summary: summary,
      legend: legend.map((dto) => dto.toDomain()).toList(),
      categories: categories.map((dto) => dto.toDomain()).toList(),
      axis: axis?.toDomain() ?? (start: '', end: ''),
      count: count ?? 0,
    );
  }
}

/// Wire DTO for `learning.detail` result.
@JsonSerializable()
class LearningDetailResultDto {
  const LearningDetailResultDto({
    this.ok,
    this.kind,
    this.id,
    this.label,
    this.content,
    this.message,
  });

  factory LearningDetailResultDto.fromJson(Map<String, dynamic> json) =>
      _$LearningDetailResultDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'kind')
  final String? kind;

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'content')
  final String? content;

  @JsonKey(name: 'message')
  final String? message;

  Map<String, dynamic> toJson() => _$LearningDetailResultDtoToJson(this);

  LearningNodeDetail toDomain() {
    return LearningNodeDetail(
      ok: ok ?? false,
      kind: kind,
      id: id ?? '',
      label: label ?? '',
      content: content ?? '',
      message: message,
    );
  }
}

/// Wire DTO for `learning.edit` and `learning.delete` results.
@JsonSerializable()
class LearningMutationResultDto {
  const LearningMutationResultDto({
    this.ok,
    this.message,
  });

  factory LearningMutationResultDto.fromJson(Map<String, dynamic> json) =>
      _$LearningMutationResultDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'message')
  final String? message;

  Map<String, dynamic> toJson() => _$LearningMutationResultDtoToJson(this);

  LearningMutationResult toDomain() {
    return (ok: ok ?? false, message: message ?? '');
  }
}
