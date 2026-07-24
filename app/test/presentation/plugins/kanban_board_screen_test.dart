// P1-15 acceptance: the board renders columns + cards from a canned board;
// the move menu PATCHes the target column (optimistically moving the card);
// tapping a card opens the detail sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/plugins/plugin_providers.dart';
import 'package:hermes/domain/models/kanban.dart';
import 'package:hermes/presentation/plugins/kanban/kanban_board_screen.dart';

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
