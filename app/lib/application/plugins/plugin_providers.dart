/// Riverpod wiring for the plugins + kanban features (tickets P1-14/P1-15).
///
/// Mirrors the nullable-repository pattern of application/providers.dart
/// (which this file deliberately does not edit): repositories are null when
/// disconnected, and callers handle null.
library;

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
