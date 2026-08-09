import 'package:flit/domain/models/kanban.dart';

/// Intent-level kanban plugin operations (ticket P1-15) — the kanban plugin
/// exposes NO JSON-RPC; its whole surface is REST under
/// `/api/plugins/kanban/` (06-kanban-rest.md). MVP scope only: board read,
/// task detail, status move. Everything else is Phase 5.
abstract interface class KanbanRepository {
  /// `GET /api/plugins/kanban/board` (optional `?board=<slug>`) → the whole
  /// board envelope in one call.
  Future<KanbanBoard> board({String? board});

  /// `GET /api/plugins/kanban/tasks/{id}` → task + comments (+ raw extras).
  Future<KanbanTaskDetail> task(String id);

  /// `PATCH /api/plugins/kanban/tasks/{id}` with `{status: status}` — moving
  /// a card between columns IS a status update (the column name doubles as
  /// the status value).
  Future<void> updateTaskStatus(String id, String status);

  /// `POST /api/plugins/kanban/tasks` — create a task (P5-05).
  /// Returns the created task or null on failure.
  ///
  /// [modelOverride] / [providerOverride] / [reasoningEffort] pin the
  /// dispatched worker's model and thinking depth; [goalMode] runs it as a
  /// goal loop bounded by [goalMaxTurns]; [projectId] anchors the task to a
  /// project (a project-scoped board supplies one when this is omitted).
  Future<KanbanTask?> createTask({
    required String title,
    String? body,
    String? assignee,
    String? tenant,
    int? priority,
    String? workspaceKind,
    List<String>? parents,
    bool? triage,
    List<String>? skills,
    String? modelOverride,
    String? providerOverride,
    String? reasoningEffort,
    bool? goalMode,
    int? goalMaxTurns,
    int? maxRuntimeSeconds,
    String? projectId,
    String? board,
  });

  /// `PATCH /api/plugins/kanban/tasks/{id}` — general update (P5-05).
  /// Returns the updated task or null.
  ///
  /// The two clear flags exist because a PATCH can't say "set to NULL" with
  /// an omitted field: [clearModelOverride] drops the model AND provider
  /// override, [clearReasoningEffort] falls the depth back to the profile.
  /// They are separate so dropping a model doesn't reset a chosen depth,
  /// and `reasoningEffort: 'none'` is a VALUE (thinking off), not a clear.
  Future<KanbanTask?> editTask(
    String id, {
    String? status,
    String? assignee,
    int? priority,
    String? title,
    String? body,
    String? result,
    String? blockReason,
    String? summary,
    String? modelOverride,
    String? providerOverride,
    bool clearModelOverride = false,
    String? reasoningEffort,
    bool clearReasoningEffort = false,
    String? board,
  });

  /// `DELETE /api/plugins/kanban/tasks/{id}` (P5-05).
  Future<void> deleteTask(String id, {String? board});

  /// `POST /api/plugins/kanban/tasks/bulk` — bulk update (P5-05).
  Future<KanbanBulkResult> bulkUpdate({
    required List<String> ids,
    String? status,
    String? assignee,
    int? priority,
    bool? archive,
    bool? reclaimFirst,
    String? board,
  });

  /// `POST /api/plugins/kanban/tasks/{id}/comments` — add comment (P5-05).
  Future<void> addComment(
    String id, {
    required String body,
    String? author,
    String? board,
  });

  /// `POST /api/plugins/kanban/tasks/{id}/specify` — LLM specify (P5-05).
  Future<KanbanSpecifyResult> specify(
    String id, {
    String? author,
    String? board,
  });

  /// `POST /api/plugins/kanban/tasks/{id}/decompose` — LLM decompose (P5-05).
  Future<KanbanDecomposeResult> decompose(
    String id, {
    String? author,
    String? board,
  });

  /// `POST /api/plugins/kanban/tasks/{id}/estimate` — rough token +
  /// complexity estimate for a stored task via the gateway's auxiliary model.
  ///
  /// Runs several seconds (an LLM call). A refusal comes back as
  /// `KanbanEstimate.ok == false` with a reason, NOT as an exception — only
  /// transport/auth failures throw.
  Future<KanbanEstimate> estimateTask(String id, {String? board});

  /// `POST /api/plugins/kanban/tasks/{id}/reassign` — reassign task (P5-05).
  Future<void> reassign(
    String id, {
    String? profile,
    bool reclaimFirst = false,
    String? reason,
    String? board,
  });

  /// `POST /api/plugins/kanban/tasks/{id}/reclaim` — reclaim stuck task (P5-05).
  Future<void> reclaim(String id, {String? reason, String? board});

  /// `POST /api/plugins/kanban/links` — add parent-child link (P5-05).
  Future<void> addLink({
    required String parentId,
    required String childId,
    String? board,
  });

  /// `DELETE /api/plugins/kanban/links` — remove link (P5-05).
  Future<void> removeLink({
    required String parentId,
    required String childId,
    String? board,
  });
}
