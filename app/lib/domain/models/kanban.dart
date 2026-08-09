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
///
/// ## Execution fields (gateway 0.20)
///
/// The `Task` dataclass grew a per-task execution/orchestration block
/// (`hermes_cli/kanban_db.py` `Task`), all of it optional and all of it
/// serialized by `asdict(task)` on every task endpoint: the dispatch
/// overrides (`model_override`, `provider_override`, `reasoning_effort`),
/// the goal loop (`goal_mode`, `goal_max_turns`), scoping (`project_id`,
/// `session_id`), block/failure bookkeeping (`block_kind`,
/// `block_recurrences`, `consecutive_failures`, `max_retries`,
/// `last_failure_error`), the workflow step pointer
/// (`workflow_template_id`, `current_step_key`), forced `skills`, and the
/// claim/run fields (`current_run_id`, `claim_lock`, `claim_expires`,
/// `worker_pid`, `last_heartbeat_at`, `max_runtime_seconds`). Same
/// tolerant parsing as the identity fields — an older gateway omits them
/// and every one reads as null.

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
    this.projectId,
    this.sessionId,
    this.blockKind,
    this.blockRecurrences = 0,
    this.consecutiveFailures = 0,
    this.modelOverride,
    this.providerOverride,
    this.reasoningEffort,
    this.goalMode = false,
    this.goalMaxTurns,
    this.skills,
    this.workflowTemplateId,
    this.currentStepKey,
    this.maxRetries,
    this.maxRuntimeSeconds,
    this.currentRunId,
    this.claimLock,
    this.claimExpires,
    this.lastFailureError,
    this.lastHeartbeatAt,
    this.workerPid,
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

  /// Linked first-class project id — a project-scoped board anchors every
  /// task it creates to its project.
  final String? projectId;

  /// Originating chat/agent session id, when the task was created from
  /// inside an agent loop that propagated `HERMES_SESSION_ID`. Null for
  /// CLI/dashboard-created tasks.
  final String? sessionId;

  /// Typed block reason (`dependency` / `needs_input` / `capability` /
  /// `transient`), or null for an un-typed block.
  final String? blockKind;

  /// Unblock↔re-block loop counter; reset only on a successful completion.
  final int blockRecurrences;

  /// Non-success counter (spawn failure, timeout, crash) feeding the
  /// circuit breaker; reset only on a successful completion.
  final int consecutiveFailures;

  /// Per-task model override for the dispatched worker.
  final String? modelOverride;

  /// Provider [modelOverride] belongs to; null resolves the model against
  /// the worker profile's own provider.
  final String? providerOverride;

  /// Per-task thinking depth for the worker (`"none"` means thinking off,
  /// which is a VALUE, not "unset"); null inherits the profile's level.
  final String? reasoningEffort;

  /// When true the worker runs a goal loop instead of a single shot.
  final bool goalMode;

  /// Turn budget for a [goalMode] worker; null uses the engine default.
  final int? goalMaxTurns;

  /// Force-loaded skills for the worker. Null = defaults only; empty =
  /// explicitly no extra skills (the distinction is on the wire).
  final List<String>? skills;

  /// Workflow template driving this task, when it came from one.
  final String? workflowTemplateId;

  /// Current step key within [workflowTemplateId].
  final String? currentStepKey;

  /// Per-task failure count at which the circuit breaker trips; null falls
  /// through to the dispatcher's own limit.
  final int? maxRetries;

  /// Worker runtime cap in seconds.
  final int? maxRuntimeSeconds;

  /// Run id of the in-flight run, when the task is claimed.
  final int? currentRunId;

  /// Claim token held by the running worker.
  final String? claimLock;

  /// When the current claim expires.
  final DateTime? claimExpires;

  /// Short excerpt of the last failure's error text.
  final String? lastFailureError;

  /// Last heartbeat from the running worker.
  final DateTime? lastHeartbeatAt;

  /// PID of the running worker.
  final int? workerPid;

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
    String? projectId,
    String? sessionId,
    String? blockKind,
    int? blockRecurrences,
    int? consecutiveFailures,
    String? modelOverride,
    String? providerOverride,
    String? reasoningEffort,
    bool? goalMode,
    int? goalMaxTurns,
    List<String>? skills,
    String? workflowTemplateId,
    String? currentStepKey,
    int? maxRetries,
    int? maxRuntimeSeconds,
    int? currentRunId,
    String? claimLock,
    DateTime? claimExpires,
    String? lastFailureError,
    DateTime? lastHeartbeatAt,
    int? workerPid,
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
      projectId: projectId ?? this.projectId,
      sessionId: sessionId ?? this.sessionId,
      blockKind: blockKind ?? this.blockKind,
      blockRecurrences: blockRecurrences ?? this.blockRecurrences,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      modelOverride: modelOverride ?? this.modelOverride,
      providerOverride: providerOverride ?? this.providerOverride,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      goalMode: goalMode ?? this.goalMode,
      goalMaxTurns: goalMaxTurns ?? this.goalMaxTurns,
      skills: skills ?? this.skills,
      workflowTemplateId: workflowTemplateId ?? this.workflowTemplateId,
      currentStepKey: currentStepKey ?? this.currentStepKey,
      maxRetries: maxRetries ?? this.maxRetries,
      maxRuntimeSeconds: maxRuntimeSeconds ?? this.maxRuntimeSeconds,
      currentRunId: currentRunId ?? this.currentRunId,
      claimLock: claimLock ?? this.claimLock,
      claimExpires: claimExpires ?? this.claimExpires,
      lastFailureError: lastFailureError ?? this.lastFailureError,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      workerPid: workerPid ?? this.workerPid,
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
        other.progress == progress &&
        other.projectId == projectId &&
        other.sessionId == sessionId &&
        other.blockKind == blockKind &&
        other.blockRecurrences == blockRecurrences &&
        other.consecutiveFailures == consecutiveFailures &&
        other.modelOverride == modelOverride &&
        other.providerOverride == providerOverride &&
        other.reasoningEffort == reasoningEffort &&
        other.goalMode == goalMode &&
        other.goalMaxTurns == goalMaxTurns &&
        _nullableListEquals(other.skills, skills) &&
        other.workflowTemplateId == workflowTemplateId &&
        other.currentStepKey == currentStepKey &&
        other.maxRetries == maxRetries &&
        other.maxRuntimeSeconds == maxRuntimeSeconds &&
        other.currentRunId == currentRunId &&
        other.claimLock == claimLock &&
        other.claimExpires == claimExpires &&
        other.lastFailureError == lastFailureError &&
        other.lastHeartbeatAt == lastHeartbeatAt &&
        other.workerPid == workerPid;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
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
    projectId,
    sessionId,
    blockKind,
    blockRecurrences,
    consecutiveFailures,
    modelOverride,
    providerOverride,
    reasoningEffort,
    goalMode,
    goalMaxTurns,
    if (skills != null) Object.hashAll(skills!) else null,
    workflowTemplateId,
    currentStepKey,
    maxRetries,
    maxRuntimeSeconds,
    currentRunId,
    claimLock,
    claimExpires,
    lastFailureError,
    lastHeartbeatAt,
    workerPid,
  ]);

  /// `null` and `[]` are different values for [skills] on the wire, so the
  /// list compare has to keep them apart.
  static bool _nullableListEquals(List<String>? a, List<String>? b) {
    if (a == null || b == null) {
      return a == null && b == null;
    }
    return deepListEquals(a, b);
  }

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

