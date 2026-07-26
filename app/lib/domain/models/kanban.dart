import 'package:flit/domain/models/deep_equals.dart';

/// Domain models for the kanban plugin board (ticket P1-15).
///
/// Hand-written + immutable (05-conventions.md). Wire → domain translation
/// lives in the data layer (`KanbanRepositoryImpl`); these models are clean.
///
/// ## Sanctioned defensive task-field list
///
/// 06-kanban-rest.md pins the BOARD envelope exactly but does NOT enumerate
/// the `Task` dataclass's own fields. Per the ticket's sanctioned defensive
/// parsing, [KanbanTask] carries these identity fields, ALL parsed
/// tolerantly (string-or-num coerced to string; missing → null/empty):
///
/// - `id` (required, `''` fallback), `title` (required, `''` fallback)
/// - `status?`, `body?`, `assignee?`, `priority?`, `tenant?`
///
/// Plus the derived fields 06-kanban-rest.md DOES document:
///
/// - `age?`, `latestSummary?` (200-char preview)
/// - `linkCounts?` `{parents, children}`
/// - `commentCount?`
/// - `progress?` `{done, total}` (null on the wire when absent)
///
/// (`diagnostics` / `warnings` are documented as optional; the MVP UI never
/// renders them, so they are not modelled.) Anything else the server sends
/// is ignored for board tasks and preserved raw in [KanbanTaskDetail.extras].

/// One column of the board (06-kanban-rest.md: fixed server order —
/// triage/todo/scheduled/ready/running/blocked/review/done — rendered as
/// received, never re-ordered client-side).
final class KanbanColumn {
  const KanbanColumn({required this.name, this.tasks = const <KanbanTask>[]});

  /// Column name, e.g. `triage`. Doubles as the task `status` value used
  /// when moving a card (`PATCH /tasks/{id} {status: <name>}`).
  final String name;

  /// Tasks currently in this column, in server order.
  final List<KanbanTask> tasks;

  KanbanColumn copyWith({String? name, List<KanbanTask>? tasks}) {
    return KanbanColumn(name: name ?? this.name, tasks: tasks ?? this.tasks);
  }

  @override
  bool operator ==(Object other) {
    return other is KanbanColumn &&
        other.name == name &&
        deepListEquals(other.tasks, tasks);
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(tasks));

  @override
  String toString() => 'KanbanColumn(name: $name, tasks: ${tasks.length})';
}

/// The whole board envelope from `GET /api/plugins/kanban/board`
/// (06-kanban-rest.md): `{columns, tenants, assignees, latest_event_id,
/// now}`.
final class KanbanBoard {
  const KanbanBoard({
    this.columns = const <KanbanColumn>[],
    this.tenants = const <String>[],
    this.assignees = const <String>[],
    this.latestEventId,
    this.now,
  });

  /// Columns in the FIXED order they arrive — render as-is.
  final List<KanbanColumn> columns;

  /// Tenant filter values the server reports.
  final List<String> tenants;

  /// Known assignee (profile) names.
  final List<String> assignees;

  /// Cursor for the live `/events` WS feed (Phase 5; unused by the MVP).
  final int? latestEventId;

  /// Server clock (`now`, epoch seconds) — absorbed to a [DateTime].
  final DateTime? now;

  /// All column names, in order — the target list for "move to" menus.
  List<String> get columnNames =>
      columns.map((column) => column.name).toList(growable: false);

  /// Returns a copy with [taskId] removed from its current column and
  /// appended to [toColumn] (status updated to the column name). Unknown
  /// task ids or target columns return `this` unchanged.
  KanbanBoard moveTaskToColumn(String taskId, String toColumn) {
    KanbanTask? moved;
    final next = <KanbanColumn>[];
    for (final column in columns) {
      final remaining = <KanbanTask>[];
      for (final task in column.tasks) {
        if (task.id == taskId && moved == null) {
          moved = task.copyWith(status: toColumn);
        } else {
          remaining.add(task);
        }
      }
      next.add(column.copyWith(tasks: remaining));
    }
    if (moved == null) {
      return this;
    }
    var placed = false;
    for (var i = 0; i < next.length; i++) {
      if (next[i].name == toColumn) {
        next[i] = next[i].copyWith(
          tasks: <KanbanTask>[...next[i].tasks, moved],
        );
        placed = true;
        break;
      }
    }
    return placed ? KanbanBoard._copy(this, next) : this;
  }

