/// Riverpod wiring for the plugins + kanban features (tickets P1-14/P1-15).
///
/// Mirrors the nullable-repository pattern of application/providers.dart
/// (which this file deliberately does not edit): repositories are null when
/// disconnected, and callers handle null.
library;

import 'dart:async';

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

/// The kanban board for the current connection.
///
/// MVP approach is poll-on-focus: the board is fetched on first build and on
/// explicit [KanbanBoardNotifier.refresh] (app-bar button); the live
/// `/api/plugins/kanban/events` WS feed (seeded from
/// [KanbanBoard.latestEventId]) is Phase 5 — see 06-kanban-rest.md.
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
    return repository.board();
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
    state = AsyncData(await repository.board());
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
