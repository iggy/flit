import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_nav.dart';
import 'package:flit/presentation/flit/flit_sessions_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _Repo extends Fake implements FlitRepository {
  final List<String> calls = <String>[];

  static FlitSession _s(String id, String title, String project) => FlitSession(
    id: id,
    title: title,
    workingDir: '/src',
    provider: 'local',
    model: 'qwen',
    state: FlitTaskState.idle,
    lastSeq: 0,
    projectId: project,
  );

  @override
  Future<List<FlitProject>> listProjects() async => const <FlitProject>[
    FlitProject(id: 'scratch', name: 'Scratch'),
    FlitProject(id: 'web', name: 'Web', directory: '/src/web'),
  ];

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) async =>
      <FlitSession>[
        _s('a', 'Fix the build', 'web'),
        _s('c', 'Try a thing', 'scratch'),
      ].where((s) => projectId == null || s.projectId == projectId).toList();

  @override
  Future<List<FlitAgentRole>> listRoles() async => const <FlitAgentRole>[];

  @override
  Future<FlitSession> createSession({
    required String workingDir,
    String title = '',
    String provider = '',
    String model = '',
    String effort = '',
    String role = '',
    String projectId = '',
  }) async {
    calls.add('create $projectId $workingDir');
    return _s('new', 'New', projectId);
  }

  @override
  Future<FlitProject> setProjectExport(
    String projectId, {
    required bool enabled,
  }) async {
    calls.add('export $projectId $enabled');
    return FlitProject(id: projectId, name: projectId, exportEnabled: enabled);
  }
}

void main() {
  Future<(_Repo, GoRouter)> pump(
    WidgetTester tester, {
    required Size size,
    required String initialLocation,
    Widget Function()? list,
    String? selectedProject,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    final container = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    if (selectedProject != null) {
      container
          .read(flitSelectedProjectProvider.notifier)
          .select(selectedProject);
    }
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        ShellRoute(
          builder: (context, state, child) =>
              FlitShell(sessionId: state.pathParameters['id'], child: child),
          routes: <RouteBase>[
            GoRoute(
              path: '/flit',
              builder: (_, _) =>
                  list?.call() ?? const Scaffold(body: Text('session list')),
              routes: <RouteBase>[
                GoRoute(
                  path: 'session/:id',
                  builder: (_, state) => Scaffold(
                    body: Text('open ${state.pathParameters['id']}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (repo, router);
  }

  Future<void> startSession(WidgetTester tester) async {
    expect(find.widgetWithText(AlertDialog, 'New session'), findsOneWidget);
    // The directory starts at the project's.
    expect(find.widgetWithText(TextField, '/src/web'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
  }

  testWidgets('right-clicking a project offers New session in it', (
    tester,
  ) async {
    final (repo, _) = await pump(
      tester,
      size: const Size(1200, 800),
      initialLocation: '/flit/session/c',
    );
    await tester.tap(find.text('Web'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('New session…'), findsOneWidget);
    expect(find.text('Include in exports'), findsOneWidget);
    expect(find.text('A git worktree per session'), findsOneWidget);

    await tester.tap(find.text('New session…'));
    await tester.pumpAndSettle();
    await startSession(tester);
    expect(repo.calls, <String>['create web /src/web']);
    expect(find.text('open new'), findsOneWidget);
  });

  testWidgets('long-pressing a project opens the same menu', (tester) async {
    final (repo, _) = await pump(
      tester,
      size: const Size(1200, 800),
      initialLocation: '/flit/session/c',
    );
    await tester.longPress(find.text('Scratch'));
    await tester.pumpAndSettle();
    expect(find.text('New session…'), findsOneWidget);
    // Scratch has no directory, so no worktree option.
    expect(find.text('A git worktree per session'), findsNothing);

    await tester.tap(find.text('Include in exports'));
    await tester.pumpAndSettle();
    expect(repo.calls, <String>['export scratch false']);
    // Still on the open session.
    expect(find.text('open c'), findsOneWidget);
  });

  testWidgets('the New session button takes the same path', (tester) async {
    final (repo, _) = await pump(
      tester,
      size: const Size(400, 800),
      initialLocation: '/flit',
      list: () => const FlitSessionsScreen(),
      selectedProject: 'web',
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await startSession(tester);
    expect(repo.calls, <String>['create web /src/web']);
    expect(find.text('open new'), findsOneWidget);
  });
}
