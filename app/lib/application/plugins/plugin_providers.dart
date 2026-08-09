/// Riverpod wiring for the plugins + kanban features (tickets P1-14/P1-15).
///
/// Mirrors the nullable-repository pattern of application/providers.dart
/// (which this file deliberately does not edit): repositories are null when
/// disconnected, and callers handle null.
library;

import 'dart:async';
import 'dart:collection';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/kanban_repository.dart';
import 'package:flit/data/repositories/plugin_repository.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flit/domain/repositories/kanban_repository.dart';
import 'package:flit/domain/repositories/plugin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The plugin repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final pluginRepositoryProvider = Provider<PluginRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return PluginRepositoryImpl(client);
});

/// The kanban repository for the current connection, or null when there is
/// no REST client (disconnected). The kanban plugin is REST-only
/// (06-kanban-rest.md).
final kanbanRepositoryProvider = Provider<KanbanRepository?>((ref) {
  final client = ref.watch(restClientProvider);
  if (client == null) {
    return null;
  }
  return KanbanRepositoryImpl(client);
});

/// All plugins from `plugins.list` (wire §13); empty when disconnected.
final pluginsProvider = FutureProvider<List<PluginInfo>>((ref) async {
  final repository = ref.watch(pluginRepositoryProvider);
  if (repository == null) {
    return const <PluginInfo>[];
  }
  return repository.list();
});

/// Rich plugin details from `plugins.manage {action:'list'}` (P5-08);
/// empty when disconnected.
final pluginDetailsProvider = FutureProvider<List<PluginDetail>>((ref) async {
  final repository = ref.watch(pluginRepositoryProvider);
  if (repository == null) {
    return const <PluginDetail>[];
  }
  return repository.manageList();
});

/// One task's detail payload, keyed by task id — feeds the detail sheet.
/// Null when disconnected.
final kanbanTaskDetailProvider =
    FutureProvider.family<KanbanTaskDetail?, String>((ref, id) async {
      final repository = ref.watch(kanbanRepositoryProvider);
      if (repository == null) {
        return null;
      }
      return repository.task(id);
    });

/// The selected kanban board slug (for deep-link routing, ticket P9-02).
/// Null means the current/default board.
final selectedKanbanBoardProvider =
    NotifierProvider<SelectedKanbanBoardNotifier, String?>(
      SelectedKanbanBoardNotifier.new,
    );

class SelectedKanbanBoardNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Set the board slug (e.g. from a deep link).
  void selectBoard(String? slug) {
    state = slug;
  }
}

/// The board's workflow filters — the server-side `workflow_template_id` /
/// `current_step_key` predicates on `GET /board`.
///
/// Both are independent: a step key filters across every template unless a
/// template is also named. Null means "no filter"; an empty string would be a
/// filter for an empty value, so the UI never sends one.
final class KanbanBoardFilter {
  const KanbanBoardFilter({this.workflowTemplateId, this.currentStepKey});

  /// Only tasks driven by this workflow template.
  final String? workflowTemplateId;

  /// Only tasks sitting at this workflow step.
  final String? currentStepKey;

  /// True when the board on screen is narrowed — the UI has to say so, since
  /// a filtered board otherwise just looks like tasks went missing.
  bool get isActive => workflowTemplateId != null || currentStepKey != null;

  @override
  bool operator ==(Object other) {
    return other is KanbanBoardFilter &&
        other.workflowTemplateId == workflowTemplateId &&
        other.currentStepKey == currentStepKey;
  }

  @override
  int get hashCode => Object.hash(workflowTemplateId, currentStepKey);

  @override
  String toString() =>
      'KanbanBoardFilter(workflowTemplateId: $workflowTemplateId, '
      'currentStepKey: $currentStepKey)';
}

/// The active board filter. Changing it re-fetches the board, because the
/// filtering happens server-side (`plugin_api.py` `get_board` → SQL).
final kanbanBoardFilterProvider =
    NotifierProvider<KanbanBoardFilterNotifier, KanbanBoardFilter>(
      KanbanBoardFilterNotifier.new,
    );

class KanbanBoardFilterNotifier extends Notifier<KanbanBoardFilter> {
  @override
  KanbanBoardFilter build() {
    // A template id / step key belongs to ONE board's tasks, so switching
    // boards drops the filter instead of carrying a predicate that matches
    // nothing over to the new board.
    ref.watch(selectedKanbanBoardProvider);
    return const KanbanBoardFilter();
  }

  /// Apply both predicates at once (the filter sheet's Apply).
  void apply({String? workflowTemplateId, String? currentStepKey}) {
    state = KanbanBoardFilter(
      workflowTemplateId: workflowTemplateId,
      currentStepKey: currentStepKey,
    );
  }

