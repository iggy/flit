import 'package:flit/domain/models/deep_equals.dart';

/// Domain model for project facts (ticket P6-04).
///
/// Wire shape: `project.facts {cwd?}` → `{facts: {root, manifests, ...}}`.
/// A null facts result is NORMAL (not a code workspace).
final class ProjectFacts {
  const ProjectFacts({
    required this.root,
    required this.manifests,
    required this.packageManagers,
    required this.verifyCommands,
    required this.contextFiles,
  });

  /// Project root path.
  final String root;

  /// Detected manifest files (e.g., pubspec.yaml, package.json).
  final List<String> manifests;

  /// Detected package managers (e.g., dart, npm).
  final List<String> packageManagers;

  /// Detected verify commands (e.g., flutter analyze, flutter test).
  final List<String> verifyCommands;

  /// Detected context files (e.g., CLAUDE.md, AGENTS.md).
  final List<String> contextFiles;

  @override
  bool operator ==(Object other) {
    return other is ProjectFacts &&
        other.root == root &&
        deepListEquals(other.manifests, manifests) &&
        deepListEquals(other.packageManagers, packageManagers) &&
        deepListEquals(other.verifyCommands, verifyCommands) &&
        deepListEquals(other.contextFiles, contextFiles);
  }

  @override
  int get hashCode => Object.hash(
    root,
    Object.hashAll(manifests),
    Object.hashAll(packageManagers),
    Object.hashAll(verifyCommands),
    Object.hashAll(contextFiles),
  );

  @override
  String toString() =>
      'ProjectFacts(root: $root, manifests: $manifests, packageManagers: $packageManagers, verifyCommands: $verifyCommands, contextFiles: $contextFiles)';
}
