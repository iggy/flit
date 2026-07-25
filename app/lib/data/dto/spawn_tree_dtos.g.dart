// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spawn_tree_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpawnTreeListResultDto _$SpawnTreeListResultDtoFromJson(
  Map<String, dynamic> json,
) => SpawnTreeListResultDto(
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map(
            (e) =>
                SpawnTreeSnapshotEntryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <SpawnTreeSnapshotEntryDto>[],
);

Map<String, dynamic> _$SpawnTreeListResultDtoToJson(
  SpawnTreeListResultDto instance,
) => <String, dynamic>{'entries': instance.entries};

SpawnTreeSnapshotEntryDto _$SpawnTreeSnapshotEntryDtoFromJson(
  Map<String, dynamic> json,
) => SpawnTreeSnapshotEntryDto(
  path: json['path'] as String?,
  sessionId: json['session_id'] as String?,
  finishedAt: json['finished_at'] as num?,
  startedAt: json['started_at'] as num?,
  label: json['label'] as String?,
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$SpawnTreeSnapshotEntryDtoToJson(
  SpawnTreeSnapshotEntryDto instance,
) => <String, dynamic>{
  'path': instance.path,
  'session_id': instance.sessionId,
  'finished_at': instance.finishedAt,
  'started_at': instance.startedAt,
  'label': instance.label,
  'count': instance.count,
};

SpawnTreeSaveResultDto _$SpawnTreeSaveResultDtoFromJson(
  Map<String, dynamic> json,
) => SpawnTreeSaveResultDto(
  path: json['path'] as String?,
  sessionId: json['session_id'] as String?,
);

Map<String, dynamic> _$SpawnTreeSaveResultDtoToJson(
  SpawnTreeSaveResultDto instance,
) => <String, dynamic>{'path': instance.path, 'session_id': instance.sessionId};