  static KanbanBoard _copy(KanbanBoard board, List<KanbanColumn> columns) {
    return KanbanBoard(
      columns: columns,
      tenants: board.tenants,
      assignees: board.assignees,
      latestEventId: board.latestEventId,
      now: board.now,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KanbanBoard &&
        deepListEquals(other.columns, columns) &&
        deepListEquals(other.tenants, tenants) &&
        deepListEquals(other.assignees, assignees) &&
        other.latestEventId == latestEventId &&
        other.now == now;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(columns),
    Object.hashAll(tenants),
    Object.hashAll(assignees),
    latestEventId,
    now,
  );

  @override
  String toString() =>
      'KanbanBoard(columns: ${columns.length}, latestEventId: $latestEventId)';
}

/// Parent/child link counts — the derived `link_counts` field
/// (06-kanban-rest.md).
final class KanbanLinkCounts {
  const KanbanLinkCounts({required this.parents, required this.children});

  final int parents;
  final int children;

  @override
  bool operator ==(Object other) {
    return other is KanbanLinkCounts &&
        other.parents == parents &&
        other.children == children;
  }

  @override
  int get hashCode => Object.hash(parents, children);

  @override
  String toString() =>
      'KanbanLinkCounts(parents: $parents, children: $children)';
}

/// Step progress — the derived `progress {done, total}` field (null on the
/// wire when the task has no steps).
final class KanbanProgress {
  const KanbanProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  bool operator ==(Object other) {
    return other is KanbanProgress &&
        other.done == done &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(done, total);

  @override
  String toString() => 'KanbanProgress($done/$total)';
}

/// One kanban task card. See the sanctioned field list documented at the top
/// of this file — identity fields are parsed defensively; derived fields are
/// the documented ones.
final class KanbanTask {
  const KanbanTask({
    required this.id,
    required this.title,
    this.status,
    this.body,
    this.assignee,
    this.priority,
    this.tenant,
    this.age,
    this.latestSummary,
    this.linkCounts,
    this.commentCount,
    this.progress,
  });

  /// Task id (stringified from string-or-num; `''` when absent).
  final String id;

  /// Task title (`''` when absent).
  final String title;

  /// Column/status name, e.g. `triage`.
  final String? status;

  /// Full task body (markdown-ish plain text).
  final String? body;

  /// Assignee profile name.
  final String? assignee;

  /// Priority (wire type unpinned — string-or-num coerced to string).
  final String? priority;

  /// Tenant slug.
  final String? tenant;

  /// Derived age (wire type unpinned — string-or-num coerced to string).
  final String? age;

  /// Derived `latest_summary`: 200-char preview of the latest event.
  final String? latestSummary;

  /// Derived `link_counts {parents, children}`.
  final KanbanLinkCounts? linkCounts;

  /// Derived `comment_count`.
  final int? commentCount;

  /// Derived `progress {done, total}` (null when the task has no steps).
  final KanbanProgress? progress;

  KanbanTask copyWith({
    String? id,
    String? title,
    String? status,
    String? body,
    String? assignee,
    String? priority,
    String? tenant,
    String? age,
    String? latestSummary,
    KanbanLinkCounts? linkCounts,
    int? commentCount,
    KanbanProgress? progress,
  }) {
    return KanbanTask(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      body: body ?? this.body,
      assignee: assignee ?? this.assignee,
      priority: priority ?? this.priority,
      tenant: tenant ?? this.tenant,
      age: age ?? this.age,
      latestSummary: latestSummary ?? this.latestSummary,
      linkCounts: linkCounts ?? this.linkCounts,
      commentCount: commentCount ?? this.commentCount,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KanbanTask &&
        other.id == id &&
        other.title == title &&
        other.status == status &&
        other.body == body &&
        other.assignee == assignee &&
        other.priority == priority &&
        other.tenant == tenant &&
        other.age == age &&
        other.latestSummary == latestSummary &&
        other.linkCounts == linkCounts &&
        other.commentCount == commentCount &&
        other.progress == progress;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    status,
    body,
    assignee,
    priority,
    tenant,
    age,
    latestSummary,
    linkCounts,
    commentCount,
    progress,
  );

  @override
  String toString() => 'KanbanTask(id: $id, title: $title, status: $status)';
}

/// The detail-drawer payload from `GET /api/plugins/kanban/tasks/{id}`
/// (06-kanban-rest.md: "task + comments + events + attachments + links +
/// runs"). The task itself is parsed like a board task; [comments] stays
/// raw-ish because the docs don't pin comment fields; every other top-level
/// key (`events`, `attachments`, `links`, `runs`, …) lands in [extras]
/// untouched — the MVP renders only [task] + [comments].
final class KanbanTaskDetail {
  const KanbanTaskDetail({
    required this.task,
    this.comments = const <Map<String, dynamic>>[],
    this.extras = const <String, dynamic>{},
  });

