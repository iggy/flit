import 'package:flit/domain/models/project.dart';

/// Typed result for `projects.list` and similar methods that return both the
/// project list and the active project ID.
typedef ProjectsList = ({List<Project> projects, String? activeId});

/// Intent-level project operations (tickets P4-07, P4-08).
///
/// Method names and params come VERBATIM from gateway source — do not invent
/// protocol. See wire shapes documented in task description.
abstract interface class ProjectsRepository {
  /// `projects.list` → all projects + active_id.
  Future<ProjectsList> list();

  /// `projects.get` → a single project by ID (null if not found).
  Future<Project?> get(String id);

  /// `projects.set_active` → sets the active project (null clears it).
  /// Returns the new active_id.
  Future<String?> setActive(String? id);

  /// `projects.for_cwd` → project matching the given cwd (or current if
  /// omitted), plus the cwd and branch.
  Future<({Project? project, String cwd, String? branch})> forCwd({
    String? cwd,
  });

  /// `projects.create` → create a new project. Returns null on failure.
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
  });

  /// `projects.update` → update project metadata. Returns the updated project.
  Future<Project> update(
    String id, {
    String? name,
    String? description,
    String? icon,
    String? color,
    String? boardSlug,
  });

  /// `projects.add_folder` → add a folder to a project.
  Future<Project> addFolder(
    String id,
    String path, {
    String? label,
    bool isPrimary = false,
  });

  /// `projects.remove_folder` → remove a folder from a project.
  Future<Project> removeFolder(String id, String path);

  /// `projects.set_primary` → set the primary folder for a project.
  Future<Project> setPrimary(String id, String path);

  /// `projects.archive` → archive or restore a project. Returns updated list.
  Future<ProjectsList> archive(String id, {bool restore = false});

  /// `projects.delete` → delete a project. Returns updated list.
  Future<ProjectsList> delete(String id);

  /// `projects.project_sessions` → project with session/lane grouping (opaque
  /// nested structure). Returns raw map; the screen may treat it as opaque.
  Future<Map<String, dynamic>> projectSessions(
    String id, {
    int? sessionLimit,
  });

  /// `projects.discover_repos` → scan for repositories. Returns repo list.
  Future<List<DiscoveredRepo>> discoverRepos();
}
