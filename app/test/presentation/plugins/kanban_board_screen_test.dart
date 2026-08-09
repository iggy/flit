// P1-15 acceptance: the board renders columns + cards from a canned board;
// the move menu PATCHes the target column (optimistically moving the card);
// tapping a card opens the detail sheet.

import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/presentation/plugins/kanban/kanban_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/plugins/plugin_providers_test.dart'
    show FakeKanbanRepository;

const _taskOne = KanbanTask(
  id: '1',
  title: 'Task one',
  status: 'triage',
  assignee: 'default',
  latestSummary: 'Started investigating',
  commentCount: 2,
  progress: KanbanProgress(done: 1, total: 3),
);
const _taskTwo = KanbanTask(id: '2', title: 'Task two', status: 'todo');

const _board = KanbanBoard(
  columns: <KanbanColumn>[
    KanbanColumn(name: 'triage', tasks: <KanbanTask>[_taskOne]),
    KanbanColumn(name: 'todo', tasks: <KanbanTask>[_taskTwo]),
    KanbanColumn(name: 'done'),
  ],
  latestEventId: 42,
);

Widget _wrap(FakeKanbanRepository repository) {
  return ProviderScope(
    overrides: [kanbanRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: KanbanBoardScreen()),
  );
}

void main() {
  testWidgets('renders columns and cards from the canned board', (
    tester,
  ) async {
    final repository = FakeKanbanRepository(boardResult: _board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Column headers + counts, in server order.
    expect(find.text('triage'), findsOneWidget);
    expect(find.text('todo'), findsOneWidget);
    expect(find.text('done'), findsOneWidget);

    // Cards: title, assignee, summary, badges.
    expect(find.text('Task one'), findsOneWidget);
    expect(find.text('Task two'), findsOneWidget);
    expect(find.text('default'), findsOneWidget);
    expect(find.text('Started investigating'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // comment-count badge
    expect(find.text('1/3'), findsOneWidget); // progress badge

    // Empty state (P1-16): the taskless 'done' column shows a hint.
    expect(find.text('No tasks'), findsOneWidget);
  });

  testWidgets('move menu triggers moveTask with the target column', (
    tester,
  ) async {
    final repository = FakeKanbanRepository(boardResult: _board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Open the move menu on the triage card.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    // The OTHER columns are listed, the current one is not.
    expect(find.text('Move to todo'), findsOneWidget);
    expect(find.text('Move to done'), findsOneWidget);
    expect(find.text('Move to triage'), findsNothing);

    await tester.tap(find.text('Move to done'));
    await tester.pumpAndSettle();

    // PATCHed with the target column as the status…
    expect(repository.statusUpdates, <({String id, String status})>[
      (id: '1', status: 'done'),
    ]);
    // …and the card moved optimistically (triage now shows 0).
    expect(find.text('Task one'), findsOneWidget);
  });

  testWidgets('tapping a card opens the detail sheet', (tester) async {
    final repository = FakeKanbanRepository(boardResult: _board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Task one'));
    await tester.pumpAndSettle();

    // FakeKanbanRepository.task answers "Task <id>" with no comments.
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Comments (0)'), findsOneWidget);
    expect(find.text('No comments yet.'), findsOneWidget);
  });

  testWidgets('cards badge the execution overrides and distress signals', (
    tester,
  ) async {
    const board = KanbanBoard(
      columns: <KanbanColumn>[
        KanbanColumn(
          name: 'running',
          tasks: <KanbanTask>[
            KanbanTask(
              id: '9',
              title: 'Deep task',
              status: 'running',
              modelOverride: 'claude-opus-5',
              providerOverride: 'anthropic',
              reasoningEffort: 'ultra',
              goalMode: true,
              goalMaxTurns: 8,
              blockKind: 'needs_input',
              blockRecurrences: 3,
              consecutiveFailures: 2,
            ),
          ],
        ),
      ],
    );
    final repository = FakeKanbanRepository(boardResult: board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('claude-opus-5'), findsOneWidget);
    expect(find.text('ultra'), findsOneWidget);
    expect(find.text('goal ≤8'), findsOneWidget);
    expect(find.text('needs_input ×3'), findsOneWidget);
    expect(find.text('2 failed'), findsOneWidget);
  });

  testWidgets('a plain card badges nothing', (tester) async {
    final repository = FakeKanbanRepository(boardResult: _board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // "no thinking" is the label for reasoning_effort: none, which is a
    // VALUE — a task that never set one must not show it.
    expect(find.text('no thinking'), findsNothing);
    expect(find.text('goal'), findsNothing);
  });

  testWidgets('reasoning_effort "none" badges as thinking-off', (tester) async {
    const board = KanbanBoard(
      columns: <KanbanColumn>[
        KanbanColumn(
          name: 'todo',
          tasks: <KanbanTask>[
            KanbanTask(
              id: '3',
              title: 'Quick task',
              status: 'todo',
              reasoningEffort: 'none',
            ),
          ],
        ),
      ],
    );
    final repository = FakeKanbanRepository(boardResult: board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('no thinking'), findsOneWidget);
  });

  testWidgets('the detail sheet shows the execution fields', (tester) async {
    const task = KanbanTask(
      id: '9',
      title: 'Deep task',
      status: 'running',
      projectId: 'proj-1',
      modelOverride: 'claude-opus-5',
      providerOverride: 'anthropic',
      reasoningEffort: 'high',
      goalMode: true,
      goalMaxTurns: 8,
      consecutiveFailures: 2,
      lastFailureError: 'worker crashed',
      workflowTemplateId: 'wf-2',
      currentStepKey: 'implement',
      workerPid: 4242,
    );
    final repository = FakeKanbanRepository(
      boardResult: const KanbanBoard(
        columns: <KanbanColumn>[
          KanbanColumn(name: 'running', tasks: <KanbanTask>[task]),
        ],
      ),
      taskDetail: const KanbanTaskDetail(task: task),
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deep task'));
    await tester.pumpAndSettle();

    expect(find.text('Project: proj-1'), findsOneWidget);
    expect(find.text('Model: claude-opus-5 (anthropic)'), findsOneWidget);
    expect(find.text('Thinking: high'), findsOneWidget);
    expect(find.text('Goal loop (≤ 8 turns)'), findsOneWidget);
    expect(find.text('Failures: 2'), findsOneWidget);
    expect(find.text('Workflow: wf-2 → implement'), findsOneWidget);
    expect(find.text('Worker PID: 4242'), findsOneWidget);
    expect(find.text('Last failure: worker crashed'), findsOneWidget);
  });

  testWidgets('emptying a set model override sends the clear flag', (
    tester,
  ) async {
    const task = KanbanTask(
      id: '9',
      title: 'Deep task',
      status: 'running',
      modelOverride: 'claude-opus-5',
      reasoningEffort: 'high',
    );
    final repository = FakeKanbanRepository(
      boardResult: const KanbanBoard(
        columns: <KanbanColumn>[
          KanbanColumn(name: 'running', tasks: <KanbanTask>[task]),
        ],
      ),
      taskDetail: const KanbanTaskDetail(task: task),
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deep task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Wipe the model field and drop the depth back to "Inherit profile".
    // The dialog scrolls, so the depth dropdown needs bringing into view.
    await tester.enterText(find.widgetWithText(TextField, 'Model override'), '');
    final depthDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(depthDropdown);
    await tester.pumpAndSettle();
    await tester.tap(depthDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inherit profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final call = repository.editCalls.single;
    expect(call.modelOverride, isNull);
    expect(call.clearModelOverride, isTrue);
    expect(call.reasoningEffort, isNull);
    expect(call.clearReasoningEffort, isTrue);
  });

  testWidgets('editing a task that never had overrides clears nothing', (
    tester,
  ) async {
    final repository = FakeKanbanRepository(boardResult: _board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Task one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final call = repository.editCalls.single;
    expect(call.clearModelOverride, isFalse);
    expect(call.clearReasoningEffort, isFalse);
  });

  testWidgets('refresh button re-fetches the board', (tester) async {
    final repository = FakeKanbanRepository(boardResult: _board);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    repository.boardResult = const KanbanBoard(
      columns: <KanbanColumn>[
        KanbanColumn(name: 'triage'),
        KanbanColumn(name: 'todo', tasks: <KanbanTask>[_taskTwo]),
        KanbanColumn(
          name: 'done',
          tasks: <KanbanTask>[
            KanbanTask(id: '1', title: 'Task one', status: 'done'),
          ],
        ),
      ],
    );
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // The re-fetched board is rendered (both tasks now in later columns).
    expect(find.text('Task one'), findsOneWidget);
    expect(find.text('Task two'), findsOneWidget);
  });
}