  /// The parsed task (same sanctioned fields as [KanbanTask]).
  final KanbanTask task;

  /// Raw comment maps (`{body, author, ...}` per the REST catalog — fields
  /// not pinned by the docs, so kept as-is).
  final List<Map<String, dynamic>> comments;

  /// All remaining top-level keys of the detail response, unmodified.
  final Map<String, dynamic> extras;

  @override
  bool operator ==(Object other) {
    return other is KanbanTaskDetail &&
        other.task == task &&
        deepListEquals(other.comments, comments) &&
        shallowMapEquals(other.extras, extras);
  }

  @override
  int get hashCode =>
      Object.hash(task, Object.hashAll(comments), Object.hashAll(extras.keys));

  @override
  String toString() =>
      'KanbanTaskDetail(task: $task, comments: ${comments.length}, '
      'extras: ${extras.keys.join(', ')})';
}

/// Result from `POST /tasks/bulk` (P5-05).
final class KanbanBulkResult {
  const KanbanBulkResult({required this.results});

  final List<KanbanBulkItem> results;

  @override
  bool operator ==(Object other) {
    return other is KanbanBulkResult && deepListEquals(other.results, results);
  }

  @override
  int get hashCode => Object.hashAll(results);

  @override
  String toString() => 'KanbanBulkResult(results: ${results.length})';
}

/// One bulk operation result (P5-05).
final class KanbanBulkItem {
  const KanbanBulkItem({required this.id, required this.ok, this.error});

  final String id;
  final bool ok;
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is KanbanBulkItem &&
        other.id == id &&
        other.ok == ok &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(id, ok, error);

  @override
  String toString() =>
      'KanbanBulkItem(id: $id, ok: $ok${error != null ? ', error: $error' : ''})';
}

/// Result from `POST /tasks/{id}/specify` (P5-05).
final class KanbanSpecifyResult {
  const KanbanSpecifyResult({
    required this.ok,
    required this.taskId,
    this.reason,
    this.newTitle,
  });

  final bool ok;
  final String taskId;
  final String? reason;
  final String? newTitle;

  @override
  bool operator ==(Object other) {
    return other is KanbanSpecifyResult &&
        other.ok == ok &&
        other.taskId == taskId &&
        other.reason == reason &&
        other.newTitle == newTitle;
  }

  @override
  int get hashCode => Object.hash(ok, taskId, reason, newTitle);

  @override
  String toString() =>
      'KanbanSpecifyResult(ok: $ok, taskId: $taskId${reason != null ? ', reason: $reason' : ''}${newTitle != null ? ', newTitle: $newTitle' : ''})';
}

/// Result from `POST /tasks/{id}/decompose` (P5-05).
final class KanbanDecomposeResult {
  const KanbanDecomposeResult({
    required this.ok,
    required this.taskId,
    this.reason,
    required this.fanout,
    this.childIds = const <String>[],
    this.newTitle,
  });

  final bool ok;
  final String taskId;
  final String? reason;
  final bool fanout;
  final List<String> childIds;
  final String? newTitle;

  @override
  bool operator ==(Object other) {
    return other is KanbanDecomposeResult &&
        other.ok == ok &&
        other.taskId == taskId &&
        other.reason == reason &&
        other.fanout == fanout &&
        deepListEquals(other.childIds, childIds) &&
        other.newTitle == newTitle;
  }

  @override
  int get hashCode => Object.hash(
    ok,
    taskId,
    reason,
    fanout,
    Object.hashAll(childIds),
    newTitle,
  );

  @override
  String toString() =>
      'KanbanDecomposeResult(ok: $ok, taskId: $taskId, fanout: $fanout, childIds: ${childIds.length}${reason != null ? ', reason: $reason' : ''}${newTitle != null ? ', newTitle: $newTitle' : ''})';
}
