// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LearningAxisDto _$LearningAxisDtoFromJson(Map<String, dynamic> json) =>
    LearningAxisDto(
      start: json['start'] as String?,
      end: json['end'] as String?,
    );

Map<String, dynamic> _$LearningAxisDtoToJson(LearningAxisDto instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};

LearningNodeDto _$LearningNodeDtoFromJson(Map<String, dynamic> json) =>
    LearningNodeDto(
      id: json['id'] as String?,
      glyph: json['glyph'] as String?,
      label: json['label'] as String?,
      fullLabel: json['fullLabel'] as String?,
      meta: json['meta'] as String?,
      body: json['body'] as String?,
      style: json['style'] as String?,
    );

Map<String, dynamic> _$LearningNodeDtoToJson(LearningNodeDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'glyph': instance.glyph,
      'label': instance.label,
      'fullLabel': instance.fullLabel,
      'meta': instance.meta,
      'body': instance.body,
      'style': instance.style,
    };

LearningBucketDto _$LearningBucketDtoFromJson(Map<String, dynamic> json) =>
    LearningBucketDto(
      index: (json['index'] as num?)?.toInt(),
      label: json['label'] as String?,
      date: json['date'] as String?,
      skills: (json['skills'] as num?)?.toInt(),
      memories: (json['memories'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      category: json['category'] as String?,
      color: json['color'] as String?,
      nodes:
          (json['nodes'] as List<dynamic>?)
              ?.map((e) => LearningNodeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <LearningNodeDto>[],
    );

Map<String, dynamic> _$LearningBucketDtoToJson(LearningBucketDto instance) =>
    <String, dynamic>{
      'index': instance.index,
      'label': instance.label,
      'date': instance.date,
      'skills': instance.skills,
      'memories': instance.memories,
      'total': instance.total,
      'category': instance.category,
      'color': instance.color,
      'nodes': instance.nodes,
    };

LearningLegendDto _$LearningLegendDtoFromJson(Map<String, dynamic> json) =>
    LearningLegendDto(
      glyph: json['glyph'] as String?,
      style: json['style'] as String?,
      label: json['label'] as String?,
    );

Map<String, dynamic> _$LearningLegendDtoToJson(LearningLegendDto instance) =>
    <String, dynamic>{
      'glyph': instance.glyph,
      'style': instance.style,
      'label': instance.label,
    };

LearningCategoryDto _$LearningCategoryDtoFromJson(Map<String, dynamic> json) =>
    LearningCategoryDto(
      glyph: json['glyph'] as String?,
      color: json['color'] as String?,
      label: json['label'] as String?,
    );

Map<String, dynamic> _$LearningCategoryDtoToJson(
  LearningCategoryDto instance,
) => <String, dynamic>{
  'glyph': instance.glyph,
  'color': instance.color,
  'label': instance.label,
};

LearningFramesResultDto _$LearningFramesResultDtoFromJson(
  Map<String, dynamic> json,
) => LearningFramesResultDto(
  buckets:
      (json['buckets'] as List<dynamic>?)
          ?.map((e) => LearningBucketDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LearningBucketDto>[],
  summary:
      (json['summary'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  legend:
      (json['legend'] as List<dynamic>?)
          ?.map((e) => LearningLegendDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LearningLegendDto>[],
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => LearningCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LearningCategoryDto>[],
  axis: json['axis'] == null
      ? null
      : LearningAxisDto.fromJson(json['axis'] as Map<String, dynamic>),
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$LearningFramesResultDtoToJson(
  LearningFramesResultDto instance,
) => <String, dynamic>{
  'buckets': instance.buckets,
  'summary': instance.summary,
  'legend': instance.legend,
  'categories': instance.categories,
  'axis': instance.axis,
  'count': instance.count,
};

LearningDetailResultDto _$LearningDetailResultDtoFromJson(
  Map<String, dynamic> json,
) => LearningDetailResultDto(
  ok: json['ok'] as bool?,
  kind: json['kind'] as String?,
  id: json['id'] as String?,
  label: json['label'] as String?,
  content: json['content'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$LearningDetailResultDtoToJson(
  LearningDetailResultDto instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'kind': instance.kind,
  'id': instance.id,
  'label': instance.label,
  'content': instance.content,
  'message': instance.message,
};

LearningMutationResultDto _$LearningMutationResultDtoFromJson(
  Map<String, dynamic> json,
) => LearningMutationResultDto(
  ok: json['ok'] as bool?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$LearningMutationResultDtoToJson(
  LearningMutationResultDto instance,
) => <String, dynamic>{'ok': instance.ok, 'message': instance.message};
