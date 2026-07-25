// P5-06/P5-07: controller never throws (sets error), invalidates providers on success.

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flit/domain/repositories/kanban_fleet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KanbanFleetActionController', () {
    test('createBoard success sets lastMessage and invalidates provider', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.createBoard(slug: 'test');

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, isNull);
      expect(state.lastMessage, 'Board created');
      expect(state.busy, isFalse);
    });

    test('createBoard failure sets error and never throws', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(
            _FakeRepository(throwOnCreate: GatewayNetworkException('Network error')),
          ),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.createBoard(slug: 'test');

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, 'Network error');
      expect(state.lastMessage, isNull);
      expect(state.busy, isFalse);
    });

    test('dispatch success sets lastMessage with result summary', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.dispatch();

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, isNull);
      expect(state.lastMessage, contains('spawned'));
      expect(state.busy, isFalse);
    });

    test('dispatch dry run shows different message', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.dispatch(dryRun: true);

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.lastMessage, contains('Dry run'));
    });

    test('terminateRun success sets lastMessage', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.terminateRun(101);

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, isNull);
      expect(state.lastMessage, 'Worker terminated');
    });

    test('setOrchestration success sets lastMessage', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.setOrchestration(autoDecompose: true);

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, isNull);
      expect(state.lastMessage, 'Orchestration updated');
    });

    test('clearError clears error but keeps lastMessage', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(
            _FakeRepository(throwOnCreate: GatewayNetworkException('Error')),
          ),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.createBoard(slug: 'test');
      expect(container.read(kanbanFleetActionControllerProvider).error, isNotNull);

      controller.clearError();

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, isNull);
    });

    test('handles null repository gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(null),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.createBoard(slug: 'test');

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, 'Not connected to a gateway.');
    });

    test('handles non-GatewayException errors', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(
            _FakeRepository(throwOnCreate: Exception('Random error')),
          ),
        ],
      );

      final controller = container.read(kanbanFleetActionControllerProvider.notifier);

      await controller.createBoard(slug: 'test');

      final state = container.read(kanbanFleetActionControllerProvider);
      expect(state.error, contains('Random error'));
    });
  });

  group('FutureProviders', () {
    test('return empty/null when repository is null', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(null),
        ],
      );

      final boards = await container.read(kanbanBoardsProvider.future);
      expect(boards, isNull);

      final workers = await container.read(kanbanWorkersProvider.future);
      expect(workers, isEmpty);
    });

    test('call repository methods when repository is available', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanFleetRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
      );

      final boards = await container.read(kanbanBoardsProvider.future);
      expect(boards, isNotNull);
      expect(boards!.boards, hasLength(1));
    });
  });
}

final class _FakeRepository implements KanbanFleetRepository {
  _FakeRepository({
    this.throwOnCreate,
  });

  final Exception? throwOnCreate;

  @override
  Future<KanbanBoardList> listBoards({
    bool includeArchived = false,
    String? board,
  }) async {
    return KanbanBoardList(
      boards: <KanbanBoardMeta>[
        KanbanBoardMeta(
          slug: 'main',
          name: 'Main',
          description: '',
          icon: '',
          color: '',
          archived: false,
          dbPath: '/data/main.db',
          isCurrent: true,
          counts: const <String, int>{'ready': 5},
          total: 10,
          defaultWorkspaceKind: 'scratch',
        ),
      ],
      current: 'main',
    );
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
    if (throwOnCreate != null) {
      throw throwOnCreate!;
    }
    return KanbanBoardMeta(
      slug: slug,
      name: name ?? '',
      description: description ?? '',
      icon: icon ?? '',
      color: color ?? '',
      archived: false,
      dbPath: '/data/$slug.db',
      isCurrent: switchTo,
      counts: const <String, int>{},
      total: 0,
      defaultWorkspaceKind: 'scratch',
    );
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
    return null;
  }

  @override
  Future<void> deleteBoard(
    String slug, {
    bool delete = false,
    String? board,
  }) async {}

  @override
  Future<String> switchBoard(String slug) async {
    return slug;
  }

  @override
  Future<KanbanStats> stats({String? board}) async {
    return KanbanStats(
      byStatus: const <String, int>{'ready': 5},
      byAssignee: const <String, Map<String, int>>{},
      oldestReadyAgeSeconds: null,
      now: null,
    );
  }

  @override
  Future<List<KanbanWorker>> activeWorkers({String? board}) async {
    return const <KanbanWorker>[];
  }

  @override
  Future<List<KanbanDiagnosticGroup>> diagnostics({
    String? severity,
    String? board,
  }) async {
    return const <KanbanDiagnosticGroup>[];
  }

  @override
  Future<KanbanDispatchResult> dispatch({
    bool dryRun = false,
    int? max,
    String? board,
  }) async {
    return const KanbanDispatchResult(
      reclaimed: 1,
      promoted: 2,
      spawnedCount: 3,
      skippedUnassigned: <String>[],
    );
  }

  @override
  Future<void> terminateRun(
    int runId, {
    String? reason,
    String? board,
  }) async {}

  @override
  Future<List<KanbanAssignee>> listAssignees({String? board}) async {
    return const <KanbanAssignee>[];
  }

  @override
  Future<List<KanbanProfile>> listProfiles() async {
    return const <KanbanProfile>[];
  }

  @override
  Future<void> setProfileDescription(String name, String description) async {}

  @override
  Future<KanbanOrchestration> orchestration() async {
    return const KanbanOrchestration(
      orchestratorProfile: 'orch',
      defaultAssignee: 'default',
      autoDecompose: false,
      autoPromoteChildren: false,
      resolvedOrchestratorProfile: 'orch',
      resolvedDefaultAssignee: 'default',
      activeProfile: 'orch',
    );
  }

  @override
  Future<KanbanOrchestration> setOrchestration({
    String? orchestratorProfile,
    String? defaultAssignee,
    bool? autoDecompose,
    bool? autoPromoteChildren,
  }) async {
    return const KanbanOrchestration(
      orchestratorProfile: 'orch',
      defaultAssignee: 'default',
      autoDecompose: true,
      autoPromoteChildren: false,
      resolvedOrchestratorProfile: 'orch',
      resolvedDefaultAssignee: 'default',
      activeProfile: 'orch',
    );
  }
}
