import 'package:flit/domain/models/project_facts.dart';

/// Intent-level project facts operations (ticket P6-04).
abstract interface class ProjectFactsRepository {
  /// `project.facts {cwd?}` → detected manifests, package managers, verify
  /// commands, and context files. Returns null when cwd is NOT a code
  /// workspace (this is a normal result, not an error).
  Future<ProjectFacts?> facts({String? cwd});
}
