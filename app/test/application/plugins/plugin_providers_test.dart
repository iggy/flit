// P1-14/P1-15 acceptance: plugins + kanban providers against fake
// repositories — null-when-disconnected behavior, board load/refresh, and
// the OPTIMISTIC moveTask (apply locally, PATCH, rollback on failure).

import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flit/domain/repositories/kanban_repository.dart';
import 'package:flit/domain/repositories/plugin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake plugin repository answering from [plugins].
final class FakePluginRepository implements PluginRepository {
  FakePluginRepository({
    this.plugins = const <PluginInfo>[],
    this.details = const <PluginDetail>[],
    this.error,
    this.toggleResult,
  });

  List<PluginInfo> plugins;
  List<PluginDetail> details;
  Exception? error;
  int listCalls = 0;
  int manageListCalls = 0;
  PluginDetail? toggleResult;
  final List<({String name, bool enable})> toggleCalls =
      <({String name, bool enable})>[];

  @override
  Future<List<PluginInfo>> list() async {
    listCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return plugins;
  }

  @override
  Future<List<PluginDetail>> manageList() async {
    manageListCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return details;
  }

  @override
  Future<PluginDetail?> toggle(String name, bool enable) async {
    toggleCalls.add((name: name, enable: enable));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return toggleResult;
  }
}

/// One recorded `editTask` call — enough to assert the model/effort clear
/// flags, which an omitted field cannot express.
typedef EditTaskCall = ({
  String id,
  String? modelOverride,
  String? providerOverride,
  bool clearModelOverride,
  String? reasoningEffort,
  bool clearReasoningEffort,
});

/// Fake kanban repository with a settable board and recorded PATCHes.
final class FakeKanbanRepository implements KanbanRepository {
  FakeKanbanRepository({required this.boardResult, this.taskDetail});

  KanbanBoard boardResult;

  /// Detail answered by [task]; null falls back to a bare `Task <id>`.
  KanbanTaskDetail? taskDetail;
  Exception? updateError;

  /// Answered by [estimateTask]; settable so a test can flip the outcome.
  KanbanEstimate estimateResult = const KanbanEstimate(
    ok: true,
    estTokens: 48000,
    complexity: 'M',
  );
  final List<({String id, String status})> statusUpdates =
      <({String id, String status})>[];
  final List<EditTaskCall> editCalls = <EditTaskCall>[];

  @override
  Future<KanbanBoard> board({String? board}) async => boardResult;

  @override
  Future<KanbanTaskDetail> task(String id) async =>
      taskDetail ??
      KanbanTaskDetail(
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
  }) async => null;

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
    editCalls.add((
      id: id,
      modelOverride: modelOverride,
      providerOverride: providerOverride,
      clearModelOverride: clearModelOverride,
      reasoningEffort: reasoningEffort,
      clearReasoningEffort: clearReasoningEffort,
    ));
    return null;
  }

  @override
  Future<void> deleteTask(String id, {String? board}) async {}

  @override
  Future<KanbanBulkResult> bulkUpdate({
    required List<String> ids,
    String? status,
    String? assignee,
    int? priority,
    bool? archive,
    bool? reclaimFirst,
    String? board,
  }) async => const KanbanBulkResult(results: <KanbanBulkItem>[]);

  @override
  Future<void> addComment(
    String id, {
    required String body,
    String? author,
    String? board,
  }) async {}

  @override
  Future<KanbanSpecifyResult> specify(
    String id, {
    String? author,
    String? board,
  }) async => const KanbanSpecifyResult(ok: true, taskId: '');

  @override
  Future<KanbanDecomposeResult> decompose(
    String id, {
    String? author,
    String? board,
  }) async => const KanbanDecomposeResult(ok: true, taskId: '', fanout: false);

  @override
  Future<KanbanEstimate> estimateTask(String id, {String? board}) async =>
      estimateResult;

  @override
  Future<void> reassign(
    String id, {
    String? profile,
    bool reclaimFirst = false,
    String? reason,
    String? board,
  }) async {}

  @override
  Future<void> reclaim(String id, {String? reason, String? board}) async {}

  @override
  Future<void> addLink({
    required String parentId,
    required String childId,
    String? board,
  }) async {}

  @override
  Future<void> removeLink({
    required String parentId,
    required String childId,
    String? board,
  }) async {}
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

  group('pluginDetailsProvider (P5-08)', () {
    test('returns the rich plugin details', () async {
      final repository = FakePluginRepository(
        details: const <PluginDetail>[
          PluginDetail(
            name: 'kanban',
            version: '1.0.0',
            description: 'Kanban board',
            source: 'bundled',
            status: 'enabled',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(pluginDetailsProvider.future),
        const <PluginDetail>[
          PluginDetail(
            name: 'kanban',
            version: '1.0.0',
            description: 'Kanban board',
            source: 'bundled',
            status: 'enabled',
          ),
        ],
      );
      expect(repository.manageListCalls, 1);
    });

    test('is empty when the repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(await container.read(pluginDetailsProvider.future), isEmpty);
    });
  });

  group('PluginToggleController (P5-08)', () {
    test('toggles a plugin and invalidates details on success', () async {
      final repository = FakePluginRepository(
        toggleResult: const PluginDetail(
          name: 'kanban',
          version: '1.0.0',
          description: 'Kanban board',
          source: 'bundled',
          status: 'enabled',
        ),
      );
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(pluginToggleControllerProvider.notifier)
          .toggle('kanban', true);

      expect(repository.toggleCalls, <({String name, bool enable})>[
        (name: 'kanban', enable: true),
      ]);
      expect(container.read(pluginToggleControllerProvider).error, isNull);
    });

    test('never throws — captures error in state', () async {
      final repository = FakePluginRepository()
        ..error = const GatewayNetworkException('offline');
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(pluginToggleControllerProvider.notifier)
          .toggle('kanban', true);

      expect(container.read(pluginToggleControllerProvider).error, isNotNull);
    });

    test('guards against null repository', () async {
      final container = ProviderContainer(
        overrides: [pluginRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      await container
          .read(pluginToggleControllerProvider.notifier)
          .toggle('kanban', true);

      expect(
        container.read(pluginToggleControllerProvider).error,
        'Not connected to a gateway.',
      );
    });
  });
}