  /// Back to the whole board.
  void clear() {
    state = const KanbanBoardFilter();
  }
}

/// The workflow values actually present on the board — what the filter sheet
/// offers. Template ids are opaque strings nobody can be expected to type.
///
/// Empty means the board has no workflow-driven tasks at all, which is also
/// what an older gateway looks like (it sends neither field on a task, and
/// FastAPI would silently ignore the query params) — so the filter affordance
/// hides itself rather than promising a filter that does nothing.
final class KanbanWorkflowOptions {
  const KanbanWorkflowOptions({
    this.templateIds = const <String>[],
    this.stepKeys = const <String>[],
    this.stepKeysByTemplate = const <String, List<String>>{},
  });

  /// Every `workflow_template_id` seen, sorted.
  final List<String> templateIds;

  /// Every `current_step_key` seen, sorted — including steps on tasks with
  /// no template.
  final List<String> stepKeys;

  /// Step keys per template, so picking a template can't leave an
  /// impossible step selected behind it.
  final Map<String, List<String>> stepKeysByTemplate;

  bool get isEmpty => templateIds.isEmpty && stepKeys.isEmpty;

  /// The steps worth offering for [templateId] — all of them when no
  /// template is chosen.
  List<String> stepKeysFor(String? templateId) {
    if (templateId == null) {
      return stepKeys;
    }
    return stepKeysByTemplate[templateId] ?? const <String>[];
  }

  @override
  bool operator ==(Object other) {
    if (other is! KanbanWorkflowOptions) {
      return false;
    }
    if (!_sameStrings(other.templateIds, templateIds) ||
        !_sameStrings(other.stepKeys, stepKeys) ||
        other.stepKeysByTemplate.length != stepKeysByTemplate.length) {
      return false;
    }
    for (final entry in stepKeysByTemplate.entries) {
      final theirs = other.stepKeysByTemplate[entry.key];
      if (theirs == null || !_sameStrings(theirs, entry.value)) {
        return false;
      }
    }
    return true;
  }

  static bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(templateIds),
    Object.hashAll(stepKeys),
    Object.hashAll(stepKeysByTemplate.keys),
  );

  @override
  String toString() =>
      'KanbanWorkflowOptions(templateIds: ${templateIds.length}, '
      'stepKeys: ${stepKeys.length})';
}

/// Filter options harvested from the board.
///
/// Read from UNFILTERED loads only: a filtered board no longer contains the
/// other templates' tasks, so harvesting off one would strand the user on the
/// choice they just made with no way back to a sibling template.
final kanbanWorkflowOptionsProvider =
    NotifierProvider<KanbanWorkflowOptionsNotifier, KanbanWorkflowOptions>(
      KanbanWorkflowOptionsNotifier.new,
    );

class KanbanWorkflowOptionsNotifier extends Notifier<KanbanWorkflowOptions> {
  @override
  KanbanWorkflowOptions build() {
    // Another board means another set of workflows.
    ref.watch(selectedKanbanBoardProvider);
    ref.listen(kanbanBoardProvider, (previous, next) {
      _record(next.value);
    });
    // A plain listen only fires on CHANGE, and the board has usually loaded
    // before anything watches this provider (the filter button is in the
    // app bar of the screen that loaded it) — so seed from what is there.
    return _optionsOf(_unfilteredBoard()) ?? const KanbanWorkflowOptions();
  }

  void _record(KanbanBoard? board) {
    final options = _optionsOf(board);
    if (options != null && options != state) {
      state = options;
    }
  }

  /// The loaded board, or null when it is absent or narrowed. Reading the
  /// filter (rather than watching it) keeps applying a filter from wiping
  /// the very options it was chosen from.
  KanbanBoard? _unfilteredBoard() {
    if (ref.read(kanbanBoardFilterProvider).isActive) {
      return null;
    }
    return ref.read(kanbanBoardProvider).value;
  }

  KanbanWorkflowOptions? _optionsOf(KanbanBoard? board) {
    if (board == null || ref.read(kanbanBoardFilterProvider).isActive) {
      return null;
    }
    final templateIds = SplayTreeSet<String>();
    final stepKeys = SplayTreeSet<String>();
    final byTemplate = <String, SplayTreeSet<String>>{};
    for (final column in board.columns) {
      for (final task in column.tasks) {
        final template = task.workflowTemplateId;
        final step = task.currentStepKey;
        if (template != null && template.isNotEmpty) {
          templateIds.add(template);
        }
        if (step != null && step.isNotEmpty) {
          stepKeys.add(step);
          if (template != null && template.isNotEmpty) {
            byTemplate
                .putIfAbsent(template, SplayTreeSet<String>.new)
                .add(step);
          }
        }
      }
    }
    return KanbanWorkflowOptions(
      templateIds: templateIds.toList(growable: false),
      stepKeys: stepKeys.toList(growable: false),
      stepKeysByTemplate: <String, List<String>>{
        for (final entry in byTemplate.entries)
          entry.key: entry.value.toList(growable: false),
      },
    );
  }
}

