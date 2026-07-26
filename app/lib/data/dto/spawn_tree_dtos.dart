import 'package:flit/domain/models/spawn_tree_snapshot.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spawn_tree_dtos.g.dart';

/// Wire DTO for `spawn_tree.list` result
/// (docs/reference/08-agent-transparency-wire-shapes.md §spawn_tree.list).
@JsonSerializable()
class SpawnTreeListResultDto {
  const SpawnTreeListResultDto({
    this.entries = const <SpawnTreeSnapshotEntryDto>[],
  });

  factory SpawnTreeListResultDto.fromJson(Map<String, dynamic> json) =>
      _$SpawnTreeListResultDtoFromJson(json);

  @JsonKey(name: 'entries')
  final List<SpawnTreeSnapshotEntryDto> entries;

  Map<String, dynamic> toJson() => _$SpawnTreeListResultDtoToJson(this);

  List<SpawnTreeSnapshotEntry> toDomain() {
    return entries.map((dto) => dto.toDomain()).toList();
  }
}

/// One snapshot entry from `spawn_tree.list`.
@JsonSerializable()
class SpawnTreeSnapshotEntryDto {
  const SpawnTreeSnapshotEntryDto({
    this.path,
    this.sessionId,
    this.finishedAt,
    this.startedAt,
    this.label,
    this.count,
  });

  factory SpawnTreeSnapshotEntryDto.fromJson(Map<String, dynamic> json) =>
      _$SpawnTreeSnapshotEntryDtoFromJson(json);

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'session_id')
  final String? sessionId;

  @JsonKey(name: 'finished_at')
  final num? finishedAt;

  @JsonKey(name: 'started_at')
  final num? startedAt;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'count')
  final int? count;

  Map<String, dynamic> toJson() => _$SpawnTreeSnapshotEntryDtoToJson(this);

  SpawnTreeSnapshotEntry toDomain() {
    return SpawnTreeSnapshotEntry(
      path: path ?? '',
      sessionId: sessionId ?? '',
      finishedAt: (finishedAt ?? 0).toDouble(),
      startedAt: startedAt?.toDouble(),
      label: label ?? '',
      count: count ?? 0,
    );
  }
}

/// Wire DTO for `spawn_tree.load` result.
///
/// The `subagents` field is OPAQUE (TUI-assembled) — json_serializable cannot
/// cleanly type `List<dynamic>` in a standard DTO, so we use a custom fromJson
/// that reads the raw JSON list directly.
class SpawnTreeLoadResultDto {
  const SpawnTreeLoadResultDto({
    this.sessionId,
    this.startedAt,
    this.finishedAt,
    this.label,
    this.subagents = const <dynamic>[],
  });

  factory SpawnTreeLoadResultDto.fromJson(Map<String, dynamic> json) {
    return SpawnTreeLoadResultDto(
      sessionId: json['session_id'] as String?,
      startedAt: json['started_at'] as num?,
      finishedAt: json['finished_at'] as num?,
      label: json['label'] as String?,
      subagents: json['subagents'] as List<dynamic>? ?? const <dynamic>[],
    );
  }

  final String? sessionId;
  final num? startedAt;
  final num? finishedAt;
  final String? label;
  final List<dynamic> subagents;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'session_id': sessionId,
    'started_at': startedAt,
    'finished_at': finishedAt,
    'label': label,
    'subagents': subagents,
  };

  SpawnTreeSnapshot toDomain() {
    return SpawnTreeSnapshot(
      sessionId: sessionId ?? '',
      startedAt: startedAt?.toDouble(),
      finishedAt: (finishedAt ?? 0).toDouble(),
      label: label ?? '',
      subagents: subagents,
    );
  }
}

/// Wire DTO for `spawn_tree.save` result.
@JsonSerializable()
class SpawnTreeSaveResultDto {
  const SpawnTreeSaveResultDto({this.path, this.sessionId});

  factory SpawnTreeSaveResultDto.fromJson(Map<String, dynamic> json) =>
      _$SpawnTreeSaveResultDtoFromJson(json);

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'session_id')
  final String? sessionId;

  Map<String, dynamic> toJson() => _$SpawnTreeSaveResultDtoToJson(this);
}
