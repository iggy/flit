import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_mcp_sheet.dart';
import 'package:flit/presentation/flit/flit_projects.dart';
import 'package:flit/presentation/flit/flit_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  final List<String> calls = <String>[];
  final Map<String, bool> mcp = <String, bool>{'fs': true, 'web': false};

  @override
  Future<List<FlitProject>> listProjects() async => const <FlitProject>[
    FlitProject(id: 'scratch', name: 'Scratch', sessionCount: 2),
    FlitProject(id: 'p1', name: 'app', directory: '/src/app', sessionCount: 1),
  ];

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) async {
    calls.add('list:$projectId');
    return const <FlitSession>[];
  }

  @override
  Future<FlitProject> createProject({
    required String directory,
    String name = '',
  }) async {
    calls.add('create:$directory:$name');
    return FlitProject(
      id: 'p2',
      name: name.isEmpty ? 'new' : name,
      directory: directory,
    );
  }

  @override
  Future<List<FlitMcpServer>> listMcpServers(String sessionId) async =>
      <FlitMcpServer>[
        for (final e in mcp.entries)
          FlitMcpServer(
            name: e.key,
            enabled: e.value,
            running: e.value,
            toolCount: e.value ? 3 : 0,
          ),
      ];

  @override
  Future<FlitSession> setMcpServer(
    String sessionId,
    String server, {
    required bool enabled,
  }) async {
    calls.add('mcp:$server:$enabled');
    mcp[server] = enabled;
    return const FlitSession(
      id: 's',
      title: '',
      workingDir: '/',
      provider: '',
      model: '',
      state: FlitTaskState.idle,
      lastSeq: 0,
    );
  }
}

void main() {
  late _Repo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _Repo();
    container = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Widget app(Widget child) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: child),
        body: const SizedBox(),
      ),
    ),
  );

  testWidgets('project switcher filters sessions and creates projects', (
    tester,
  ) async {
    container.listen(flitSessionsProvider, (_, _) {});
    await tester.pumpWidget(app(const FlitProjectSwitcher()));
    await tester.pumpAndSettle();
    expect(find.text('All projects'), findsOneWidget);

    await tester.tap(find.text('All projects'));
    await tester.pumpAndSettle();
    expect(find.text('/src/app · 1 sessions'), findsOneWidget);
    await tester.tap(find.text('app'));
    await tester.pumpAndSettle();
    expect(container.read(flitSelectedProjectProvider), 'p1');
    expect(repo.calls, contains('list:p1'));

    await tester.tap(find.text('app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New project…'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Directory on the server'),
      '/src/new',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Name (optional)'),
      'fresh',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('create:/src/new:fresh'));
    expect(container.read(flitSelectedProjectProvider), 'p2');
  });

  testWidgets('MCP sheet toggles servers', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFlitMcpSheet(context, 's'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('3 tools'), findsOneWidget);
    expect(find.text('not started yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'web'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('mcp:web:true'));
  });

  testWidgets('rating buttons', (tester) async {
    bool? rated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitRatingButtons(rating: null, onRate: (g) => rated = g),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Bad'));
    expect(rated, isFalse);
    await tester.tap(find.byTooltip('Good'));
    expect(rated, isTrue);
  });
}
