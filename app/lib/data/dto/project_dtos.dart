import 'package:flit/domain/models/project.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_dtos.g.dart';

/// Wire DTO for a project folder entry.
@JsonSerializable()
class ProjectFolderDto {
  const ProjectFolderDto({this.path, this.label, this.isPrimary, this.addedAt});

  factory ProjectFolderDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectFolderDtoFromJson(json);

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'is_primary')
  final bool? isPrimary;

  @JsonKey(name: 'added_at')
  final int? addedAt;

  Map<String, dynamic> toJson() => _$ProjectFolderDtoToJson(this);

  ProjectFolder toDomain() {
    return ProjectFolder(
      path: path ?? '',
      label: label,
      isPrimary: isPrimary ?? false,
      addedAt: addedAt ?? 0,
    );
  }
}

/// Wire DTO for a project (wire shape from `projects.*` methods).
@JsonSerializable()
class ProjectDto {
  const ProjectDto({
    this.id,
    this.slug,
    this.name,
    this.description,
    this.icon,
    this.color,
    this.boardSlug,
    this.primaryPath,
    this.archived,
    this.createdAt,
    this.folders = const <ProjectFolderDto>[],
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectDtoFromJson(json);

  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'slug')
  final String? slug;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'icon')
  final String? icon;

  @JsonKey(name: 'color')
  final String? color;

  @JsonKey(name: 'board_slug')
  final String? boardSlug;

  @JsonKey(name: 'primary_path')
  final String? primaryPath;

  @JsonKey(name: 'archived')
  final bool? archived;

  @JsonKey(name: 'created_at')
  final int? createdAt;

  @JsonKey(name: 'folders')
  final List<ProjectFolderDto> folders;

  Map<String, dynamic> toJson() => _$ProjectDtoToJson(this);

  Project toDomain() {
    return Project(
      id: id ?? '',
      slug: slug ?? '',
      name: name ?? '',
      description: description,
      icon: icon,
      color: color,
      boardSlug: boardSlug,
      primaryPath: primaryPath,
      archived: archived ?? false,
      createdAt: createdAt ?? 0,
      folders: folders.map((dto) => dto.toDomain()).toList(),
    );
  }
}

/// Wire DTO for `projects.list` result.
@JsonSerializable()
class ProjectsListResultDto {
  const ProjectsListResultDto({
    this.projects = const <ProjectDto>[],
    this.activeId,
  });

  factory ProjectsListResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectsListResultDtoFromJson(json);

  @JsonKey(name: 'projects')
  final List<ProjectDto> projects;

  @JsonKey(name: 'active_id')
  final String? activeId;

  Map<String, dynamic> toJson() => _$ProjectsListResultDtoToJson(this);

  ({List<Project> projects, String? activeId}) toDomain() {
    return (
      projects: projects.map((dto) => dto.toDomain()).toList(),
      activeId: activeId,
    );
  }
}

/// Wire DTO for single-project results (get, create, update, etc.).
@JsonSerializable()
class ProjectResultDto {
  const ProjectResultDto({this.project});

  factory ProjectResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectResultDtoFromJson(json);

  @JsonKey(name: 'project')
  final ProjectDto? project;

  Map<String, dynamic> toJson() => _$ProjectResultDtoToJson(this);

  Project? toDomain() {
    return project?.toDomain();
  }
}

/// Wire DTO for `projects.for_cwd` result.
@JsonSerializable()
class ForCwdResultDto {
  const ForCwdResultDto({this.project, this.cwd, this.branch});

  factory ForCwdResultDto.fromJson(Map<String, dynamic> json) =>
      _$ForCwdResultDtoFromJson(json);

  @JsonKey(name: 'project')
  final ProjectDto? project;

  @JsonKey(name: 'cwd')
  final String? cwd;

  @JsonKey(name: 'branch')
  final String? branch;

  Map<String, dynamic> toJson() => _$ForCwdResultDtoToJson(this);

  ({Project? project, String cwd, String? branch}) toDomain() {
    return (project: project?.toDomain(), cwd: cwd ?? '', branch: branch);
  }
}

/// Wire DTO for `projects.set_active` result.
@JsonSerializable()
class SetActiveResultDto {
  const SetActiveResultDto({this.activeId});

  factory SetActiveResultDto.fromJson(Map<String, dynamic> json) =>
      _$SetActiveResultDtoFromJson(json);

  @JsonKey(name: 'active_id')
  final String? activeId;

  Map<String, dynamic> toJson() => _$SetActiveResultDtoToJson(this);
}

/// Wire DTO for a discovered repository entry.
@JsonSerializable()
class DiscoveredRepoDto {
  const DiscoveredRepoDto({
    this.root,
    this.label,
    this.sessions,
    this.lastActive,
  });

  factory DiscoveredRepoDto.fromJson(Map<String, dynamic> json) =>
      _$DiscoveredRepoDtoFromJson(json);

  @JsonKey(name: 'root')
  final String? root;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'sessions')
  final int? sessions;

  @JsonKey(name: 'last_active')
  final num? lastActive;

  Map<String, dynamic> toJson() => _$DiscoveredRepoDtoToJson(this);

  DiscoveredRepo toDomain() {
    return DiscoveredRepo(
      root: root ?? '',
      label: label ?? '',
      sessions: sessions ?? 0,
      lastActive: lastActive ?? 0,
    );
  }
}

/// Wire DTO for `projects.discover_repos` result.
@JsonSerializable()
class DiscoverReposResultDto {
  const DiscoverReposResultDto({this.repos = const <DiscoveredRepoDto>[]});

  factory DiscoverReposResultDto.fromJson(Map<String, dynamic> json) =>
      _$DiscoverReposResultDtoFromJson(json);

  @JsonKey(name: 'repos')
  final List<DiscoveredRepoDto> repos;

  Map<String, dynamic> toJson() => _$DiscoverReposResultDtoToJson(this);

  List<DiscoveredRepo> toDomain() {
    return repos.map((dto) => dto.toDomain()).toList();
  }
}
