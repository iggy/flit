// ignore_for_file: use_null_aware_elements

import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/project_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/project.dart';
import 'package:flit/domain/repositories/projects_repository.dart';

/// [ProjectsRepository] over [GatewayRpcClient.request] (tickets P4-07, P4-08).
///
/// Method names/params come VERBATIM from the gateway wire shapes — never
/// invent protocol.
final class ProjectsRepositoryImpl implements ProjectsRepository {
  const ProjectsRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<ProjectsList> list() async {
    final result = await _client.request('projects.list');
    final dto = ProjectsListResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<Project?> get(String id) async {
    final result = await _client.request('projects.get', <String, dynamic>{
      'id': id,
    });
    final dto = ProjectResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<String?> setActive(String? id) async {
    final result = await _client.request(
      'projects.set_active',
      <String, dynamic>{'id': id},
    );
    final dto = SetActiveResultDto.fromJson(result);
    return dto.activeId;
  }

  @override
  Future<({Project? project, String cwd, String? branch})> forCwd({
    String? cwd,
  }) async {
    final result = await _client.request('projects.for_cwd', <String, dynamic>{
      if (cwd != null) 'cwd': cwd,
    });
    final dto = ForCwdResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<Project?> create({
    required String name,
    String? slug,
    List<String>? folders,
    String? primaryPath,
    String? description,
    String? icon,
    String? color,
    String? boardSlug,
    bool use = false,
  }) async {
    final result = await _client.request('projects.create', <String, dynamic>{
      'name': name,
      if (slug != null) 'slug': slug,
      if (folders != null) 'folders': folders,
      if (primaryPath != null) 'primary_path': primaryPath,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (boardSlug != null) 'board_slug': boardSlug,
      if (use) 'use': use,
    });
    final dto = ProjectResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<Project> update(
    String id, {
    String? name,
    String? description,
    String? icon,
    String? color,
    String? boardSlug,
  }) async {
    final result = await _client.request('projects.update', <String, dynamic>{
      'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (boardSlug != null) 'board_slug': boardSlug,
    });
    final dto = ProjectResultDto.fromJson(result);
    final project = dto.toDomain();
    if (project == null) {
      throw const GatewayRpcException(5062, 'Project not found');
    }
    return project;
  }

  @override
  Future<Project> addFolder(
    String id,
    String path, {
    String? label,
    bool isPrimary = false,
  }) async {
    final result = await _client
        .request('projects.add_folder', <String, dynamic>{
          'id': id,
          'path': path,
          if (label != null) 'label': label,
          if (isPrimary) 'is_primary': isPrimary,
        });
    final dto = ProjectResultDto.fromJson(result);
    final project = dto.toDomain();
    if (project == null) {
      throw const GatewayRpcException(5062, 'Project not found');
    }
    return project;
  }

  @override
  Future<Project> removeFolder(String id, String path) async {
    final result = await _client.request(
      'projects.remove_folder',
      <String, dynamic>{'id': id, 'path': path},
    );
    final dto = ProjectResultDto.fromJson(result);
    final project = dto.toDomain();
    if (project == null) {
      throw const GatewayRpcException(5062, 'Project not found');
    }
    return project;
  }

  @override
  Future<Project> setPrimary(String id, String path) async {
    final result = await _client.request(
      'projects.set_primary',
      <String, dynamic>{'id': id, 'path': path},
    );
    final dto = ProjectResultDto.fromJson(result);
    final project = dto.toDomain();
    if (project == null) {
      throw const GatewayRpcException(5062, 'Project not found');
    }
    return project;
  }

  @override
  Future<ProjectsList> archive(String id, {bool restore = false}) async {
    final result = await _client.request('projects.archive', <String, dynamic>{
      'id': id,
      if (restore) 'restore': restore,
    });
    final dto = ProjectsListResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<ProjectsList> delete(String id) async {
    final result = await _client.request('projects.delete', <String, dynamic>{
      'id': id,
    });
    final dto = ProjectsListResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<Map<String, dynamic>> projectSessions(
    String id, {
    int? sessionLimit,
  }) async {
    final result = await _client.request(
      'projects.project_sessions',
      <String, dynamic>{
        'id': id,
        if (sessionLimit != null) 'session_limit': sessionLimit,
      },
    );
    return result;
  }

  @override
  Future<List<DiscoveredRepo>> discoverRepos() async {
    final result = await _client.request('projects.discover_repos');
    final dto = DiscoverReposResultDto.fromJson(result);
    return dto.toDomain();
  }
}