/// The kanban board for the current connection.
///
/// MVP approach is poll-on-focus: the board is fetched on first build and on
/// explicit [KanbanBoardNotifier.refresh] (app-bar button); the live
/// `/api/plugins/kanban/events` WS feed (seeded from
/// [KanbanBoard.latestEventId]) is Phase 5 — see 06-kanban-rest.md.
///
/// Ticket P9-02: the board slug is now read from [selectedKanbanBoardProvider]
/// so deep links can target a specific board. The workflow narrowing comes
/// from [kanbanBoardFilterProvider] and is applied by the SERVER, so changing
/// it re-fetches.
final kanbanBoardProvider =
    AsyncNotifierProvider<KanbanBoardNotifier, KanbanBoard?>(
      KanbanBoardNotifier.new,
    );

class KanbanBoardNotifier extends AsyncNotifier<KanbanBoard?> {
  @override
  Future<KanbanBoard?> build() async {
    final repository = ref.watch(kanbanRepositoryProvider);
    if (repository == null) {
      return null;
    }
    final slug = ref.watch(selectedKanbanBoardProvider);
    final filter = ref.watch(kanbanBoardFilterProvider);
    return repository.board(
      board: slug,
      workflowTemplateId: filter.workflowTemplateId,
      currentStepKey: filter.currentStepKey,
    );
  }

  /// Re-fetch the board (poll-on-focus MVP; the live feed is Phase 5).
  /// Keeps the current data visible on failure — the error is swallowed
  /// into [AsyncError] only when there is nothing to show.
  Future<void> refresh() async {
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const AsyncData(null);
      return;
    }
    final slug = ref.read(selectedKanbanBoardProvider);
    final filter = ref.read(kanbanBoardFilterProvider);
    state = AsyncData(
      await repository.board(
        board: slug,
        workflowTemplateId: filter.workflowTemplateId,
        currentStepKey: filter.currentStepKey,
      ),
    );
  }

  /// Move [id] to column [toColumn] (= `PATCH {status: toColumn}`).
  ///
  /// Choice: OPTIMISTIC update with rollback (rather than refetch-after-
  /// PATCH) — a board move should feel instant, and a failed PATCH snaps
  /// the card back. The pre-move board is restored and the error rethrown
  /// so the UI can surface it (snackbar).
  Future<void> moveTask(String id, String toColumn) async {
    final repository = ref.read(kanbanRepositoryProvider);
    final board = state.value;
    if (repository == null || board == null) {
      return;
    }
    state = AsyncData(board.moveTaskToColumn(id, toColumn));
    try {
      await repository.updateTaskStatus(id, toColumn);
    } on GatewayException {
      state = AsyncData(board); // rollback
      rethrow;
    }
  }
}

/// Interaction state for plugin toggle (P5-08).
final class PluginToggleState {
  const PluginToggleState({this.busy = false, this.error});

  /// A toggle call is in flight.
  final bool busy;

  /// Human-readable failure, or null.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is PluginToggleState &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, error);

  @override
  String toString() {
    return 'PluginToggleState(busy: $busy, error: $error)';
  }
}

/// Controller for plugin toggle (P5-08): enable/disable plugins.
final pluginToggleControllerProvider =
    NotifierProvider<PluginToggleController, PluginToggleState>(
      PluginToggleController.new,
    );

class PluginToggleController extends Notifier<PluginToggleState> {
  @override
  PluginToggleState build() => const PluginToggleState();

  /// Toggle a plugin's enabled state. NEVER throws — failures land in
  /// [PluginToggleState.error].
  Future<void> toggle(String name, bool enable) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(pluginRepositoryProvider);
    if (repository == null) {
      state = const PluginToggleState(error: 'Not connected to a gateway.');
      return;
    }
    state = const PluginToggleState(busy: true);
    try {
      await repository.toggle(name, enable);
      state = const PluginToggleState();
      ref.invalidate(pluginDetailsProvider);
    } on GatewayException catch (error) {
      state = PluginToggleState(error: error.message);
    } on Object catch (error) {
      state = PluginToggleState(error: error.toString());
    }
  }

  void clearError() {
    state = PluginToggleState(busy: state.busy);
  }
}

