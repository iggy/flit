// P5-06: KanbanFleetScreen renders stats, workers, diagnostics and dispatch action.

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flit/presentation/settings/kanban_fleet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders stats section', (tester) async {
    final stats = KanbanStats(
      byStatus: const <String, int>{'ready': 5, 'running': 3},
      byAssignee: const <String, Map<String, int>>{},
      oldestReadyAgeSeconds: 3600,
      now: DateTime.now().toUtc(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanStatsProvider.overrideWith((ref) => Future.value(stats)),
          kanbanWorkersProvider.overrideWith((ref) => Future.value(const <KanbanWorker>[])),
          kanbanDiagnosticsProvider.overrideWith((ref) => Future.value(const <KanbanDiagnosticGroup>[])),
          kanbanFleetActionControllerProvider.overrideWith(_FakeActionController.new),
        ],
        child: const MaterialApp(home: KanbanFleetScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fleet Stats'), findsOneWidget);
    expect(find.text('ready'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('renders active workers', (tester) async {
    final workers = <KanbanWorker>[
      KanbanWorker(
        runId: 101,
        taskId: 'task-1',
        taskTitle: 'Working on it',
        taskStatus: 'running',
        workerPid: 1234,
        startedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanStatsProvider.overrideWith((ref) => Future.value(null)),
          kanbanWorkersProvider.overrideWith((ref) => Future.value(workers)),
          kanbanDiagnosticsProvider.overrideWith((ref) => Future.value(const <KanbanDiagnosticGroup>[])),
          kanbanFleetActionControllerProvider.overrideWith(_FakeActionController.new),
        ],
        child: const MaterialApp(home: KanbanFleetScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Active Workers (1)'), findsOneWidget);
    expect(find.text('Working on it'), findsOneWidget);
  });

  testWidgets('terminate worker button calls controller', (tester) async {
    final controller = _FakeActionController();
    final workers = <KanbanWorker>[
      KanbanWorker(
        runId: 101,
        taskId: 'task-1',
        taskTitle: 'Working',
        taskStatus: 'running',
        workerPid: 1234,
        startedAt: DateTime.now().toUtc(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanStatsProvider.overrideWith((ref) => Future.value(null)),
          kanbanWorkersProvider.overrideWith((ref) => Future.value(workers)),
          kanbanDiagnosticsProvider.overrideWith((ref) => Future.value(const <KanbanDiagnosticGroup>[])),
          kanbanFleetActionControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: KanbanFleetScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap terminate button
    await tester.tap(find.byIcon(Icons.stop_circle_outlined));
    await tester.pumpAndSettle();

    // Confirm in dialog
    await tester.tap(find.text('Terminate'));
    await tester.pumpAndSettle();

    expect(controller.terminateRunCalled, isTrue);
    expect(controller.lastRunId, 101);
  });

  testWidgets('dispatch button calls controller', (tester) async {
    final controller = _FakeActionController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanStatsProvider.overrideWith((ref) => Future.value(null)),
          kanbanWorkersProvider.overrideWith((ref) => Future.value(const <KanbanWorker>[])),
          kanbanDiagnosticsProvider.overrideWith((ref) => Future.value(const <KanbanDiagnosticGroup>[])),
          kanbanFleetActionControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: KanbanFleetScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap dispatch button
    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();

    expect(controller.dispatchCalled, isTrue);
    expect(controller.lastDryRun, isFalse);
  });

  testWidgets('shows diagnostics', (tester) async {
    final diagnostics = <KanbanDiagnosticGroup>[
      KanbanDiagnosticGroup(
        taskId: 'task-1',
        taskTitle: 'Task 1',
        diagnostics: <KanbanDiagnostic>[
          KanbanDiagnostic(
            kind: 'crash',
            severity: 'error',
            title: 'Worker crashed',
            detail: 'Out of memory',
            firstSeenAt: DateTime.now().toUtc(),
            lastSeenAt: DateTime.now().toUtc(),
            count: 3,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanStatsProvider.overrideWith((ref) => Future.value(null)),
          kanbanWorkersProvider.overrideWith((ref) => Future.value(const <KanbanWorker>[])),
          kanbanDiagnosticsProvider.overrideWith((ref) => Future.value(diagnostics)),
          kanbanFleetActionControllerProvider.overrideWith(_FakeActionController.new),
        ],
        child: const MaterialApp(home: KanbanFleetScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Diagnostics (1)'), findsOneWidget);
  });
}

final class _FakeActionController extends KanbanFleetActionController {
  _FakeActionController({
    this.error,
    this.lastMessage,
  });

  final String? error;
  final String? lastMessage;
  bool dispatchCalled = false;
  bool? lastDryRun;
  bool terminateRunCalled = false;
  int? lastRunId;

  @override
  KanbanFleetActionState build() {
    return KanbanFleetActionState(
      error: error,
      lastMessage: lastMessage,
    );
  }

  @override
  Future<void> dispatch({
    bool dryRun = false,
    int? max,
    String? board,
  }) async {
    dispatchCalled = true;
    lastDryRun = dryRun;
  }

  @override
  Future<void> terminateRun(
    int runId, {
    String? reason,
    String? board,
  }) async {
    terminateRunCalled = true;
    lastRunId = runId;
  }

  @override
  void clearError() {}
}