/// Result from `POST /tasks/{id}/estimate` — a rough token + complexity read
/// on a task from the gateway's auxiliary model.
///
/// Two wire details: a refusal is a **200** with `{ok: false, reason}`, not an
/// HTTP error (`plugin_api.py` `_run_estimate` never raises), and on an `ok`
/// result [complexity] / [rationale] / [model] are each independently
/// nullable — the gateway drops a complexity band it doesn't recognise and
/// only knows the model name when the provider echoed one back.
///
/// [estTokens] is tokens for a whole multi-turn agent run, deliberately NOT a
/// dollar cost: providers don't report cost reliably.
final class KanbanEstimate {
  const KanbanEstimate({
    required this.ok,
    this.reason,
    this.estTokens,
    this.complexity,
    this.rationale,
    this.model,
  });

  /// False when the gateway declined to estimate (no title, auxiliary client
  /// unavailable, LLM error, unparseable reply) — see [reason].
  final bool ok;

  /// Why the estimate failed; null when [ok].
  final String? reason;

  /// Estimated total tokens across the whole run.
  final int? estTokens;

  /// Complexity band — `S` / `M` / `L`, or null when the model returned
  /// something else.
  final String? complexity;

  /// One-sentence why behind the numbers.
  final String? rationale;

  /// Model that produced the estimate, when the provider reported it.
  final String? model;

  @override
  bool operator ==(Object other) {
    return other is KanbanEstimate &&
        other.ok == ok &&
        other.reason == reason &&
        other.estTokens == estTokens &&
        other.complexity == complexity &&
        other.rationale == rationale &&
        other.model == model;
  }

  @override
  int get hashCode =>
      Object.hash(ok, reason, estTokens, complexity, rationale, model);

  @override
  String toString() =>
      'KanbanEstimate(ok: $ok, estTokens: $estTokens, '
      'complexity: $complexity, model: $model'
      '${reason != null ? ', reason: $reason' : ''})';
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
