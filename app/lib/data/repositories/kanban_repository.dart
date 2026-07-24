import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/transport/gateway_rest_client.dart';
import 'package:hermes/domain/models/kanban.dart';
import 'package:hermes/domain/repositories/kanban_repository.dart';

/// [KanbanRepository] over [GatewayRestClient] (ticket P1-15).
///
/// Endpoints come VERBATIM from docs/reference/06-kanban-rest.md (MVP scope:
/// `GET /board`, `GET /tasks/{id}`, `PATCH /tasks/{id}`) — never invent
/// protocol. Auth + typed errors are handled by the REST client.
///
/// ## Parsing (sanctioned defensive field list)
///
/// The docs pin the board ENVELOPE exactly (`columns[{name, tasks[]}]`,
/// `tenants`, `assignees`, `latest_event_id`, `now`) and the derived task
/// fields (`age`, `latest_summary`, `link_counts {parents, children}`,
/// `comment_count`, `progress {done,total}|null`), but NOT the Task
/// dataclass's own fields. Per the ticket, these identity fields are parsed
/// defensively — string-or-num coerced to string, missing → null/empty:
/// `id`, `title`, `status`, `body`, `assignee`, `priority`, `tenant`.
/// Rendering tolerates any of them being absent; parsing never throws on a
/// missing task key.
final class KanbanRepositoryImpl implements KanbanRepository {
  const KanbanRepositoryImpl(this._client);

  final GatewayRestClient _client;

  static const _base = '/api/plugins/kanban';

  @override
  Future<KanbanBoard> board({String? board}) async {
    final data = await _client.getJson(
      '$_base/board',
      queryParameters: board == null ? null : <String, String>{'board': board},
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
}
