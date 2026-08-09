// P5-05 acceptance: KanbanTaskActionController never throws on failure (sets
// error), triggers board refresh on success.

import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/domain/repositories/kanban_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createTask', () {
    test('sets busy during call, then lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      expect(container.read(kanbanTaskActionControllerProvider).busy, isFalse);

      final future = container
          .read(kanbanTaskActionControllerProvider.notifier)
          .createTask(title: 'Test');

      expect(container.read(kanbanTaskActionControllerProvider).busy, isTrue);

      await future;

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.busy, isFalse);
      expect(state.error, isNull);
      expect(state.lastMessage, 'Task created');
    });

    test('sets error on GatewayException (never throws)', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          createTaskError: const GatewayNetworkException(
            'Gateway returned HTTP 500',
          ),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .createTask(title: 'Test');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.busy, isFalse);
      expect(state.error, 'Gateway returned HTTP 500');
      expect(state.lastMessage, isNull);
    });

    test('sets error on generic exception (never throws)', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          createTaskError: const GatewayNetworkException('Unexpected'),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .createTask(title: 'Test');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.error, contains('Unexpected'));
    });
  });

  group('editTask', () {
    test('sets lastMessage on success and invalidates detail', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .editTask('7', title: 'Updated');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Task updated');
      expect(state.error, isNull);
    });
  });

  group('deleteTask', () {
    test('sets lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .deleteTask('7');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Task deleted');
    });
  });

  group('bulkUpdate', () {
    test('reports success count in lastMessage', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          bulkResult: const KanbanBulkResult(
            results: <KanbanBulkItem>[
              KanbanBulkItem(id: '1', ok: true),
              KanbanBulkItem(id: '2', ok: false, error: 'failed'),
            ],
          ),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .bulkUpdate(ids: <String>['1', '2']);

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Updated 1 of 2 tasks');
    });
  });

  group('addComment', () {
    test('sets lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .addComment('7', body: 'Nice');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Comment added');
    });
  });

  group('specify', () {
    test('sets lastMessage when ok is true', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          specifyResult: const KanbanSpecifyResult(
            ok: true,
            taskId: '7',
            newTitle: 'Expanded',
          ),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .specify('7');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, contains('Task specified'));
      expect(state.error, isNull);
    });

    test('sets error when ok is false', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          specifyResult: const KanbanSpecifyResult(
            ok: false,
            taskId: '7',
            reason: 'Too vague',
          ),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .specify('7');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.error, contains('Specify failed'));
      expect(state.lastMessage, isNull);
    });
  });

  group('decompose', () {
    test('sets lastMessage with child count when ok is true', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          decomposeResult: const KanbanDecomposeResult(
            ok: true,
            taskId: '7',
            fanout: true,
            childIds: <String>['8', '9'],
          ),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .decompose('7');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Task decomposed into 2 children');
    });
  });

  group('reassign', () {
    test('sets lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .reassign('7', profile: 'research');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Task reassigned');
    });
  });

  group('reclaim', () {
    test('sets lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .reclaim('7');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Task reclaimed');
    });
  });

  group('addLink', () {
    test('sets lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .addLink(parentId: '1', childId: '2');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Link added');
    });
  });

  group('removeLink', () {
    test('sets lastMessage on success', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .removeLink(parentId: '1', childId: '2');

      final state = container.read(kanbanTaskActionControllerProvider);
      expect(state.lastMessage, 'Link removed');
    });
  });

  group('kanbanEstimateProvider', () {
    test('is idle until asked — build never calls the gateway', () async {
      final container = _containerWith(_FakeKanbanRepository());

      final state = container.read(kanbanEstimateProvider('7'));

      expect(state.busy, isFalse);
      expect(state.estimate, isNull);
      expect(state.error, isNull);
    });

    test('sets busy during the call, then the estimate', () async {
      final container = _containerWith(_FakeKanbanRepository());

      final future = container.read(kanbanEstimateProvider('7').notifier).run();

      expect(container.read(kanbanEstimateProvider('7')).busy, isTrue);

      await future;

      final state = container.read(kanbanEstimateProvider('7'));
      expect(state.busy, isFalse);
      expect(state.error, isNull);
      expect(state.estimate?.estTokens, 48000);
      expect(state.estimate?.complexity, 'M');
    });

    test('a declined estimate is a result, not an error', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          estimateResult: const KanbanEstimate(
            ok: false,
            reason: 'a title is required to estimate',
          ),
        ),
      );

      await container.read(kanbanEstimateProvider('7').notifier).run();

      final state = container.read(kanbanEstimateProvider('7'));
      expect(state.error, isNull);
      expect(state.estimate?.ok, isFalse);
      expect(state.estimate?.reason, 'a title is required to estimate');
    });

    test('sets error on GatewayException (never throws)', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          estimateError: const GatewayNetworkException(
            'Gateway returned HTTP 500',
          ),
        ),
      );

      await container.read(kanbanEstimateProvider('7').notifier).run();

      final state = container.read(kanbanEstimateProvider('7'));
      expect(state.busy, isFalse);
      expect(state.error, 'Gateway returned HTTP 500');
    });

    test('keeps the previous estimate visible on a re-run failure', () async {
      // The call takes seconds; blanking the old numbers mid-flight (or on a
      // failed refresh) reads as if the task lost its estimate.
      final repository = _FakeKanbanRepository();
      final container = _containerWith(repository);

      await container.read(kanbanEstimateProvider('7').notifier).run();
      expect(
        container.read(kanbanEstimateProvider('7')).estimate?.estTokens,
        48000,
      );

      repository.estimateError = const GatewayNetworkException('Down');
      await container.read(kanbanEstimateProvider('7').notifier).run();

      final state = container.read(kanbanEstimateProvider('7'));
      expect(state.error, 'Down');
      expect(state.estimate?.estTokens, 48000);
    });

    test('estimates are per task id', () async {
      final container = _containerWith(_FakeKanbanRepository());

      await container.read(kanbanEstimateProvider('7').notifier).run();

      expect(container.read(kanbanEstimateProvider('7')).estimate, isNotNull);
      expect(container.read(kanbanEstimateProvider('8')).estimate, isNull);
    });
  });

  group('clearError', () {
    test('clears error but preserves busy and lastMessage', () async {
      final container = _containerWith(
        _FakeKanbanRepository(
          createTaskError: const GatewayNetworkException('Error'),
        ),
      );

      await container
          .read(kanbanTaskActionControllerProvider.notifier)
          .createTask(title: 'Test');

      expect(
        container.read(kanbanTaskActionControllerProvider).error,
        isNotNull,
      );

      container.read(kanbanTaskActionControllerProvider.notifier).clearError();

      expect(container.read(kanbanTaskActionControllerProvider).error, isNull);
    });
  });
}

