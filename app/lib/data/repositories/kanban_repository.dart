import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/domain/repositories/kanban_repository.dart';

/// [KanbanRepository] over [GatewayRestClient] (ticket P1-15).
///
/// Endpoints come VERBATIM from docs/reference/06-kanban-rest.md (MVP scope:
/// `GET /board`, `GET /tasks/{id}`, `PATCH /tasks/{id}`) — never invent
/// protocol. Auth + typed errors are handled by the REST client.
///
/// ## Parsing (sanctioned defensive field list)
///
/// The board fetch also forwards the server's `workflow_template_id` /
/// `current_step_key` filters; see [board].
///
/// The docs pin the board ENVELOPE exactly (`columns[{name, tasks[]}]`,
/// `tenants`, `assignees`, `latest_event_id`, `now`) and the derived task
/// fields (`age`, `latest_summary`, `link_counts {parents, children}`,
/// `comment_count`, `progress {done,total}|null`), but NOT the Task
/// dataclass's own fields. Per the ticket, these identity fields are parsed
/// defensively — string-or-num coerced to string, missing → null/empty:
/// `id`, `title`, `status`, `body`, `assignee`, `priority`, `tenant`.
/// Rendering tolerates any of them being absent; parsing never throws on a
/// missing task key. The 0.20 execution block (`model_override`,
/// `reasoning_effort`, `goal_mode`, `project_id`, the block/failure counters,
/// the claim fields — see [KanbanTask]) is parsed the same way.
final class KanbanRepositoryImpl implements KanbanRepository {
  const KanbanRepositoryImpl(this._client);

  final GatewayRestClient _client;

  static const _base = '/api/plugins/kanban';

