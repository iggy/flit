/// [KanbanFleetRepository] over [GatewayRestClient] (P5-06/P5-07).
///
/// Endpoints from docs/phases/phase-5-wire-shapes.md (lines 132-179) —
/// never invent protocol. Hand-parsed using the defensive helpers from
/// kanban_repository.dart (no json_serializable for kanban).
library;

import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flit/domain/repositories/kanban_fleet_repository.dart';

final class KanbanFleetRepositoryImpl implements KanbanFleetRepository {
  const KanbanFleetRepositoryImpl(this._client);

  final GatewayRestClient _client;

  static const _base = '/api/plugins/kanban';

  @override
  Future<KanbanBoardList> listBoards({
    bool includeArchived = false,
    String? board,
  }) async {
    final queryParams = <String, String>{};
    if (includeArchived) {
      queryParams['include_archived'] = 'true';
    }
    if (board != null) {
      queryParams['board'] = board;
    }
    final data = await _client.getJson(
      '$_base/boards',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final map = _expectMap(data, 'GET $_base/boards');
    return _parseBoardList(map);
  }

  @override
  Future<KanbanBoardMeta?> createBoard({
    required String slug,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    bool switchTo = false,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{'slug': slug};
    if (name != null) {
      requestBody['name'] = name;
    }
    if (description != null) {
      requestBody['description'] = description;
    }
    if (icon != null) {
      requestBody['icon'] = icon;
    }
    if (color != null) {
      requestBody['color'] = color;
    }
    if (defaultWorkdir != null) {
      requestBody['default_workdir'] = defaultWorkdir;
    }
    if (switchTo) {
      requestBody['switch'] = switchTo;
    }

    final data = await _client.postJson(
      '$_base/boards',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
    final map = _expectMap(data, 'POST $_base/boards');
    final boardData = map['board'];
    if (boardData is Map<String, dynamic>) {
      return _parseBoardMeta(boardData);
    }
    return null;
  }

  @override
  Future<KanbanBoardMeta?> updateBoard(
    String slug, {
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{};
    if (name != null) {
      requestBody['name'] = name;
    }
    if (description != null) {
      requestBody['description'] = description;
    }
    if (icon != null) {
      requestBody['icon'] = icon;
    }
    if (color != null) {
      requestBody['color'] = color;
    }
    if (defaultWorkdir != null) {
      requestBody['default_workdir'] = defaultWorkdir;
    }

    final data = await _client.patchJson(
      '$_base/boards/$slug',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
    final map = _expectMap(data, 'PATCH $_base/boards/$slug');
    final boardData = map['board'];
    if (boardData is Map<String, dynamic>) {
      return _parseBoardMeta(boardData);
    }
    return null;
  }

  @override
  Future<void> deleteBoard(
    String slug, {
    bool delete = false,
    String? board,
  }) async {
    final queryParams = <String, String>{};
    if (delete) {
      queryParams['delete'] = 'true';
    }
    if (board != null) {
      queryParams['board'] = board;
    }
    await _client.deleteJson(
      '$_base/boards/$slug',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  @override
  Future<String> switchBoard(String slug) async {
    final data = await _client.postJson('$_base/boards/$slug/switch');
    final map = _expectMap(data, 'POST $_base/boards/$slug/switch');
    return _stringOrNull(map['current']) ?? '';
  }

  @override
  Future<KanbanStats> stats({String? board}) async {
    final data = await _client.getJson(
      '$_base/stats',
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
    final map = _expectMap(data, 'GET $_base/stats');
    return _parseStats(map);
  }

  @override
  Future<List<KanbanWorker>> activeWorkers({String? board}) async {
    final data = await _client.getJson(
      '$_base/workers/active',
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
    final map = _expectMap(data, 'GET $_base/workers/active');
    final workersList = _mapList(map['workers']);
    return workersList.map(_parseWorker).toList();
  }

  @override
  Future<List<KanbanDiagnosticGroup>> diagnostics({
    String? severity,
    String? board,
  }) async {
    final queryParams = <String, String>{};
    if (severity != null) {
      queryParams['severity'] = severity;
    }
    if (board != null) {
      queryParams['board'] = board;
    }
    final data = await _client.getJson(
      '$_base/diagnostics',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final map = _expectMap(data, 'GET $_base/diagnostics');
    final diagnosticsList = _mapList(map['diagnostics']);
    return diagnosticsList.map(_parseDiagnosticGroup).toList();
  }

  @override
  Future<KanbanDispatchResult> dispatch({
    bool dryRun = false,
    int? max,
    String? board,
  }) async {
    final queryParams = <String, String>{};
    if (dryRun) {
      queryParams['dry_run'] = 'true';
    }
    if (max != null) {
      queryParams['max'] = max.toString();
    }
    if (board != null) {
      queryParams['board'] = board;
    }
    final data = await _client.postJson(
      '$_base/dispatch',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final map = _expectMap(data, 'POST $_base/dispatch');
    return _parseDispatchResult(map);
  }

  @override
  Future<void> terminateRun(
    int runId, {
    String? reason,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{};
    if (reason != null) {
      requestBody['reason'] = reason;
    }

    await _client.postJson(
      '$_base/runs/$runId/terminate',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
  }

  @override
  Future<List<KanbanAssignee>> listAssignees({String? board}) async {
    final data = await _client.getJson(
      '$_base/assignees',
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
    final map = _expectMap(data, 'GET $_base/assignees');
    final assigneesList = _mapList(map['assignees']);
    return assigneesList.map(_parseAssignee).toList();
  }

  @override
  Future<List<KanbanProfile>> listProfiles() async {
    final data = await _client.getJson('$_base/profiles');
    final map = _expectMap(data, 'GET $_base/profiles');
    final profilesList = _mapList(map['profiles']);
    return profilesList.map(_parseProfile).toList();
  }

  @override
  Future<void> setProfileDescription(String name, String description) async {
    final requestBody = <String, dynamic>{'description': description};
    await _client.patchJson('$_base/profiles/$name', body: requestBody);
  }

  @override
  Future<KanbanOrchestration> orchestration() async {
    final data = await _client.getJson('$_base/orchestration');
    final map = _expectMap(data, 'GET $_base/orchestration');
    return _parseOrchestration(map);
  }

  @override
  Future<KanbanOrchestration> setOrchestration({
    String? orchestratorProfile,
    String? defaultAssignee,
    bool? autoDecompose,
    bool? autoPromoteChildren,
  }) async {
    final requestBody = <String, dynamic>{};
    if (orchestratorProfile != null) {
      requestBody['orchestrator_profile'] = orchestratorProfile;
    }
    if (defaultAssignee != null) {
      requestBody['default_assignee'] = defaultAssignee;
    }
    if (autoDecompose != null) {
      requestBody['auto_decompose'] = autoDecompose;
    }
    if (autoPromoteChildren != null) {
      requestBody['auto_promote_children'] = autoPromoteChildren;
    }

    final data = await _client.putJson('$_base/orchestration', body: requestBody);
    final map = _expectMap(data, 'PUT $_base/orchestration');
    return _parseOrchestration(map);
  }

  // ---- wire → domain translation (defensive parsing) --

  static Map<String, dynamic> _expectMap(Object? data, String what) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw GatewayParseException('$what returned an unexpected body.');
  }

  static String? _stringOrNull(Object? value) {
    if (value is String) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  static int? _intOrNull(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static bool _boolOr(Object? value, bool fallback) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  static DateTime? _epochSeconds(Object? value) {
    final seconds = _intOrNull(value);
    if (seconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value.whereType<Map<String, dynamic>>().toList();
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList();
  }

  static Map<String, int> _stringIntMap(Object? value) {
    if (value is! Map) {
      return const <String, int>{};
    }
    final result = <String, int>{};
    for (final entry in value.entries) {
      if (entry.key is String) {
        final intValue = _intOrNull(entry.value);
        if (intValue != null) {
          result[entry.key as String] = intValue;
        }
      }
    }
    return result;
  }

  static Map<String, Map<String, int>> _stringMapIntMap(Object? value) {
    if (value is! Map) {
      return const <String, Map<String, int>>{};
    }
    final result = <String, Map<String, int>>{};
    for (final entry in value.entries) {
      if (entry.key is String) {
        final nested = _stringIntMap(entry.value);
        result[entry.key as String] = nested;
      }
    }
    return result;
  }

  static KanbanBoardList _parseBoardList(Map<String, dynamic> json) {
    final boardsList = _mapList(json['boards']);
    final boards = boardsList.map(_parseBoardMeta).toList();
    final current = _stringOrNull(json['current']) ?? '';
    return KanbanBoardList(boards: boards, current: current);
  }

  static KanbanBoardMeta _parseBoardMeta(Map<String, dynamic> json) {
    return KanbanBoardMeta(
      slug: _stringOrNull(json['slug']) ?? '',
      name: _stringOrNull(json['name']) ?? '',
      description: _stringOrNull(json['description']) ?? '',
      icon: _stringOrNull(json['icon']) ?? '',
      color: _stringOrNull(json['color']) ?? '',
      defaultWorkdir: _stringOrNull(json['default_workdir']),
      createdAt: _epochSeconds(json['created_at']),
      archived: _boolOr(json['archived'], false),
      dbPath: _stringOrNull(json['db_path']) ?? '',
      isCurrent: _boolOr(json['is_current'], false),
      counts: _stringIntMap(json['counts']),
      total: _intOrNull(json['total']) ?? 0,
      defaultWorkspaceKind: _stringOrNull(json['default_workspace_kind']) ?? '',
    );
  }

  static KanbanStats _parseStats(Map<String, dynamic> json) {
    return KanbanStats(
      byStatus: _stringIntMap(json['by_status']),
      byAssignee: _stringMapIntMap(json['by_assignee']),
      oldestReadyAgeSeconds: _intOrNull(json['oldest_ready_age_seconds']),
      now: _epochSeconds(json['now']),
    );
  }

  static KanbanWorker _parseWorker(Map<String, dynamic> json) {
    return KanbanWorker(
      runId: _intOrNull(json['run_id']) ?? 0,
      taskId: _stringOrNull(json['task_id']) ?? '',
      taskTitle: _stringOrNull(json['task_title']) ?? '',
      taskStatus: _stringOrNull(json['task_status']) ?? '',
      taskAssignee: _stringOrNull(json['task_assignee']),
      profile: _stringOrNull(json['profile']),
      workerPid: _intOrNull(json['worker_pid']) ?? 0,
      startedAt: _epochSeconds(json['started_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastHeartbeatAt: _epochSeconds(json['last_heartbeat_at']),
      maxRuntimeSeconds: _intOrNull(json['max_runtime_seconds']),
    );
  }

  static KanbanDiagnosticGroup _parseDiagnosticGroup(Map<String, dynamic> json) {
    final diagnosticsList = _mapList(json['diagnostics']);
    final diagnostics = diagnosticsList.map(_parseDiagnostic).toList();
    return KanbanDiagnosticGroup(
      taskId: _stringOrNull(json['task_id']) ?? '',
      taskTitle: _stringOrNull(json['task_title']),
      taskStatus: _stringOrNull(json['task_status']),
      taskAssignee: _stringOrNull(json['task_assignee']),
      diagnostics: diagnostics,
    );
  }

  static KanbanDiagnostic _parseDiagnostic(Map<String, dynamic> json) {
    return KanbanDiagnostic(
      kind: _stringOrNull(json['kind']) ?? '',
      severity: _stringOrNull(json['severity']) ?? '',
      title: _stringOrNull(json['title']) ?? '',
      detail: _stringOrNull(json['detail']) ?? '',
      firstSeenAt: _epochSeconds(json['first_seen_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastSeenAt: _epochSeconds(json['last_seen_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      count: _intOrNull(json['count']) ?? 0,
      runId: _intOrNull(json['run_id']),
    );
  }

  static KanbanDispatchResult _parseDispatchResult(Map<String, dynamic> json) {
    final spawnedList = json['spawned'];
    final spawnedCount = spawnedList is List ? spawnedList.length : 0;
    return KanbanDispatchResult(
      reclaimed: _intOrNull(json['reclaimed']) ?? 0,
      promoted: _intOrNull(json['promoted']) ?? 0,
      spawnedCount: spawnedCount,
      skippedUnassigned: _stringList(json['skipped_unassigned']),
    );
  }

  static KanbanAssignee _parseAssignee(Map<String, dynamic> json) {
    return KanbanAssignee(
      name: _stringOrNull(json['name']) ?? '',
      onDisk: _boolOr(json['on_disk'], false),
      counts: _stringIntMap(json['counts']),
    );
  }

  static KanbanProfile _parseProfile(Map<String, dynamic> json) {
    return KanbanProfile(
      name: _stringOrNull(json['name']) ?? '',
      isDefault: _boolOr(json['is_default'], false),
      model: _stringOrNull(json['model']) ?? '',
      provider: _stringOrNull(json['provider']) ?? '',
      description: _stringOrNull(json['description']) ?? '',
      descriptionAuto: _boolOr(json['description_auto'], false),
      skillCount: _intOrNull(json['skill_count']) ?? 0,
    );
  }

  static KanbanOrchestration _parseOrchestration(Map<String, dynamic> json) {
    return KanbanOrchestration(
      orchestratorProfile: _stringOrNull(json['orchestrator_profile']) ?? '',
      defaultAssignee: _stringOrNull(json['default_assignee']) ?? '',
      autoDecompose: _boolOr(json['auto_decompose'], false),
      autoPromoteChildren: _boolOr(json['auto_promote_children'], false),
      resolvedOrchestratorProfile: _stringOrNull(json['resolved_orchestrator_profile']) ?? '',
      resolvedDefaultAssignee: _stringOrNull(json['resolved_default_assignee']) ?? '',
      activeProfile: _stringOrNull(json['active_profile']) ?? '',
    );
  }
}
