// P5-07: KanbanOrchestrationScreen renders assignees, profiles, orchestration and edit action.

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flit/presentation/settings/kanban_orchestration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders assignees section', (tester) async {
    final assignees = <KanbanAssignee>[
      const KanbanAssignee(
        name: 'default',
        onDisk: true,
        counts: <String, int>{'ready': 3},
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanAssigneesProvider.overrideWith((ref) => Future.value(assignees)),
          kanbanProfilesProvider.overrideWith((ref) => Future.value(const <KanbanProfile>[])),
          kanbanOrchestrationProvider.overrideWith((ref) => Future.value(null)),
          kanbanFleetActionControllerProvider.overrideWith(_FakeActionController.new),
        ],
        child: const MaterialApp(home: KanbanOrchestrationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Assignees (1)'), findsOneWidget);
  });

  testWidgets('renders profiles section with edit button', (tester) async {
    final profiles = <KanbanProfile>[
      const KanbanProfile(
        name: 'default',
        isDefault: true,
        model: 'claude-3',
        provider: 'anthropic',
        description: 'Default profile',
        descriptionAuto: false,
        skillCount: 5,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanAssigneesProvider.overrideWith((ref) => Future.value(const <KanbanAssignee>[])),
          kanbanProfilesProvider.overrideWith((ref) => Future.value(profiles)),
          kanbanOrchestrationProvider.overrideWith((ref) => Future.value(null)),
          kanbanFleetActionControllerProvider.overrideWith(_FakeActionController.new),
        ],
        child: const MaterialApp(home: KanbanOrchestrationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profiles (1)'), findsOneWidget);
  });

  testWidgets('renders orchestration settings with switches', (tester) async {
    final orchestration = const KanbanOrchestration(
      orchestratorProfile: 'orch',
      defaultAssignee: 'default',
      autoDecompose: true,
      autoPromoteChildren: false,
      resolvedOrchestratorProfile: 'orch',
      resolvedDefaultAssignee: 'default',
      activeProfile: 'orch',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanAssigneesProvider.overrideWith((ref) => Future.value(const <KanbanAssignee>[])),
          kanbanProfilesProvider.overrideWith((ref) => Future.value(const <KanbanProfile>[])),
          kanbanOrchestrationProvider.overrideWith((ref) => Future.value(orchestration)),
          kanbanFleetActionControllerProvider.overrideWith(_FakeActionController.new),
        ],
        child: const MaterialApp(home: KanbanOrchestrationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Orchestration Settings'), findsOneWidget);
  });

  testWidgets('edit description button opens dialog', (tester) async {
    final controller = _FakeActionController();
    final profiles = <KanbanProfile>[
      const KanbanProfile(
        name: 'default',
        isDefault: true,
        model: 'claude-3',
        provider: 'anthropic',
        description: 'Old description',
        descriptionAuto: false,
        skillCount: 5,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanAssigneesProvider.overrideWith((ref) => Future.value(const <KanbanAssignee>[])),
          kanbanProfilesProvider.overrideWith((ref) => Future.value(profiles)),
          kanbanOrchestrationProvider.overrideWith((ref) => Future.value(null)),
          kanbanFleetActionControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: KanbanOrchestrationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Expand profiles section
    await tester.tap(find.text('Profiles (1)'));
    await tester.pumpAndSettle();

    // Tap edit button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edit default Description'), findsOneWidget);

    // Enter new description and save
    await tester.enterText(find.byType(TextField), 'New description');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(controller.setProfileDescriptionCalled, isTrue);
    expect(controller.lastProfileName, 'default');
  });

  testWidgets('orchestration switch calls controller', (tester) async {
    final controller = _FakeActionController();
    final orchestration = const KanbanOrchestration(
      orchestratorProfile: 'orch',
      defaultAssignee: 'default',
      autoDecompose: false,
      autoPromoteChildren: false,
      resolvedOrchestratorProfile: 'orch',
      resolvedDefaultAssignee: 'default',
      activeProfile: 'orch',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kanbanAssigneesProvider.overrideWith((ref) => Future.value(const <KanbanAssignee>[])),
          kanbanProfilesProvider.overrideWith((ref) => Future.value(const <KanbanProfile>[])),
          kanbanOrchestrationProvider.overrideWith((ref) => Future.value(orchestration)),
          kanbanFleetActionControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: KanbanOrchestrationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // The orchestration section is already expanded by default (initiallyExpanded: true)
    // Toggle auto decompose switch by finding the specific SwitchListTile
    final switchFinder = find.byWidgetPredicate(
      (widget) => widget is SwitchListTile && widget.title is Text && (widget.title! as Text).data == 'Auto Decompose',
    );

    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(controller.setOrchestrationCalled, isTrue);
  });
}

final class _FakeActionController extends KanbanFleetActionController {
  _FakeActionController({
    this.error,
    this.lastMessage,
  });

  final String? error;
  final String? lastMessage;
  bool setProfileDescriptionCalled = false;
  String? lastProfileName;
  bool setOrchestrationCalled = false;

  @override
  KanbanFleetActionState build() {
    return KanbanFleetActionState(
      error: error,
      lastMessage: lastMessage,
    );
  }

  @override
  Future<void> setProfileDescription(String name, String description) async {
    setProfileDescriptionCalled = true;
    lastProfileName = name;
  }

  @override
  Future<void> setOrchestration({
    String? orchestratorProfile,
    String? defaultAssignee,
    bool? autoDecompose,
    bool? autoPromoteChildren,
  }) async {
    setOrchestrationCalled = true;
  }

  @override
  void clearError() {}
}
