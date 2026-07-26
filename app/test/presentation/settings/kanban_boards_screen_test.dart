// P5-06: KanbanBoardsScreen renders boards and wires create/switch actions.

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flit/presentation/settings/kanban_boards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders boards list with current board indicator', (
    tester,
  ) async {
    final boards = KanbanBoardList(
      boards: <KanbanBoardMeta>[
        KanbanBoardMeta(
          slug: 'main',
          name: 'Main Board',
          description: 'Default',
          icon: '',
          color: '',
          archived: false,
          dbPath: '/data/main.db',
          isCurrent: true,
          counts: const <String, int>{'ready': 5},
          total: 10,
          defaultWorkspaceKind: 'scratch',
        ),
        KanbanBoardMeta(
          slug: 'ops',
          name: 'Ops Board',
          description: '',
          icon: '',
          color: '',
          archived: false,
          dbPath: '/data/ops.db',
          isCurrent: false,
          counts: const <String, int>{},
          total: 0,
          defaultWorkspaceKind: 'scratch',
        ),
      ],
      current: 'main',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanBoardsProvider.overrideWith((ref) => Future.value(boards)),
          kanbanFleetActionControllerProvider.overrideWith(
            _FakeActionController.new,
          ),
        ],
        child: const MaterialApp(home: KanbanBoardsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Main Board'), findsOneWidget);
    expect(find.text('Ops Board'), findsOneWidget);
    expect(find.text('Current board: main'), findsOneWidget);
    expect(find.text('Total tasks: 10'), findsOneWidget);
  });

  testWidgets('shows empty state when no boards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanBoardsProvider.overrideWith(
            (ref) => Future.value(
              const KanbanBoardList(boards: <KanbanBoardMeta>[], current: ''),
            ),
          ),
          kanbanFleetActionControllerProvider.overrideWith(
            _FakeActionController.new,
          ),
        ],
        child: const MaterialApp(home: KanbanBoardsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No boards available'), findsOneWidget);
  });

  testWidgets('shows error banner when action state has error', (tester) async {
    final boards = KanbanBoardList(
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
          counts: const <String, int>{},
          total: 0,
          defaultWorkspaceKind: 'scratch',
        ),
      ],
      current: 'main',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanBoardsProvider.overrideWith((ref) => Future.value(boards)),
          kanbanFleetActionControllerProvider.overrideWith(
            () => _FakeActionController(error: 'Network error'),
          ),
        ],
        child: const MaterialApp(home: KanbanBoardsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
  });

  testWidgets('switch action calls controller', (tester) async {
    final controller = _FakeActionController();
    final boards = KanbanBoardList(
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
          counts: const <String, int>{},
          total: 0,
          defaultWorkspaceKind: 'scratch',
        ),
        KanbanBoardMeta(
          slug: 'ops',
          name: 'Ops',
          description: '',
          icon: '',
          color: '',
          archived: false,
          dbPath: '/data/ops.db',
          isCurrent: false,
          counts: const <String, int>{},
          total: 0,
          defaultWorkspaceKind: 'scratch',
        ),
      ],
      current: 'main',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanBoardsProvider.overrideWith((ref) => Future.value(boards)),
          kanbanFleetActionControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: KanbanBoardsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap popup menu on the second board
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();

    // Tap "Switch to this board"
    await tester.tap(find.text('Switch to this board'));
    await tester.pumpAndSettle();

    expect(controller.switchBoardCalled, isTrue);
    expect(controller.lastSlug, 'ops');
  });
}

final class _FakeActionController extends KanbanFleetActionController {
  _FakeActionController({this.error, this.lastMessage});

  final String? error;
  final String? lastMessage;
  bool switchBoardCalled = false;
  String? lastSlug;

  @override
  KanbanFleetActionState build() {
    return KanbanFleetActionState(error: error, lastMessage: lastMessage);
  }

  @override
  Future<void> createBoard({
    required String slug,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? defaultWorkdir,
    bool switchTo = false,
    String? board,
  }) async {}

  @override
  Future<void> switchBoard(String slug) async {
    switchBoardCalled = true;
    lastSlug = slug;
  }

  @override
  Future<void> deleteBoard(
    String slug, {
    bool delete = false,
    String? board,
  }) async {}

  @override
  void clearError() {}
}