/// One task's estimate: idle until asked, then in flight, then a result.
///
/// [estimate] holds BOTH outcomes of the call — a declined estimate is an
/// `ok: false` [KanbanEstimate] with a reason, not an [error]; [error] is only
/// for transport/auth failures.
final class KanbanEstimateState {
  const KanbanEstimateState({this.busy = false, this.estimate, this.error});

  /// The estimate call is in flight (several seconds — an LLM round-trip).
  final bool busy;

  /// The last result, ok or declined; null before the first run.
  final KanbanEstimate? estimate;

  /// Human-readable transport failure, or null.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is KanbanEstimateState &&
        other.busy == busy &&
        other.estimate == estimate &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, estimate, error);

  @override
  String toString() =>
      'KanbanEstimateState(busy: $busy, estimate: $estimate, error: $error)';
}

/// A task's token/complexity estimate, keyed by task id.
///
/// Deliberately NOT a [FutureProvider]: `POST /tasks/{id}/estimate` spends an
/// auxiliary-model call, so it runs only when the user asks
/// ([KanbanEstimateNotifier.run]), never on build.
final kanbanEstimateProvider =
    NotifierProvider.family<
      KanbanEstimateNotifier,
      KanbanEstimateState,
      String
    >(KanbanEstimateNotifier.new);

class KanbanEstimateNotifier extends Notifier<KanbanEstimateState> {
  KanbanEstimateNotifier(this.taskId);

  /// The task being estimated — the family argument.
  final String taskId;

  @override
  KanbanEstimateState build() => const KanbanEstimateState();

  /// Ask the gateway to estimate [taskId]. NEVER throws — a refusal lands in
  /// [KanbanEstimateState.estimate] with `ok: false`, a transport failure in
  /// [KanbanEstimateState.error].
  Future<void> run({String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanEstimateState(error: 'Not connected to a gateway.');
      return;
    }
    // Keep the previous estimate on screen while the next one is computed —
    // the call is slow enough that blanking it reads as a failure.
    state = KanbanEstimateState(busy: true, estimate: state.estimate);
    try {
      final estimate = await repository.estimateTask(taskId, board: board);
      state = KanbanEstimateState(estimate: estimate);
    } on GatewayException catch (error) {
      state = KanbanEstimateState(
        estimate: state.estimate,
        error: error.message,
      );
    } on Object catch (error) {
      state = KanbanEstimateState(
        estimate: state.estimate,
        error: error.toString(),
      );
    }
  }
}

/// Interaction state for kanban task actions (P5-05).
final class KanbanTaskActionState {
  const KanbanTaskActionState({
    this.busy = false,
    this.error,
    this.lastMessage,
  });

  /// An action call is in flight.
  final bool busy;

  /// Human-readable failure, or null.
  final String? error;

  /// Success message from the last action.
  final String? lastMessage;

  @override
  bool operator ==(Object other) {
    return other is KanbanTaskActionState &&
        other.busy == busy &&
        other.error == error &&
        other.lastMessage == lastMessage;
  }

  @override
  int get hashCode => Object.hash(busy, error, lastMessage);

  @override
  String toString() {
    return 'KanbanTaskActionState(busy: $busy, error: $error, lastMessage: $lastMessage)';
  }
}

/// Controller for kanban task actions (P5-05): create, edit, delete, bulk
/// update, comments, specify, decompose, reassign, reclaim, links.
final kanbanTaskActionControllerProvider =
    NotifierProvider<KanbanTaskActionController, KanbanTaskActionState>(
      KanbanTaskActionController.new,
    );

class KanbanTaskActionController extends Notifier<KanbanTaskActionState> {
  @override
  KanbanTaskActionState build() => const KanbanTaskActionState();

