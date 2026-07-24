import 'package:hermes/domain/models/kanban.dart';

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
}
