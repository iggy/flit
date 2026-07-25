// P5-09 acceptance: the skills screen renders category groups, reload action
// calls the controller, and displays reload results.

import 'package:flit/application/skills/skills_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/skill_catalog.dart';
import 'package:flit/presentation/settings/skills_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/skills/skills_providers_test.dart'
    show FakeSkillsRepository;

Widget _wrap(FakeSkillsRepository repository) {
  return ProviderScope(
    overrides: [skillsRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: SkillsScreen()),
  );
}

const _catalog = SkillCatalog(
  groups: <SkillGroup>[
    SkillGroup(category: 'built-in', names: <String>['loop', 'run', 'simplify']),
    SkillGroup(category: 'project', names: <String>['custom-skill']),
  ],
);

void main() {
  testWidgets('renders skill groups by category', (tester) async {
    final repository = FakeSkillsRepository(catalog: _catalog);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('built-in'), findsOneWidget);
    expect(find.text('3 skill(s)'), findsOneWidget);
    expect(find.text('project'), findsOneWidget);
    expect(find.text('1 skill(s)'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNWidgets(2));
  });

  testWidgets('expands category to show skill names', (tester) async {
    final repository = FakeSkillsRepository(catalog: _catalog);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Expand the built-in category.
    await tester.tap(find.text('built-in'));
    await tester.pumpAndSettle();

    expect(find.text('loop'), findsOneWidget);
    expect(find.text('run'), findsOneWidget);
    expect(find.text('simplify'), findsOneWidget);
  });

  testWidgets('reload action is present in app bar', (tester) async {
    final repository = FakeSkillsRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('reload action calls the controller', (tester) async {
    final repository = FakeSkillsRepository(
      reloadResult: const SkillReloadResult(
        output: 'Reload complete',
        added: <SkillChange>[],
        removed: <SkillChange>[],
        unchanged: <String>[],
        total: 5,
        commands: 3,
      ),
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(repository.reloadCalls, 1);
  });

  testWidgets('empty state when no skills are reported', (tester) async {
    await tester.pumpWidget(_wrap(FakeSkillsRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No skills reported by the gateway.'), findsOneWidget);
  });

  testWidgets('error state with retry', (tester) async {
    final repository = FakeSkillsRepository()
      ..error = const GatewayNetworkException('unreachable');
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Could not load skills'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