  /// Create a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> createTask({
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
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.createTask(
        title: title,
        body: body,
        assignee: assignee,
        tenant: tenant,
        priority: priority,
        workspaceKind: workspaceKind,
        parents: parents,
        triage: triage,
        skills: skills,
        modelOverride: modelOverride,
        providerOverride: providerOverride,
        reasoningEffort: reasoningEffort,
        goalMode: goalMode,
        goalMaxTurns: goalMaxTurns,
        maxRuntimeSeconds: maxRuntimeSeconds,
        projectId: projectId,
        board: board,
      );
      state = const KanbanTaskActionState(lastMessage: 'Task created');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Edit a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> editTask(
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
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.editTask(
        id,
        status: status,
        assignee: assignee,
        priority: priority,
        title: title,
        body: body,
        result: result,
        blockReason: blockReason,
        summary: summary,
        modelOverride: modelOverride,
        providerOverride: providerOverride,
        clearModelOverride: clearModelOverride,
        reasoningEffort: reasoningEffort,
        clearReasoningEffort: clearReasoningEffort,
        board: board,
      );
      state = const KanbanTaskActionState(lastMessage: 'Task updated');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      ref.invalidate(kanbanTaskDetailProvider(id));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Delete a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> deleteTask(String id, {String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.deleteTask(id, board: board);
      state = const KanbanTaskActionState(lastMessage: 'Task deleted');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      ref.invalidate(kanbanTaskDetailProvider(id));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Bulk update tasks. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> bulkUpdate({
    required List<String> ids,
    String? status,
    String? assignee,
    int? priority,
    bool? archive,
    bool? reclaimFirst,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      final result = await repository.bulkUpdate(
        ids: ids,
        status: status,
        assignee: assignee,
        priority: priority,
        archive: archive,
        reclaimFirst: reclaimFirst,
        board: board,
      );
      final successCount = result.results.where((item) => item.ok).length;
      state = KanbanTaskActionState(
        lastMessage: 'Updated $successCount of ${ids.length} tasks',
      );
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      for (final id in ids) {
        ref.invalidate(kanbanTaskDetailProvider(id));
      }
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Add a comment. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> addComment(
    String id, {
    required String body,
    String? author,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.addComment(id, body: body, author: author, board: board);
      state = const KanbanTaskActionState(lastMessage: 'Comment added');
      ref.invalidate(kanbanTaskDetailProvider(id));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Specify a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> specify(String id, {String? author, String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      final result = await repository.specify(id, author: author, board: board);
      final message = result.ok
          ? 'Task specified${result.newTitle != null ? ': ${result.newTitle}' : ''}'
          : 'Specify failed${result.reason != null ? ': ${result.reason}' : ''}';
      state = KanbanTaskActionState(
        lastMessage: result.ok ? message : null,
        error: result.ok ? null : message,
      );
      if (result.ok) {
        unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
        ref.invalidate(kanbanTaskDetailProvider(id));
      }
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Decompose a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> decompose(String id, {String? author, String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      final result = await repository.decompose(
        id,
        author: author,
        board: board,
      );
      final message = result.ok
          ? 'Task decomposed into ${result.childIds.length} children'
          : 'Decompose failed${result.reason != null ? ': ${result.reason}' : ''}';
      state = KanbanTaskActionState(
        lastMessage: result.ok ? message : null,
        error: result.ok ? null : message,
      );
      if (result.ok) {
        unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
        ref.invalidate(kanbanTaskDetailProvider(id));
      }
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Reassign a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> reassign(
    String id, {
    String? profile,
    bool reclaimFirst = false,
    String? reason,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.reassign(
        id,
        profile: profile,
        reclaimFirst: reclaimFirst,
        reason: reason,
        board: board,
      );
      state = const KanbanTaskActionState(lastMessage: 'Task reassigned');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      ref.invalidate(kanbanTaskDetailProvider(id));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Reclaim a task. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> reclaim(String id, {String? reason, String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.reclaim(id, reason: reason, board: board);
      state = const KanbanTaskActionState(lastMessage: 'Task reclaimed');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      ref.invalidate(kanbanTaskDetailProvider(id));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Add a parent-child link. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> addLink({
    required String parentId,
    required String childId,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.addLink(
        parentId: parentId,
        childId: childId,
        board: board,
      );
      state = const KanbanTaskActionState(lastMessage: 'Link added');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      ref.invalidate(kanbanTaskDetailProvider(parentId));
      ref.invalidate(kanbanTaskDetailProvider(childId));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  /// Remove a parent-child link. NEVER throws — failures land in [KanbanTaskActionState.error].
  Future<void> removeLink({
    required String parentId,
    required String childId,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanRepositoryProvider);
    if (repository == null) {
      state = const KanbanTaskActionState(error: 'Not connected to a gateway.');
      return;
    }
    state = const KanbanTaskActionState(busy: true);
    try {
      await repository.removeLink(
        parentId: parentId,
        childId: childId,
        board: board,
      );
      state = const KanbanTaskActionState(lastMessage: 'Link removed');
      unawaited(ref.read(kanbanBoardProvider.notifier).refresh());
      ref.invalidate(kanbanTaskDetailProvider(parentId));
      ref.invalidate(kanbanTaskDetailProvider(childId));
    } on GatewayException catch (error) {
      state = KanbanTaskActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanTaskActionState(error: error.toString());
    }
  }

  void clearError() {
    state = KanbanTaskActionState(
      busy: state.busy,
      lastMessage: state.lastMessage,
    );
  }
}
