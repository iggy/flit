import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_sessions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  @override
  Future<List<FlitProject>> listProjects() async => const <FlitProject>[
    FlitProject(id: 'scratch', name: 'Scratch'),
  ];

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) async =>
      const <FlitSession>[
        FlitSession(
          id: 'a',
          title: 'Add storage',
          workingDir: '/src/app',
          provider: 'local',
          model: 'qwen',
          state: FlitTaskState.waiting,
          lastSeq: 9,
          status: 'blocked on: which database to use',
        ),
        FlitSession(
          id: 'b',
          title: 'Quiet one',
          workingDir: '/src/other',
          provider: 'local',
          model: 'qwen',
          state: FlitTaskState.idle,
          lastSeq: 0,
        ),
      ];
}

void main() {
  testWidgets('session cards show the agent status line', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [flitRepositoryProvider.overrideWithValue(_Repo())],
        child: const MaterialApp(home: FlitSessionsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('blocked on: which database to use'), findsOneWidget);
    // Both cards still show their directory and model.
    expect(find.text('/src/app'), findsOneWidget);
    expect(find.text('/src/other'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
