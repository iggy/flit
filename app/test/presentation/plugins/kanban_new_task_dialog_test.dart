// P5-05 acceptance: KanbanNewTaskDialog submits form fields to createTask.

import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/domain/repositories/kanban_repository.dart';
import 'package:flit/presentation/plugins/kanban/kanban_new_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('submits title (required) and optional fields', (tester) async {
    final repository = _FakeKanbanRepository();
    final container = ProviderContainer(
      overrides: [
        kanbanRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: KanbanNewTaskDialog()),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Test task');
    await tester.enterText(find.byType(TextFormField).at(1), 'Task body');
    await tester.enterText(find.byType(TextFormField).at(2), 'default');

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(repository.lastCreateCall?.title, 'Test task');
    expect(repository.lastCreateCall?.body, 'Task body');
    expect(repository.lastCreateCall?.assignee, 'default');
  });

  testWidgets('requires title', (tester) async {
    final container = ProviderContainer(
      overrides: [
        kanbanRepositoryProvider.overrideWithValue(_FakeKanbanRepository()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: KanbanNewTaskDialog()),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
  });

  testWidgets('shows busy state during submission', (tester) async {
    final container = ProviderContainer(
      overrides: [
        kanbanRepositoryProvider.overrideWithValue(
          _FakeKanbanRepository(delayMs: 100),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: KanbanNewTaskDialog()),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Test');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the delayed task to complete.
    await tester.pumpAndSettle();
  });
}

final class _FakeKanbanRepository implements KanbanRepository {
  _FakeKanbanRepository({this.delayMs = 0});

  final int delayMs;
  _CreateTaskCall? lastCreateCall;

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
    String? board,
  }) async {
    lastCreateCall = _CreateTaskCall(
      title: title,
      body: body,
      assignee: assignee,
      priority: priority,
      triage: triage,
    );
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    return KanbanTask(id: '1', title: title);
  }

  @override
  Future<KanbanBoard> board({String? board}) async => const KanbanBoard();

  @override
  Future<KanbanTaskDetail> task(String id) async =>
      KanbanTaskDetail(task: KanbanTask(id: id, title: 'Test'));

  @override
  Future<void> updateTaskStatus(String id, String status) async {}

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
    String? board,
  }) async =>
      null;

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
  }) async =>
      const KanbanBulkResult(results: <KanbanBulkItem>[]);

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
  }) async =>
      const KanbanSpecifyResult(ok: true, taskId: '');

  @override
  Future<KanbanDecomposeResult> decompose(
    String id, {
    String? author,
    String? board,
  }) async =>
      const KanbanDecomposeResult(ok: true, taskId: '', fanout: false);

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

final class _CreateTaskCall {
  const _CreateTaskCall({
    required this.title,
    this.body,
    this.assignee,
    this.priority,
    this.triage,
  });

  final String title;
  final String? body;
  final String? assignee;
  final int? priority;
  final bool? triage;
}
