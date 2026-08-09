/// Riverpod wiring for kanban fleet operations & orchestration (P5-06/P5-07).
///
/// Mirrors the nullable-repository pattern of plugin_providers.dart:
/// repositories are null when disconnected, and FutureProviders return
/// empty/null when the repository is null.
library;

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/kanban_fleet_repository.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flit/domain/repositories/kanban_fleet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The kanban fleet repository for the current connection, or null when
/// there is no REST client (disconnected).
final kanbanFleetRepositoryProvider = Provider<KanbanFleetRepository?>((ref) {
  final client = ref.watch(restClientProvider);
  if (client == null) {
    return null;
  }
  return KanbanFleetRepositoryImpl(client);
});

/// All boards from `GET /boards`; empty when disconnected.
final kanbanBoardsProvider = FutureProvider<KanbanBoardList?>((ref) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.listBoards();
});

/// Fleet stats from `GET /stats`; null when disconnected.
final kanbanStatsProvider = FutureProvider<KanbanStats?>((ref) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.stats();
});

/// Active workers from `GET /workers/active`; empty when disconnected.
final kanbanWorkersProvider = FutureProvider<List<KanbanWorker>>((ref) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return const <KanbanWorker>[];
  }
  return repository.activeWorkers();
});

/// Diagnostics from `GET /diagnostics`; empty when disconnected.
final kanbanDiagnosticsProvider = FutureProvider<List<KanbanDiagnosticGroup>>((
  ref,
) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return const <KanbanDiagnosticGroup>[];
  }
  return repository.diagnostics();
});

/// Assignees from `GET /assignees`; empty when disconnected.
final kanbanAssigneesProvider = FutureProvider<List<KanbanAssignee>>((
  ref,
) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return const <KanbanAssignee>[];
  }
  return repository.listAssignees();
});

/// Profiles from `GET /profiles`; empty when disconnected.
final kanbanProfilesProvider = FutureProvider<List<KanbanProfile>>((ref) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return const <KanbanProfile>[];
  }
  return repository.listProfiles();
});

/// Orchestration settings from `GET /orchestration`; null when disconnected.
final kanbanOrchestrationProvider = FutureProvider<KanbanOrchestration?>((
  ref,
) async {
  final repository = ref.watch(kanbanFleetRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.orchestration();
});

/// Interaction state for kanban fleet actions (P5-06/P5-07).
final class KanbanFleetActionState {
  const KanbanFleetActionState({
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
    return other is KanbanFleetActionState &&
        other.busy == busy &&
        other.error == error &&
        other.lastMessage == lastMessage;
  }

  @override
  int get hashCode => Object.hash(busy, error, lastMessage);

  @override
  String toString() {
    return 'KanbanFleetActionState(busy: $busy, error: $error, lastMessage: $lastMessage)';
  }
}

/// Controller for kanban fleet actions (P5-06/P5-07): boards, dispatch,
/// workers, profiles, orchestration.
final kanbanFleetActionControllerProvider =
    NotifierProvider<KanbanFleetActionController, KanbanFleetActionState>(
      KanbanFleetActionController.new,
    );

class KanbanFleetActionController extends Notifier<KanbanFleetActionState> {
  @override
  KanbanFleetActionState build() => const KanbanFleetActionState();

  /// Create a board. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> createBoard({
    required String slug,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    String? projectId,
    bool switchTo = false,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      await repository.createBoard(
        slug: slug,
        name: name,
        description: description,
        icon: icon,
        color: color,
        defaultWorkdir: defaultWorkdir,
        projectId: projectId,
        switchTo: switchTo,
        board: board,
      );
      state = const KanbanFleetActionState(lastMessage: 'Board created');
      ref.invalidate(kanbanBoardsProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Update a board. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> updateBoard(
    String slug, {
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    String? projectId,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      await repository.updateBoard(
        slug,
        name: name,
        description: description,
        icon: icon,
        color: color,
        defaultWorkdir: defaultWorkdir,
        projectId: projectId,
        board: board,
      );
      state = const KanbanFleetActionState(lastMessage: 'Board updated');
      ref.invalidate(kanbanBoardsProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Delete or archive a board. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> deleteBoard(
    String slug, {
    bool delete = false,
    String? board,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      await repository.deleteBoard(slug, delete: delete, board: board);
      state = KanbanFleetActionState(
        lastMessage: delete ? 'Board deleted' : 'Board archived',
      );
      ref.invalidate(kanbanBoardsProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Switch to a board. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> switchBoard(String slug) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      final current = await repository.switchBoard(slug);
      state = KanbanFleetActionState(lastMessage: 'Switched to $current');
      ref.invalidate(kanbanBoardsProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Dispatch workers. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> dispatch({bool dryRun = false, int? max, String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      final result = await repository.dispatch(
        dryRun: dryRun,
        max: max,
        board: board,
      );
      final message = dryRun
          ? 'Dry run: ${result.spawnedCount} would spawn'
          : 'Dispatched: ${result.spawnedCount} spawned, ${result.reclaimed} reclaimed, ${result.promoted} promoted';
      state = KanbanFleetActionState(lastMessage: message);
      ref.invalidate(kanbanWorkersProvider);
      ref.invalidate(kanbanStatsProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Terminate a worker. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> terminateRun(int runId, {String? reason, String? board}) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      await repository.terminateRun(runId, reason: reason, board: board);
      state = const KanbanFleetActionState(lastMessage: 'Worker terminated');
      ref.invalidate(kanbanWorkersProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Set profile description. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> setProfileDescription(String name, String description) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      await repository.setProfileDescription(name, description);
      state = const KanbanFleetActionState(lastMessage: 'Profile updated');
      ref.invalidate(kanbanProfilesProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  /// Update orchestration settings. NEVER throws — failures land in [KanbanFleetActionState.error].
  Future<void> setOrchestration({
    String? orchestratorProfile,
    String? defaultAssignee,
    bool? autoDecompose,
    bool? autoPromoteChildren,
  }) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(kanbanFleetRepositoryProvider);
    if (repository == null) {
      state = const KanbanFleetActionState(
        error: 'Not connected to a gateway.',
      );
      return;
    }
    state = const KanbanFleetActionState(busy: true);
    try {
      await repository.setOrchestration(
        orchestratorProfile: orchestratorProfile,
        defaultAssignee: defaultAssignee,
        autoDecompose: autoDecompose,
        autoPromoteChildren: autoPromoteChildren,
      );
      state = const KanbanFleetActionState(
        lastMessage: 'Orchestration updated',
      );
      ref.invalidate(kanbanOrchestrationProvider);
    } on GatewayException catch (error) {
      state = KanbanFleetActionState(error: error.message);
    } on Object catch (error) {
      state = KanbanFleetActionState(error: error.toString());
    }
  }

  void clearError() {
    state = KanbanFleetActionState(
      busy: state.busy,
      lastMessage: state.lastMessage,
    );
  }
}
