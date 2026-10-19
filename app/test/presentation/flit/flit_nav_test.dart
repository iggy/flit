import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _Repo extends Fake implements FlitRepository {
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
    FlitProject(id: 'web', name: 'Web'),
  ];

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) async {
    expect(projectId, isNull, reason: 'the pane lists every session');
    return <FlitSession>[
      _s('a', 'Fix the build', 'web'),
      _s('b', 'Add a page', 'web'),
      _s('c', 'Try a thing', 'scratch'),
    ];
  }
}

void main() {
  Future<(GoRouter, ProviderContainer)> pump(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(_Repo())],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/flit/session/a',
      routes: <RouteBase>[
        ShellRoute(
          builder: (context, state, child) =>
              FlitShell(sessionId: state.pathParameters['id'], child: child),
          routes: <RouteBase>[
            GoRoute(
              path: '/flit',
              builder: (_, _) => const Scaffold(body: Text('session list')),
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
    return (router, container);
  }

  testWidgets('wide windows keep projects and sessions beside a session', (
    tester,
  ) async {
    final (_, container) = await pump(tester, const Size(1200, 800));
    expect(find.byType(FlitNavPane), findsOneWidget);
    expect(find.text('open a'), findsOneWidget);
    // The open session's project is expanded and the session selected.
    expect(find.text('Fix the build'), findsOneWidget);
    expect(find.text('Add a page'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Fix the build'),
              matching: find.byType(ListTile),
            ),
          )
          .selected,
      isTrue,
    );

    // Another session opens straight from the pane.
    await tester.tap(find.text('Add a page'));
    await tester.pumpAndSettle();
    expect(find.text('open b'), findsOneWidget);
    expect(find.byType(FlitNavPane), findsOneWidget);

    // A project name opens that project's session list.
    await tester.tap(find.text('Scratch'));
    await tester.pumpAndSettle();
    expect(find.text('session list'), findsOneWidget);
    expect(container.read(flitSelectedProjectProvider), 'scratch');
  });

  testWidgets('narrow windows have no pane', (tester) async {
    await pump(tester, const Size(400, 800));
    expect(find.byType(FlitNavPane), findsNothing);
    expect(find.text('open a'), findsOneWidget);
  });
}
