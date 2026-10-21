import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_cron.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_crons.dart';
import 'package:flit/presentation/flit/flit_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _Repo extends Fake implements FlitRepository {
  final List<String> calls = <String>[];
  bool enabled = true;

  @override
  Future<List<FlitProject>> listProjects() async => const <FlitProject>[
    FlitProject(id: 'scratch', name: 'Scratch'),
  ];

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) async =>
      const <FlitSession>[
        FlitSession(
          id: 's1',
          title: 'nightly · 2026-10-21 03:00',
          workingDir: '/src',
          provider: 'local',
          model: 'qwen',
          state: FlitTaskState.done,
          lastSeq: 9,
          projectId: 'scratch',
          cronJob: 'nightly',
        ),
      ];

  @override
  Future<List<FlitCronJob>> listCronJobs() async => <FlitCronJob>[
    const FlitCronJob(
      name: 'broken',
      schedule: 'whenever',
      error: 'bad schedule',
    ),
    FlitCronJob(
      name: 'nightly',
      schedule: 'daily at 3:00',
      scheduleText: 'every day at 03:00',
      enabled: enabled,
      projectName: 'Scratch',
      prompt: 'Check the build.',
      nextRunAt: enabled ? DateTime(2030, 1, 1, 3) : null,
      lastRun: const FlitCronRun(
        id: 'r1',
        job: 'nightly',
        state: FlitCronRunState.needsAttention,
        summary: 'CI is red',
      ),
    ),
  ];

  @override
  Future<List<FlitCronRun>> listCronRuns({
    String name = '',
    int limit = 50,
  }) async => <FlitCronRun>[
    FlitCronRun(
      id: 'r1',
      job: 'nightly',
      sessionId: 's1',
      state: FlitCronRunState.needsAttention,
      summary: 'CI is red',
      startedAt: DateTime(2026, 10, 21, 3),
      refusedCommands: const <String>['git push'],
    ),
    const FlitCronRun(
      id: 'r0',
      job: 'nightly',
      state: FlitCronRunState.skipped,
      summary: 'skipped: the previous run was still going',
    ),
  ];

  @override
  Future<FlitCronRun> runCronJob(String name) async {
    calls.add('run $name');
    return FlitCronRun(
      id: 'r2',
      job: name,
      sessionId: 's2',
      state: FlitCronRunState.running,
    );
  }

  @override
  Future<FlitCronJob> setCronJobEnabled(
    String name, {
    required bool enabled,
  }) async {
    calls.add('enable $name $enabled');
    this.enabled = enabled;
    return (await listCronJobs()).last;
  }
}

void main() {
  Future<(GoRouter, _Repo)> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    final container = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/flit/crons',
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
                GoRoute(
                  path: 'crons',
                  builder: (_, _) => const FlitCronsScreen(),
                  routes: <RouteBase>[
                    GoRoute(
                      path: ':name',
                      builder: (_, state) => FlitCronJobScreen(
                        name: state.pathParameters['name'] ?? '',
                      ),
                    ),
                  ],
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
    return (router, repo);
  }

  testWidgets('the Crons screen lists jobs, runs them and switches them', (
    tester,
  ) async {
    final (_, repo) = await pump(tester, const Size(400, 800));
    expect(find.text('nightly'), findsOneWidget);
    expect(find.textContaining('every day at 03:00 · next'), findsOneWidget);
    expect(find.text('CI is red'), findsOneWidget);
    expect(find.text('Error: bad schedule'), findsOneWidget);

    await tester.tap(find.byTooltip('Run now').last);
    await tester.pumpAndSettle();
    expect(repo.calls, <String>['run nightly']);
    expect(find.text('Started nightly'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'enable nightly false');
    expect(find.text('every day at 03:00 · disabled'), findsOneWidget);
  });

  testWidgets('a job lists its runs, which open their sessions', (
    tester,
  ) async {
    final (router, _) = await pump(tester, const Size(400, 800));
    await tester.tap(find.text('nightly'));
    await tester.pumpAndSettle();
    expect(find.text('Check the build.'), findsOneWidget);
    expect(find.textContaining('Refused: git push'), findsOneWidget);
    expect(find.textContaining('still going'), findsOneWidget);
    await tester.tap(find.text('CI is red'));
    await tester.pumpAndSettle();
    expect(find.text('open s1'), findsOneWidget);
    expect(router.state.uri.path, '/flit/session/s1');
  });

  testWidgets('the side pane has a Cron section and badges cron runs', (
    tester,
  ) async {
    await pump(tester, const Size(1200, 800));
    expect(find.text('Cron'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();
    expect(find.byKey(flitCronBadgeKey), findsOneWidget);
    await tester.tap(find.byIcon(Icons.schedule).last);
    await tester.pumpAndSettle();
    expect(find.text('nightly'), findsWidgets);
  });

  test('times read naturally', () {
    final now = DateTime(2026, 10, 21, 12);
    expect(
      flitCronTime(DateTime(2026, 10, 21, 8, 30), now: now),
      'today 08:30',
    );
    expect(flitCronTime(DateTime(2026, 10, 22, 9), now: now), 'tomorrow 09:00');
    expect(
      flitCronTime(DateTime(2026, 10, 26, 10), now: now),
      'Mon 26 Oct 10:00',
    );
  });
}