  @override
  Future<KanbanBoard> board({
    String? board,
    String? workflowTemplateId,
    String? currentStepKey,
  }) async {
    // Every filter is omitted when null — the server treats a PRESENT param
    // as an equality predicate, so sending an empty string would filter for
    // empty values rather than clear the filter.
    final queryParameters = <String, String>{
      'board': ?board,
      'workflow_template_id': ?workflowTemplateId,
      'current_step_key': ?currentStepKey,
    };
    final data = await _client.getJson(
      '$_base/board',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return _parseBoard(_expectMap(data, 'GET $_base/board'));
  }

  @override
  Future<KanbanTaskDetail> task(String id) async {
    final data = await _client.getJson('$_base/tasks/$id');
    return _parseTaskDetail(_expectMap(data, 'GET $_base/tasks/$id'));
  }

  @override
  Future<void> updateTaskStatus(String id, String status) async {
    // Moving a card between columns IS a status update — the column name
    // doubles as the status value (06-kanban-rest.md MVP scope).
    await _client.patchJson(
      '$_base/tasks/$id',
      body: <String, dynamic>{'status': status},
    );
  }

  @override
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
  }) async {
    final requestBody = <String, dynamic>{'title': title};
    if (body != null) {
      requestBody['body'] = body;
    }
    if (assignee != null) {
      requestBody['assignee'] = assignee;
    }
    if (tenant != null) {
      requestBody['tenant'] = tenant;
    }
    if (priority != null) {
      requestBody['priority'] = priority;
    }
    if (workspaceKind != null) {
      requestBody['workspace_kind'] = workspaceKind;
    }
    if (parents != null) {
      requestBody['parents'] = parents;
    }
    if (triage != null) {
      requestBody['triage'] = triage;
    }
    if (skills != null) {
      requestBody['skills'] = skills;
    }
    if (modelOverride != null) {
      requestBody['model_override'] = modelOverride;
    }
    if (providerOverride != null) {
      requestBody['provider_override'] = providerOverride;
    }
    if (reasoningEffort != null) {
      requestBody['reasoning_effort'] = reasoningEffort;
    }
    if (goalMode != null) {
      requestBody['goal_mode'] = goalMode;
    }
    if (goalMaxTurns != null) {
      requestBody['goal_max_turns'] = goalMaxTurns;
    }
    if (maxRuntimeSeconds != null) {
      requestBody['max_runtime_seconds'] = maxRuntimeSeconds;
    }
    if (projectId != null) {
      requestBody['project_id'] = projectId;
    }

    final data = await _client.postJson(
      '$_base/tasks',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );

    final map = _expectMap(data, 'POST $_base/tasks');
    final taskData = map['task'];
    if (taskData is Map<String, dynamic>) {
      return _parseTask(taskData);
    }
    return null;
  }

  @override
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
  }) async {
    final requestBody = <String, dynamic>{};
    if (status != null) {
      requestBody['status'] = status;
    }
    if (assignee != null) {
      requestBody['assignee'] = assignee;
    }
    if (priority != null) {
      requestBody['priority'] = priority;
    }
    if (title != null) {
      requestBody['title'] = title;
    }
    if (body != null) {
      requestBody['body'] = body;
    }
    if (result != null) {
      requestBody['result'] = result;
    }
    if (blockReason != null) {
      requestBody['block_reason'] = blockReason;
    }
    if (summary != null) {
      requestBody['summary'] = summary;
    }
    if (modelOverride != null) {
      requestBody['model_override'] = modelOverride;
    }
    if (providerOverride != null) {
      requestBody['provider_override'] = providerOverride;
    }
    // An omitted field means "unchanged" in a PATCH, so clearing needs its
    // own flag; the model clear takes both overrides with it.
    if (clearModelOverride) {
      requestBody['clear_model_override'] = true;
    }
    if (reasoningEffort != null) {
      requestBody['reasoning_effort'] = reasoningEffort;
    }
    if (clearReasoningEffort) {
      requestBody['clear_reasoning_effort'] = true;
    }

    final data = await _client.patchJson(
      '$_base/tasks/$id',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );

    final map = _expectMap(data, 'PATCH $_base/tasks/$id');
    final taskData = map['task'];
    if (taskData is Map<String, dynamic>) {
      return _parseTask(taskData);
    }
    return null;
  }

  @override
  Future<void> deleteTask(String id, {String? board}) async {
    await _client.deleteJson(
      '$_base/tasks/$id',
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
  }

  @override
  Future<KanbanBulkResult> bulkUpdate({
    required List<String> ids,
    String? status,
    String? assignee,
    int? priority,
    bool? archive,
    bool? reclaimFirst,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{'ids': ids};
    if (status != null) {
      requestBody['status'] = status;
    }
    if (assignee != null) {
      requestBody['assignee'] = assignee;
    }
    if (priority != null) {
      requestBody['priority'] = priority;
    }
    if (archive != null) {
      requestBody['archive'] = archive;
    }
    if (reclaimFirst != null) {
      requestBody['reclaim_first'] = reclaimFirst;
    }

    final data = await _client.postJson(
      '$_base/tasks/bulk',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );

    final map = _expectMap(data, 'POST $_base/tasks/bulk');
    return _parseBulkResult(map);
  }

  @override
  Future<void> addComment(
    String id, {
    required String body,
    String? author,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{'body': body};
    if (author != null) {
      requestBody['author'] = author;
    }

    await _client.postJson(
      '$_base/tasks/$id/comments',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
  }

  @override
  Future<KanbanSpecifyResult> specify(
    String id, {
    String? author,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{};
    if (author != null) {
      requestBody['author'] = author;
    }

    final data = await _client.postJson(
      '$_base/tasks/$id/specify',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );

    final map = _expectMap(data, 'POST $_base/tasks/$id/specify');
    return _parseSpecifyResult(map);
  }

  @override
  Future<KanbanDecomposeResult> decompose(
    String id, {
    String? author,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{};
    if (author != null) {
      requestBody['author'] = author;
    }

    final data = await _client.postJson(
      '$_base/tasks/$id/decompose',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );

    final map = _expectMap(data, 'POST $_base/tasks/$id/decompose');
    return _parseDecomposeResult(map);
  }

  @override
  Future<KanbanEstimate> estimateTask(String id, {String? board}) async {
    // No body — the task id in the path is the whole input; the board is a
    // query param like every other task route.
    final data = await _client.postJson(
      '$_base/tasks/$id/estimate',
      queryParameters: board == null ? null : <String, String>{'board': board},
    );

    final map = _expectMap(data, 'POST $_base/tasks/$id/estimate');
    return _parseEstimate(map);
  }

  @override
  Future<void> reassign(
    String id, {
    String? profile,
    bool reclaimFirst = false,
    String? reason,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{'reclaim_first': reclaimFirst};
    if (profile != null) {
      requestBody['profile'] = profile;
    }
    if (reason != null) {
      requestBody['reason'] = reason;
    }

    await _client.postJson(
      '$_base/tasks/$id/reassign',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
  }

  @override
  Future<void> reclaim(String id, {String? reason, String? board}) async {
    final requestBody = <String, dynamic>{};
    if (reason != null) {
      requestBody['reason'] = reason;
    }

    await _client.postJson(
      '$_base/tasks/$id/reclaim',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
  }

  @override
  Future<void> addLink({
    required String parentId,
    required String childId,
    String? board,
  }) async {
    final requestBody = <String, dynamic>{
      'parent_id': parentId,
      'child_id': childId,
    };

    await _client.postJson(
      '$_base/links',
      body: requestBody,
      queryParameters: board == null ? null : <String, String>{'board': board},
    );
  }

  @override
  Future<void> removeLink({
    required String parentId,
    required String childId,
    String? board,
  }) async {
    final queryParams = <String, String>{
      'parent_id': parentId,
      'child_id': childId,
    };
    if (board != null) {
      queryParams['board'] = board;
    }
    await _client.deleteJson('$_base/links', queryParameters: queryParams);
  }

  // ---- wire → domain translation (kept here so the domain stays clean) --

  static Map<String, dynamic> _expectMap(Object? data, String what) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw GatewayParseException('$what returned an unexpected body.');
  }

  static KanbanBoard _parseBoard(Map<String, dynamic> json) {
    return KanbanBoard(
      columns: _mapList(json['columns']).map(_parseColumn).toList(),
      tenants: _stringList(json['tenants']),
      assignees: _stringList(json['assignees']),
      latestEventId: _intOrNull(json['latest_event_id']),
      now: _epochSeconds(json['now']),
    );
  }

  static KanbanColumn _parseColumn(Map<String, dynamic> json) {
    return KanbanColumn(
      name: _stringOrNull(json['name']) ?? '',
      tasks: _mapList(json['tasks']).map(_parseTask).toList(),
    );
  }

  static KanbanTask _parseTask(Map<String, dynamic> json) {
    return KanbanTask(
      id: _stringOrNull(json['id']) ?? '',
      title: _stringOrNull(json['title']) ?? '',
      status: _stringOrNull(json['status']),
      body: _stringOrNull(json['body']),
      assignee: _stringOrNull(json['assignee']),
      priority: _stringOrNull(json['priority']),
      tenant: _stringOrNull(json['tenant']),
      age: _stringOrNull(json['age']),
      latestSummary: _stringOrNull(json['latest_summary']),
      linkCounts: _parseLinkCounts(json['link_counts']),
      commentCount: _intOrNull(json['comment_count']),
      progress: _parseProgress(json['progress']),
      // Execution/orchestration block (gateway 0.20). Absent on an older
      // gateway, so every one is optional; the counters default to 0/false
      // the way the Task dataclass does.
      projectId: _stringOrNull(json['project_id']),
      sessionId: _stringOrNull(json['session_id']),
      blockKind: _stringOrNull(json['block_kind']),
      blockRecurrences: _intOrNull(json['block_recurrences']) ?? 0,
      consecutiveFailures: _intOrNull(json['consecutive_failures']) ?? 0,
      modelOverride: _stringOrNull(json['model_override']),
      providerOverride: _stringOrNull(json['provider_override']),
      reasoningEffort: _stringOrNull(json['reasoning_effort']),
      goalMode: json['goal_mode'] == true,
      goalMaxTurns: _intOrNull(json['goal_max_turns']),
      // `skills` distinguishes null (profile defaults) from [] (explicitly
      // no extra skills), so a missing key must NOT become an empty list.
      skills: json['skills'] is List ? _stringList(json['skills']) : null,
      workflowTemplateId: _stringOrNull(json['workflow_template_id']),
      currentStepKey: _stringOrNull(json['current_step_key']),
      maxRetries: _intOrNull(json['max_retries']),
      maxRuntimeSeconds: _intOrNull(json['max_runtime_seconds']),
      currentRunId: _intOrNull(json['current_run_id']),
      claimLock: _stringOrNull(json['claim_lock']),
      claimExpires: _epochSeconds(json['claim_expires']),
      lastFailureError: _stringOrNull(json['last_failure_error']),
      lastHeartbeatAt: _epochSeconds(json['last_heartbeat_at']),
      workerPid: _intOrNull(json['worker_pid']),
    );
  }

  static KanbanTaskDetail _parseTaskDetail(Map<String, dynamic> json) {
    // The task fields may be nested under `task` or flattened at the top
    // level (the docs say "task + comments + …" without pinning the
    // envelope) — accept both.
    final taskMap = json['task'] is Map<String, dynamic>
        ? json['task']! as Map<String, dynamic>
        : json;
    final extras = Map<String, dynamic>.from(json)
      ..remove('task')
      ..remove('comments');
    return KanbanTaskDetail(
      task: _parseTask(taskMap),
      comments: _mapList(json['comments']),
      extras: extras,
    );
  }

  static KanbanLinkCounts? _parseLinkCounts(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return KanbanLinkCounts(
      parents: _intOrNull(value['parents']) ?? 0,
      children: _intOrNull(value['children']) ?? 0,
    );
  }

  static KanbanProgress? _parseProgress(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    return KanbanProgress(
      done: _intOrNull(value['done']) ?? 0,
      total: _intOrNull(value['total']) ?? 0,
    );
  }

  /// String-or-num coercion for the unpinned task fields; anything else
  /// (missing, null, bool, nested) → null.
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

  static KanbanBulkResult _parseBulkResult(Map<String, dynamic> json) {
    final resultsList = _mapList(json['results']);
    final items = <KanbanBulkItem>[];
    for (final item in resultsList) {
      items.add(
        KanbanBulkItem(
          id: _stringOrNull(item['id']) ?? '',
          ok: item['ok'] == true,
          error: _stringOrNull(item['error']),
        ),
      );
    }
    return KanbanBulkResult(results: items);
  }

  static KanbanSpecifyResult _parseSpecifyResult(Map<String, dynamic> json) {
    return KanbanSpecifyResult(
      ok: json['ok'] == true,
      taskId: _stringOrNull(json['task_id']) ?? '',
      reason: _stringOrNull(json['reason']),
      newTitle: _stringOrNull(json['new_title']),
    );
  }

  /// A declined estimate arrives as a 200 with `{ok: false, reason}` (the
  /// server's `_run_estimate` never raises), so failure is parsed, not thrown.
  /// On an ok result the three descriptive fields are independently optional.
  static KanbanEstimate _parseEstimate(Map<String, dynamic> json) {
    return KanbanEstimate(
      ok: json['ok'] == true,
      reason: _stringOrNull(json['reason']),
      estTokens: _intOrNull(json['est_tokens']),
      complexity: _stringOrNull(json['complexity']),
      rationale: _stringOrNull(json['rationale']),
      model: _stringOrNull(json['model']),
    );
  }

  static KanbanDecomposeResult _parseDecomposeResult(
    Map<String, dynamic> json,
  ) {
    return KanbanDecomposeResult(
      ok: json['ok'] == true,
      taskId: _stringOrNull(json['task_id']) ?? '',
      reason: _stringOrNull(json['reason']),
      fanout: json['fanout'] == true,
      childIds: _stringList(json['child_ids']),
      newTitle: _stringOrNull(json['new_title']),
    );
  }
}
