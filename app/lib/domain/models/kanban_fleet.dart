/// Fleet operations & orchestration models for kanban (P5-06/P5-07).
///
/// Hand-written immutable models following the wire shapes from
/// docs/phases/phase-5-wire-shapes.md (lines 132-179). Timestamps are epoch
/// seconds converted to DateTime; defensive equals on lists/maps via
/// deep_equals.dart helpers.
library;

import 'package:flit/domain/models/deep_equals.dart';

/// Metadata for one kanban board (GET /boards).
final class KanbanBoardMeta {
  const KanbanBoardMeta({
    required this.slug,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.defaultWorkdir,
    this.createdAt,
    required this.archived,
    required this.dbPath,
    required this.isCurrent,
    required this.counts,
    required this.total,
    required this.defaultWorkspaceKind,
    this.projectId,
    this.projectName,
  });

  final String slug;
  final String name;
  final String description;
  final String icon;
  final String color;
  final String? defaultWorkdir;
  final DateTime? createdAt;
  final bool archived;
  final String dbPath;
  final bool isCurrent;
  final Map<String, int> counts;
  final int total;
  final String defaultWorkspaceKind;

  /// First-class project this board is scoped to; null = unscoped. A scoped
  /// board mirrors the project's primary repo as its `default_workdir` and
  /// its tasks inherit the project.
  final String? projectId;

  /// Display name for [projectId], resolved server-side. Null when the
  /// board is unscoped or the project no longer exists.
  final String? projectName;

  @override
  bool operator ==(Object other) {
    return other is KanbanBoardMeta &&
        other.slug == slug &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.color == color &&
        other.defaultWorkdir == defaultWorkdir &&
        other.createdAt == createdAt &&
        other.archived == archived &&
        other.dbPath == dbPath &&
        other.isCurrent == isCurrent &&
        shallowMapEquals(other.counts, counts) &&
        other.total == total &&
        other.defaultWorkspaceKind == defaultWorkspaceKind &&
        other.projectId == projectId &&
        other.projectName == projectName;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    slug,
    name,
    description,
    icon,
    color,
    defaultWorkdir,
    createdAt,
    archived,
    dbPath,
    isCurrent,
    Object.hashAll(counts.entries.map((e) => Object.hash(e.key, e.value))),
    total,
    defaultWorkspaceKind,
    projectId,
    projectName,
  ]);

  @override
  String toString() {
    return 'KanbanBoardMeta(slug: $slug, name: $name, isCurrent: $isCurrent, total: $total)';
  }
}

/// List of boards + the current board slug (GET /boards).
final class KanbanBoardList {
  const KanbanBoardList({required this.boards, required this.current});

  final List<KanbanBoardMeta> boards;
  final String current;

  @override
  bool operator ==(Object other) {
    return other is KanbanBoardList &&
        deepListEquals(other.boards, boards) &&
        other.current == current;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(boards), current);

  @override
  String toString() {
    return 'KanbanBoardList(boards: ${boards.length}, current: $current)';
  }
}

/// Fleet-wide stats (GET /stats).
final class KanbanStats {
  const KanbanStats({
    required this.byStatus,
    required this.byAssignee,
    this.oldestReadyAgeSeconds,
    this.now,
  });

  final Map<String, int> byStatus;
  final Map<String, Map<String, int>> byAssignee;
  final int? oldestReadyAgeSeconds;
  final DateTime? now;

  @override
  bool operator ==(Object other) {
    return other is KanbanStats &&
        shallowMapEquals(other.byStatus, byStatus) &&
        _deepMapMapEquals(other.byAssignee, byAssignee) &&
        other.oldestReadyAgeSeconds == oldestReadyAgeSeconds &&
        other.now == now;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(byStatus.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(
      byAssignee.entries.map(
        (e) => Object.hash(
          e.key,
          Object.hashAll(
            e.value.entries.map((ee) => Object.hash(ee.key, ee.value)),
          ),
        ),
      ),
    ),
    oldestReadyAgeSeconds,
    now,
  );

  @override
  String toString() {
    return 'KanbanStats(byStatus: $byStatus, oldestReadyAgeSeconds: $oldestReadyAgeSeconds)';
  }

  static bool _deepMapMapEquals(
    Map<String, Map<String, int>> a,
    Map<String, Map<String, int>> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) {
        return false;
      }
      if (!shallowMapEquals(b[entry.key]!, entry.value)) {
        return false;
      }
    }
    return true;
  }
}