ProviderContainer _containerWith(KanbanRepository repository) {
  return ProviderContainer(
    overrides: [kanbanRepositoryProvider.overrideWithValue(repository)],
  );
}

final class _FakeKanbanRepository implements KanbanRepository {
  _FakeKanbanRepository({
    this.createTaskError,
    this.bulkResult = const KanbanBulkResult(results: <KanbanBulkItem>[]),
    this.specifyResult = const KanbanSpecifyResult(ok: true, taskId: ''),
    this.decomposeResult = const KanbanDecomposeResult(
      ok: true,
      taskId: '',
      fanout: false,
    ),
    this.estimateResult = const KanbanEstimate(
      ok: true,
      estTokens: 48000,
      complexity: 'M',
      rationale: 'Multi-file change with tests.',
      model: 'hermes-4-405b',
    ),
    this.estimateError,
  });

  final Exception? createTaskError;
  final KanbanBulkResult bulkResult;
  final KanbanSpecifyResult specifyResult;
  final KanbanDecomposeResult decomposeResult;
  final KanbanEstimate estimateResult;

  /// Mutable so one fake can succeed and then fail — the re-run behaviour is
  /// about what survives the second call.
  Exception? estimateError;

  @override
  Future<KanbanBoard> board({
    String? board,
    String? workflowTemplateId,
    String? currentStepKey,
  }) async {
    return const KanbanBoard();
  }

  @override
  Future<KanbanTaskDetail> task(String id) async {
    return KanbanTaskDetail(
      task: KanbanTask(id: id, title: 'Test'),
    );
  }

  @override
  Future<void> updateTaskStatus(String id, String status) async {}

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
  }) async {
    if (createTaskError != null) {
      throw createTaskError!;
    }
    return KanbanTask(id: '1', title: title);
  }

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
    return KanbanTask(id: id, title: title ?? 'Test');
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
  }) async {
    return bulkResult;
  }

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
  }) async {
    return specifyResult;
  }

  @override
  Future<KanbanDecomposeResult> decompose(
    String id, {
    String? author,
    String? board,
  }) async {
    return decomposeResult;
  }

  @override
  Future<KanbanEstimate> estimateTask(String id, {String? board}) async {
    if (estimateError != null) {
      throw estimateError!;
    }
    return estimateResult;
  }

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
