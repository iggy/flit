/// Repository interface for kanban fleet operations & orchestration (P5-06/P5-07).
///
/// Methods match the REST surface from docs/phases/phase-5-wire-shapes.md
/// (lines 132-179) VERBATIM. Every endpoint accepts optional `board` for
/// board-scoping; null = current board.
library;

import 'package:flit/domain/models/kanban_fleet.dart';

abstract interface class KanbanFleetRepository {
  /// GET /boards — list all boards.
  Future<KanbanBoardList> listBoards({
    bool includeArchived = false,
    String? board,
  });

  /// POST /boards — create a board.
  ///
  /// [projectId] scopes the board to a first-class project (id or slug):
  /// the project's primary repo becomes the default workdir unless
  /// [defaultWorkdir] is given, and the board's tasks inherit the project.
  Future<KanbanBoardMeta?> createBoard({
    required String slug,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    String? projectId,
    bool switchTo = false,
    String? board,
  });

  /// PATCH /boards/{slug} — update board metadata (slug immutable).
  ///
  /// [projectId] follows the same convention as [defaultWorkdir]: null
  /// leaves the scope alone, `''` clears it, a value resolves and sets it.
  Future<KanbanBoardMeta?> updateBoard(
    String slug, {
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    String? projectId,
    String? board,
  });

  /// DELETE /boards/{slug} — archive (or delete if `delete=true`).
  Future<void> deleteBoard(String slug, {bool delete = false, String? board});

  /// POST /boards/{slug}/switch — switch to the given board.
  Future<String> switchBoard(String slug);

  /// GET /stats — fleet-wide statistics.
  Future<KanbanStats> stats({String? board});

  /// GET /workers/active — currently-running workers.
  Future<List<KanbanWorker>> activeWorkers({String? board});

  /// GET /diagnostics — fleet diagnostics (optional severity filter).
  Future<List<KanbanDiagnosticGroup>> diagnostics({
    String? severity,
    String? board,
  });

  /// POST /dispatch — nudge the dispatcher (dry run or real).
  Future<KanbanDispatchResult> dispatch({
    bool dryRun = false,
    int? max,
    String? board,
  });

  /// POST /runs/{id}/terminate — terminate a running worker.
  Future<void> terminateRun(int runId, {String? reason, String? board});

  /// GET /assignees — profile roster with task counts.
  Future<List<KanbanAssignee>> listAssignees({String? board});

  /// GET /profiles — agent profile roster.
  Future<List<KanbanProfile>> listProfiles();

  /// PATCH /profiles/{name} — set/clear profile description.
  Future<void> setProfileDescription(String name, String description);

  /// GET /orchestration — orchestration settings.
  Future<KanbanOrchestration> orchestration();

  /// PUT /orchestration — update orchestration settings.
  Future<KanbanOrchestration> setOrchestration({
    String? orchestratorProfile,
    String? defaultAssignee,
    bool? autoDecompose,
    bool? autoPromoteChildren,
  });
}
