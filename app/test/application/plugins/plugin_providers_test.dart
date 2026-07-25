// P1-14/P1-15 acceptance: plugins + kanban providers against fake
// repositories — null-when-disconnected behavior, board load/refresh, and
// the OPTIMISTIC moveTask (apply locally, PATCH, rollback on failure).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flit/domain/repositories/kanban_repository.dart';
import 'package:flit/domain/repositories/plugin_repository.dart';

/// Fake plugin repository answering from [plugins].
final class FakePluginRepository implements PluginRepository {
  FakePluginRepository({this.plugins = const <PluginInfo>[], this.error});

  List<PluginInfo> plugins;
  Exception? error;
  int listCalls = 0;

  @override
  Future<List<PluginInfo>> list() async {
    listCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return plugins;
  }
}

/// Fake kanban repository with a settable board and recorded PATCHes.
final class FakeKanbanRepository implements KanbanRepository {
  FakeKanbanRepository({required this.boardResult});

  KanbanBoard boardResult;
  Exception? updateError;
  final List<({String id, String status})> statusUpdates =
      <({String id, String status})>[];

  @override
  Future<KanbanBoard> board({String? board}) async => boardResult;

  @override
  Future<KanbanTaskDetail> task(String id) async => KanbanTaskDetail(
    task: KanbanTask(id: id, title: 'Task $id'),
  );

  @override
  Future<void> updateTaskStatus(String id, String status) async {
    statusUpdates.add((id: id, status: status));
    final failure = updateError;
    if (failure != null) {
      throw failure;
    }
  }
}

const _board = KanbanBoard(
  columns: <KanbanColumn>[
    KanbanColumn(
      name: 'triage',
      tasks: <KanbanTask>[
        KanbanTask(id: '1', title: 'Task one', status: 'triage'),
      ],
    ),
    KanbanColumn(
      name: 'todo',
      tasks: <KanbanTask>[
        KanbanTask(id: '2', title: 'Task two', status: 'todo'),
      ],
    ),
    KanbanColumn(name: 'done'),
  ],
  latestEventId: 42,
);

void main() {
  group('pluginsProvider', () {
    test('returns the fake repository plugins', () async {
      final repository = FakePluginRepository(
        plugins: const <PluginInfo>[
          PluginInfo(name: 'kanban', version: '1.0.0', enabled: true),
        ],
      );
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(pluginsProvider.future), const <PluginInfo>[
        PluginInfo(name: 'kanban', version: '1.0.0', enabled: true),
      ]);
      expect(repository.listCalls, 1);
    });

    test('is empty when the repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(await container.read(pluginsProvider.future), isEmpty);
    });
  });

  group('kanbanBoardProvider', () {
    test('loads the board from the fake repository', () async {
      final container = ProviderContainer(
        overrides: [
          kanbanRepositoryProvider.overrideWithValue(
            FakeKanbanRepository(boardResult: _board),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(kanbanBoardProvider.future), _board);
    });

    test('is null when the repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [kanbanRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(await container.read(kanbanBoardProvider.future), isNull);
    });
  });

  group('KanbanBoardNotifier.moveTask (optimistic + rollback)', () {
    test(
      'happy path: applies the move locally and PATCHes the status',
      () async {
        final repository = FakeKanbanRepository(boardResult: _board);
        final container = ProviderContainer(
          overrides: [kanbanRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        await container.read(kanbanBoardProvider.future);

        await container
            .read(kanbanBoardProvider.notifier)
            .moveTask('1', 'done');

        expect(repository.statusUpdates, <({String id, String status})>[
          (id: '1', status: 'done'),
        ]);
        final board = container.read(kanbanBoardProvider).value!;
        expect(board.columns[0].tasks, isEmpty); // triage
        expect(board.columns[2].tasks.single.id, '1'); // done
        expect(board.columns[2].tasks.single.status, 'done');
        // Untouched columns keep their tasks.
        expect(board.columns[1].tasks.single.id, '2');
      },
    );

    test('failure path: rolls back and rethrows', () async {
      final repository = FakeKanbanRepository(boardResult: _board)
        ..updateError = const GatewayNetworkException('offline');
      final container = ProviderContainer(
        overrides: [kanbanRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(kanbanBoardProvider.future);

      await expectLater(
        container.read(kanbanBoardProvider.notifier).moveTask('1', 'done'),
        throwsA(isA<GatewayNetworkException>()),
      );

      // Rolled back to the pre-move board.
      expect(container.read(kanbanBoardProvider).value, _board);
    });
  });
}