/// One active worker (GET /workers/active).
final class KanbanWorker {
  const KanbanWorker({
    required this.runId,
    required this.taskId,
    required this.taskTitle,
    required this.taskStatus,
    this.taskAssignee,
    this.profile,
    required this.workerPid,
    required this.startedAt,
    this.lastHeartbeatAt,
    this.maxRuntimeSeconds,
  });

  final int runId;
  final String taskId;
  final String taskTitle;
  final String taskStatus;
  final String? taskAssignee;
  final String? profile;
  final int workerPid;
  final DateTime startedAt;
  final DateTime? lastHeartbeatAt;
  final int? maxRuntimeSeconds;

  @override
  bool operator ==(Object other) {
    return other is KanbanWorker &&
        other.runId == runId &&
        other.taskId == taskId &&
        other.taskTitle == taskTitle &&
        other.taskStatus == taskStatus &&
        other.taskAssignee == taskAssignee &&
        other.profile == profile &&
        other.workerPid == workerPid &&
        other.startedAt == startedAt &&
        other.lastHeartbeatAt == lastHeartbeatAt &&
        other.maxRuntimeSeconds == maxRuntimeSeconds;
  }

  @override
  int get hashCode => Object.hash(
    runId,
    taskId,
    taskTitle,
    taskStatus,
    taskAssignee,
    profile,
    workerPid,
    startedAt,
    lastHeartbeatAt,
    maxRuntimeSeconds,
  );

  @override
  String toString() {
    return 'KanbanWorker(runId: $runId, taskId: $taskId, taskTitle: $taskTitle)';
  }
}

/// One diagnostic finding (nested in KanbanDiagnosticGroup).
final class KanbanDiagnostic {
  const KanbanDiagnostic({
    required this.kind,
    required this.severity,
    required this.title,
    required this.detail,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.count,
    this.runId,
  });

  final String kind;
  final String severity;
  final String title;
  final String detail;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int count;
  final int? runId;

  @override
  bool operator ==(Object other) {
    return other is KanbanDiagnostic &&
        other.kind == kind &&
        other.severity == severity &&
        other.title == title &&
        other.detail == detail &&
        other.firstSeenAt == firstSeenAt &&
        other.lastSeenAt == lastSeenAt &&
        other.count == count &&
        other.runId == runId;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    severity,
    title,
    detail,
    firstSeenAt,
    lastSeenAt,
    count,
    runId,
  );

  @override
  String toString() {
    return 'KanbanDiagnostic(severity: $severity, title: $title, count: $count)';
  }
}

/// Diagnostics grouped by task (GET /diagnostics).
final class KanbanDiagnosticGroup {
  const KanbanDiagnosticGroup({
    required this.taskId,
    this.taskTitle,
    this.taskStatus,
    this.taskAssignee,
    required this.diagnostics,
  });

  final String taskId;
  final String? taskTitle;
  final String? taskStatus;
  final String? taskAssignee;
  final List<KanbanDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) {
    return other is KanbanDiagnosticGroup &&
        other.taskId == taskId &&
        other.taskTitle == taskTitle &&
        other.taskStatus == taskStatus &&
        other.taskAssignee == taskAssignee &&
        deepListEquals(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    taskTitle,
    taskStatus,
    taskAssignee,
    Object.hashAll(diagnostics),
  );

  @override
  String toString() {
    return 'KanbanDiagnosticGroup(taskId: $taskId, diagnostics: ${diagnostics.length})';
  }
}

/// Dispatch result (POST /dispatch).
final class KanbanDispatchResult {
  const KanbanDispatchResult({
    required this.reclaimed,
    required this.promoted,
    required this.spawnedCount,
    required this.skippedUnassigned,
  });

