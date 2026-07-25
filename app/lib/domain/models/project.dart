import 'package:flit/domain/models/deep_equals.dart';

/// One folder within a project (wire `folders` array element).
final class ProjectFolder {
  const ProjectFolder({
    required this.path,
    this.label,
    required this.isPrimary,
    required this.addedAt,
  });

  /// Filesystem path to the folder.
  final String path;

  /// Optional human-readable label.
  final String? label;

  /// Whether this folder is marked as the primary path.
  final bool isPrimary;

  /// Unix timestamp (seconds) when the folder was added.
  final int addedAt;

  @override
  bool operator ==(Object other) {
    return other is ProjectFolder &&
        other.path == path &&
        other.label == label &&
        other.isPrimary == isPrimary &&
        other.addedAt == addedAt;
  }

  @override
  int get hashCode => Object.hash(path, label, isPrimary, addedAt);

  @override
  String toString() {
    return 'ProjectFolder(path: $path, label: $label, '
        'isPrimary: $isPrimary, addedAt: $addedAt)';
  }
}

/// A project workspace (wire shape from `projects.*` methods).
final class Project {
  const Project({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.boardSlug,
    this.primaryPath,
    required this.archived,
    required this.createdAt,
    required this.folders,
  });

  /// Project ID (UUID).
  final String id;

  /// URL-safe slug.
  final String slug;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// Optional icon (emoji or identifier).
  final String? icon;

  /// Optional color hex code.
  final String? color;

  /// Optional board slug reference.
  final String? boardSlug;

  /// Primary filesystem path.
  final String? primaryPath;

  /// Whether the project is archived.
  final bool archived;

  /// Unix timestamp (seconds) when the project was created.
  final int createdAt;

  /// List of folders associated with this project.
  final List<ProjectFolder> folders;

  @override
  bool operator ==(Object other) {
    return other is Project &&
        other.id == id &&
        other.slug == slug &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.color == color &&
        other.boardSlug == boardSlug &&
        other.primaryPath == primaryPath &&
        other.archived == archived &&
        other.createdAt == createdAt &&
        deepListEquals(other.folders, folders);
  }

  @override
  int get hashCode => Object.hash(
        id,
        slug,
        name,
        description,
        icon,
        color,
        boardSlug,
        primaryPath,
        archived,
        createdAt,
        Object.hashAll(folders),
      );

  @override
  String toString() {
    return 'Project(id: $id, slug: $slug, name: $name, '
        'description: $description, icon: $icon, color: $color, '
        'boardSlug: $boardSlug, primaryPath: $primaryPath, '
        'archived: $archived, createdAt: $createdAt, folders: $folders)';
  }
}

/// A discovered repository from `projects.discover_repos`.
final class DiscoveredRepo {
  const DiscoveredRepo({
    required this.root,
    required this.label,
    required this.sessions,
    required this.lastActive,
  });

  /// Filesystem root path.
  final String root;

  /// Human-readable label.
  final String label;

  /// Number of sessions associated with this repo.
  final int sessions;

  /// Last activity timestamp.
  final num lastActive;

  @override
  bool operator ==(Object other) {
    return other is DiscoveredRepo &&
        other.root == root &&
        other.label == label &&
        other.sessions == sessions &&
        other.lastActive == lastActive;
  }

  @override
  int get hashCode => Object.hash(root, label, sessions, lastActive);

  @override
  String toString() {
    return 'DiscoveredRepo(root: $root, label: $label, '
        'sessions: $sessions, lastActive: $lastActive)';
  }
}
