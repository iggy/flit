// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectFolderDto _$ProjectFolderDtoFromJson(Map<String, dynamic> json) =>
    ProjectFolderDto(
      path: json['path'] as String?,
      label: json['label'] as String?,
      isPrimary: json['is_primary'] as bool?,
      addedAt: (json['added_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProjectFolderDtoToJson(ProjectFolderDto instance) =>
    <String, dynamic>{
      'path': instance.path,
      'label': instance.label,
      'is_primary': instance.isPrimary,
      'added_at': instance.addedAt,
    };

ProjectDto _$ProjectDtoFromJson(Map<String, dynamic> json) => ProjectDto(
  id: json['id'] as String?,
  slug: json['slug'] as String?,
  name: json['name'] as String?,
  description: json['description'] as String?,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  boardSlug: json['board_slug'] as String?,
  primaryPath: json['primary_path'] as String?,
  archived: json['archived'] as bool?,
  createdAt: (json['created_at'] as num?)?.toInt(),
  folders:
      (json['folders'] as List<dynamic>?)
          ?.map((e) => ProjectFolderDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProjectFolderDto>[],
);

Map<String, dynamic> _$ProjectDtoToJson(ProjectDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'color': instance.color,
      'board_slug': instance.boardSlug,
      'primary_path': instance.primaryPath,
      'archived': instance.archived,
      'created_at': instance.createdAt,
      'folders': instance.folders,
    };

ProjectsListResultDto _$ProjectsListResultDtoFromJson(
  Map<String, dynamic> json,
) => ProjectsListResultDto(
  projects:
      (json['projects'] as List<dynamic>?)
          ?.map((e) => ProjectDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProjectDto>[],
  activeId: json['active_id'] as String?,
);

Map<String, dynamic> _$ProjectsListResultDtoToJson(
  ProjectsListResultDto instance,
) => <String, dynamic>{
  'projects': instance.projects,
  'active_id': instance.activeId,
};

ProjectResultDto _$ProjectResultDtoFromJson(Map<String, dynamic> json) =>
    ProjectResultDto(
      project: json['project'] == null
          ? null
          : ProjectDto.fromJson(json['project'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProjectResultDtoToJson(ProjectResultDto instance) =>
    <String, dynamic>{'project': instance.project};

ForCwdResultDto _$ForCwdResultDtoFromJson(Map<String, dynamic> json) =>
    ForCwdResultDto(
      project: json['project'] == null
          ? null
          : ProjectDto.fromJson(json['project'] as Map<String, dynamic>),
      cwd: json['cwd'] as String?,
      branch: json['branch'] as String?,
    );

Map<String, dynamic> _$ForCwdResultDtoToJson(ForCwdResultDto instance) =>
    <String, dynamic>{
      'project': instance.project,
      'cwd': instance.cwd,
      'branch': instance.branch,
    };

SetActiveResultDto _$SetActiveResultDtoFromJson(Map<String, dynamic> json) =>
    SetActiveResultDto(activeId: json['active_id'] as String?);

Map<String, dynamic> _$SetActiveResultDtoToJson(SetActiveResultDto instance) =>
    <String, dynamic>{'active_id': instance.activeId};

DiscoveredRepoDto _$DiscoveredRepoDtoFromJson(Map<String, dynamic> json) =>
    DiscoveredRepoDto(
      root: json['root'] as String?,
      label: json['label'] as String?,
      sessions: (json['sessions'] as num?)?.toInt(),
      lastActive: json['last_active'] as num?,
    );

Map<String, dynamic> _$DiscoveredRepoDtoToJson(DiscoveredRepoDto instance) =>
    <String, dynamic>{
      'root': instance.root,
      'label': instance.label,
      'sessions': instance.sessions,
      'last_active': instance.lastActive,
    };

DiscoverReposResultDto _$DiscoverReposResultDtoFromJson(
  Map<String, dynamic> json,
) => DiscoverReposResultDto(
  repos:
      (json['repos'] as List<dynamic>?)
          ?.map((e) => DiscoveredRepoDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DiscoveredRepoDto>[],
);

Map<String, dynamic> _$DiscoverReposResultDtoToJson(
  DiscoverReposResultDto instance,
) => <String, dynamic>{'repos': instance.repos};