  final int reclaimed;
  final int promoted;
  final int spawnedCount;
  final List<String> skippedUnassigned;

  @override
  bool operator ==(Object other) {
    return other is KanbanDispatchResult &&
        other.reclaimed == reclaimed &&
        other.promoted == promoted &&
        other.spawnedCount == spawnedCount &&
        deepListEquals(other.skippedUnassigned, skippedUnassigned);
  }

  @override
  int get hashCode => Object.hash(
    reclaimed,
    promoted,
    spawnedCount,
    Object.hashAll(skippedUnassigned),
  );

  @override
  String toString() {
    return 'KanbanDispatchResult(reclaimed: $reclaimed, promoted: $promoted, spawned: $spawnedCount)';
  }
}

/// One assignee (profile) with task counts (GET /assignees).
final class KanbanAssignee {
  const KanbanAssignee({
    required this.name,
    required this.onDisk,
    required this.counts,
  });

  final String name;
  final bool onDisk;
  final Map<String, int> counts;

  @override
  bool operator ==(Object other) {
    return other is KanbanAssignee &&
        other.name == name &&
        other.onDisk == onDisk &&
        shallowMapEquals(other.counts, counts);
  }

  @override
  int get hashCode => Object.hash(
    name,
    onDisk,
    Object.hashAll(counts.entries.map((e) => Object.hash(e.key, e.value))),
  );

  @override
  String toString() {
    return 'KanbanAssignee(name: $name, onDisk: $onDisk)';
  }
}

/// One agent profile (GET /profiles).
final class KanbanProfile {
  const KanbanProfile({
    required this.name,
    required this.isDefault,
    required this.model,
    required this.provider,
    required this.description,
    required this.descriptionAuto,
    required this.skillCount,
  });

  final String name;
  final bool isDefault;
  final String model;
  final String provider;
  final String description;
  final bool descriptionAuto;
  final int skillCount;

  @override
  bool operator ==(Object other) {
    return other is KanbanProfile &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.model == model &&
        other.provider == provider &&
        other.description == description &&
        other.descriptionAuto == descriptionAuto &&
        other.skillCount == skillCount;
  }

  @override
  int get hashCode => Object.hash(
    name,
    isDefault,
    model,
    provider,
    description,
    descriptionAuto,
    skillCount,
  );

  @override
  String toString() {
    return 'KanbanProfile(name: $name, isDefault: $isDefault, model: $model)';
  }
}

/// Orchestration knobs (GET/PUT /orchestration).
final class KanbanOrchestration {
  const KanbanOrchestration({
    required this.orchestratorProfile,
    required this.defaultAssignee,
    required this.autoDecompose,
    required this.autoPromoteChildren,
    required this.resolvedOrchestratorProfile,
    required this.resolvedDefaultAssignee,
    required this.activeProfile,
  });

  final String orchestratorProfile;
  final String defaultAssignee;
  final bool autoDecompose;
  final bool autoPromoteChildren;
  final String resolvedOrchestratorProfile;
  final String resolvedDefaultAssignee;
  final String activeProfile;

  @override
  bool operator ==(Object other) {
    return other is KanbanOrchestration &&
        other.orchestratorProfile == orchestratorProfile &&
        other.defaultAssignee == defaultAssignee &&
        other.autoDecompose == autoDecompose &&
        other.autoPromoteChildren == autoPromoteChildren &&
        other.resolvedOrchestratorProfile == resolvedOrchestratorProfile &&
        other.resolvedDefaultAssignee == resolvedDefaultAssignee &&
        other.activeProfile == activeProfile;
  }

  @override
  int get hashCode => Object.hash(
    orchestratorProfile,
    defaultAssignee,
    autoDecompose,
    autoPromoteChildren,
    resolvedOrchestratorProfile,
    resolvedDefaultAssignee,
    activeProfile,
  );

  @override
  String toString() {
    return 'KanbanOrchestration(orchestratorProfile: $orchestratorProfile, defaultAssignee: $defaultAssignee)';
  }
}
