// P5-03 acceptance: ProcessesScreen widget test — renders process rows,
// status chips, kill button, exec console.

import 'package:flit/application/processes/process_providers.dart';
import 'package:flit/domain/models/background_process.dart';
import 'package:flit/domain/repositories/process_repository.dart';
import 'package:flit/presentation/settings/processes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only fake process repository.
final class FakeProcessRepository implements ProcessRepository {
  FakeProcessRepository({
    this.listResult = const <BackgroundProcess>[],
    this.killResult = const ProcessKillResult(status: 'killed'),
    this.stopAllResult = 0,
    this.execResult = const ShellExecResult(stdout: '', stderr: '', code: 0),
  });

  final List<BackgroundProcess> listResult;
  final ProcessKillResult killResult;
  final int stopAllResult;
  final ShellExecResult execResult;

  final List<String> killedProcessIds = <String>[];
  final List<String> execCommands = <String>[];
  int stopAllCallCount = 0;

  @override
  Future<List<BackgroundProcess>> list({String? sessionId}) async {
    return listResult;
  }

  @override
  Future<ProcessKillResult> kill(String processId, {String? sessionId}) async {
    killedProcessIds.add(processId);
    return killResult;
  }

  @override
  Future<int> stopAll() async {
    stopAllCallCount++;
    return stopAllResult;
  }

  @override
  Future<ShellExecResult> exec(String command) async {
    execCommands.add(command);
    return execResult;
  }
}

void main() {
  group('ProcessesScreen', () {
    testWidgets('renders empty state when no processes', (tester) async {
      final repository = FakeProcessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No background processes'), findsOneWidget);
    });

    testWidgets('renders process row with command and status', (tester) async {
      final processes = <BackgroundProcess>[
        const BackgroundProcess(
          processId: 'proc_123',
          command: 'npm run dev',
          status: 'running',
          pid: 1234,
          uptimeSeconds: 3600,
        ),
      ];
      final repository = FakeProcessRepository(listResult: processes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('npm run dev'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('PID: 1234'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);
    });

    testWidgets('renders exited status chip differently', (tester) async {
      final processes = <BackgroundProcess>[
        const BackgroundProcess(
          processId: 'proc_456',
          command: 'test script',
          status: 'exited',
          exitCode: 0,
        ),
      ];
      final repository = FakeProcessRepository(listResult: processes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('test script'), findsOneWidget);
      expect(find.text('exited'), findsOneWidget);
    });

    testWidgets('kill button calls controller.kill', (tester) async {
      final processes = <BackgroundProcess>[
        const BackgroundProcess(
          processId: 'proc_123',
          command: 'npm run dev',
          status: 'running',
        ),
      ];
      final repository = FakeProcessRepository(listResult: processes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final killButton = find.byIcon(Icons.close);
      await tester.tap(killButton.first);
      await tester.pumpAndSettle();

      expect(repository.killedProcessIds, <String>['proc_123']);
    });

    testWidgets('stop all button calls controller.stopAll', (tester) async {
      final processes = <BackgroundProcess>[
        const BackgroundProcess(
          processId: 'proc_123',
          command: 'npm run dev',
          status: 'running',
        ),
      ];
      final repository = FakeProcessRepository(listResult: processes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final stopAllButton = find.byIcon(Icons.stop);
      await tester.tap(stopAllButton);
      await tester.pumpAndSettle();

      expect(repository.stopAllCallCount, 1);
    });

    testWidgets('exec console run button calls controller.exec', (
      tester,
    ) async {
      final repository = FakeProcessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final commandField = find.byType(TextField);
      await tester.enterText(commandField, 'echo test');
      await tester.pumpAndSettle();

      final runButton = find.text('Run');
      await tester.tap(runButton);
      await tester.pumpAndSettle();

      expect(repository.execCommands, <String>['echo test']);
    });

    testWidgets('exec console shows result after exec', (tester) async {
      final repository = FakeProcessRepository(
        execResult: const ShellExecResult(
          stdout: 'Hello World',
          stderr: '',
          code: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final commandField = find.byType(TextField);
      await tester.enterText(commandField, 'echo test');
      await tester.pumpAndSettle();

      final runButton = find.text('Run');
      await tester.tap(runButton);
      await tester.pumpAndSettle();

      expect(find.text('Exit code: 0'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('expandable output tail displays when expanded', (
      tester,
    ) async {
      final processes = <BackgroundProcess>[
        const BackgroundProcess(
          processId: 'proc_123',
          command: 'npm run dev',
          status: 'running',
          outputTail: 'Server started on port 3000\nListening...',
        ),
      ];
      final repository = FakeProcessRepository(listResult: processes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Output tail should not be visible initially
      expect(
        find.text('Server started on port 3000\nListening...'),
        findsNothing,
      );

      // Tap to expand
      final expansionTile = find.byType(ExpansionTile);
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();

      // Output tail should now be visible
      expect(
        find.text('Server started on port 3000\nListening...'),
        findsOneWidget,
      );
    });

    testWidgets('renders process list successfully', (tester) async {
      final processes = <BackgroundProcess>[
        const BackgroundProcess(
          processId: 'proc_1',
          command: 'cmd1',
          status: 'running',
        ),
        const BackgroundProcess(
          processId: 'proc_2',
          command: 'cmd2',
          status: 'exited',
        ),
      ];
      final repository = FakeProcessRepository(listResult: processes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cmd1'), findsOneWidget);
      expect(find.text('cmd2'), findsOneWidget);
    });

    testWidgets('disconnected state shows empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [processRepositoryProvider.overrideWithValue(null)],
          child: const MaterialApp(home: ProcessesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No background processes'), findsOneWidget);
    });
  });
}
