import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/flit/flit_drafts.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/application/share/share_providers.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/models/shared_content.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/connect/connect_screen.dart';
import 'package:flit/presentation/flit/flit_nav.dart';
import 'package:flit/presentation/flit/flit_new_session.dart';
import 'package:flit/presentation/flit/flit_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../application/share/fake_share_source.dart';

final class _Repo extends Fake implements FlitRepository {
  final List<String> calls = <String>[];

  static FlitSession _s(String id, String project) => FlitSession(
    id: id,
    title: id,
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
    FlitProject(id: 'research', name: 'Research', directory: '/src/papers'),
  ];

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) async =>
      <FlitSession>[_s('c', 'scratch')];

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
    return _s('new', projectId);
  }
}

/// The connection, set by the test (null until "loaded").
final class _Config extends ConnectionConfigNotifier {
  _Config(this._initial);

  final ConnectionConfig? _initial;

  @override
  ConnectionConfig? build() => _initial;

  void set(ConnectionConfig? config) => state = config;
}

final class _MemoryStore implements KeyValueStore {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

final ConnectionConfig _flit = ConnectionConfig(
  baseUrl: 'https://flit.example.com',
  token: 't',
  backend: BackendKind.flit,
);

const SharedContent _paper = SharedContent(
  text: 'https://arxiv.org/abs/1706.03762',
  subject: 'Attention Is All You Need',
);

const String _draft =
    'Attention Is All You Need\nhttps://arxiv.org/abs/1706.03762';

void main() {
  Future<(_Repo, ProviderContainer, GoRouter)> pump(
    WidgetTester tester, {
    required FakeShareSource source,
    required ConnectionConfig? config,
    required String initialLocation,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    final container = ProviderContainer(
      overrides: [
        shareSourceProvider.overrideWithValue(source),
        connectionConfigProvider.overrideWith(() => _Config(config)),
        flitRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(
          path: '/connect',
          builder: (_, _) => const Scaffold(body: Text('connect')),
        ),
        GoRoute(
          path: '/chat',
          builder: (_, _) => const Scaffold(body: Text('hermes chat')),
        ),
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
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => ShareRouter(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (repo, container, router);
  }

  testWidgets(
    'cold start: the launching share opens New session with it as the '
    "new session's draft, not sent",
    (tester) async {
      final (repo, container, _) = await pump(
        tester,
        source: FakeShareSource(_paper),
        config: null,
        initialLocation: '/connect',
      );
      // The stored connection hasn't loaded yet: the share waits.
      expect(find.text('connect'), findsOneWidget);
      expect(container.read(pendingShareProvider), _paper);

      (container.read(connectionConfigProvider.notifier) as _Config).set(_flit);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AlertDialog, 'New session'), findsOneWidget);
      expect(find.text(_draft), findsOneWidget);
      expect(container.read(pendingShareProvider), isNull);

      // Pick the project: the directory follows it.
      await tester.tap(find.byKey(flitNewSessionProjectKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Research').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '/src/papers'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(repo.calls, <String>['create research /src/papers']);
      expect(find.text('open new'), findsOneWidget);
      expect(container.read(flitDraftStoreProvider).read('new'), _draft);
    },
  );

  testWidgets('warm: a share while in a session opens New session', (
    tester,
  ) async {
    final source = FakeShareSource();
    final (repo, container, _) = await pump(
      tester,
      source: source,
      config: _flit,
      initialLocation: '/flit/session/c',
    );
    expect(find.text('open c'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    source.share(const SharedContent(text: 'https://example.com/post'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'New session'), findsOneWidget);
    expect(find.text('https://example.com/post'), findsOneWidget);

    // Cancelling drops it, and creates nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(find.text('open c'), findsOneWidget);
    expect(container.read(pendingShareProvider), isNull);
  });

  testWidgets('warm, outside the flit screens: goes to them first', (
    tester,
  ) async {
    final source = FakeShareSource();
    final (_, _, router) = await pump(
      tester,
      source: source,
      config: _flit,
      initialLocation: '/connect',
    );
    source.share(_paper);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/flit');
    expect(find.widgetWithText(AlertDialog, 'New session'), findsOneWidget);
  });

  testWidgets('connected to Hermes: says so and drops the share', (
    tester,
  ) async {
    final (repo, container, _) = await pump(
      tester,
      source: FakeShareSource(_paper),
      config: ConnectionConfig(baseUrl: 'http://127.0.0.1:9119'),
      initialLocation: '/chat',
    );
    expect(find.text(shareNeedsFlitMessage), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('hermes chat'), findsOneWidget);
    expect(container.read(pendingShareProvider), isNull);
    expect(repo.calls, isEmpty);
  });

  testWidgets('not connected: the connect screen says the share waits', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        shareSourceProvider.overrideWithValue(FakeShareSource(_paper)),
        connectionStoreProvider.overrideWithValue(
          ConnectionStore(_MemoryStore()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConnectScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(shareWaitingTitle), findsOneWidget);
    expect(find.text(shareWaitingMessage), findsOneWidget);
  });
}
