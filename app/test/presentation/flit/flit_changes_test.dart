import 'dart:async';

import 'package:flit/application/flit/flit_git.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_git.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_changes.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _diff =
    'diff --git a/lib/a.dart b/lib/a.dart\n'
    '--- a/lib/a.dart\n'
    '+++ b/lib/a.dart\n'
    '@@ -1,2 +1,2 @@\n'
    ' keep\n'
    '-old line\n'
    '+new line\n';

final class _Repo extends Fake implements FlitRepository {
  final StreamController<FlitEvent> events = StreamController<FlitEvent>();
  FlitGitStatus status = const FlitGitStatus(
    isRepo: true,
    branch: 'main',
    head: 'abcdef0123',
    upstream: 'origin/main',
    ahead: 2,
    diffBase: 'abcdef0123',
    diffBaseKind: FlitDiffBase.sessionStart,
    files: <FlitGitFile>[
      FlitGitFile(
        path: 'lib/a.dart',
        status: FlitFileStatus.modified,
        additions: 1,
        deletions: 1,
        unstaged: true,
      ),
      FlitGitFile(
        path: 'notes.md',
        status: FlitFileStatus.added,
        additions: 3,
        untracked: true,
      ),
    ],
  );
  bool worktree = false;
  bool removed = false;

  @override
  Future<FlitWorktreeRemoval> removeWorktree(String sessionId) async {
    removed = true;
    return const FlitWorktreeRemoval(
      branch: 'flit/abcd1234',
      branchKept: true,
      commits: 2,
    );
  }

  int statusCalls = 0;
  final List<String> diffPaths = <String>[];

  @override
  Future<FlitSession> getSession(String id) async => FlitSession(
    id: 's1',
    title: 'Session',
    workingDir: worktree ? '/data/worktrees/s1' : '/src/app',
    provider: 'local',
    model: 'qwen',
    state: FlitTaskState.idle,
    lastSeq: 0,
    sourceDir: worktree ? '/src/app' : '',
    worktreePath: worktree ? '/data/worktrees/s1' : '',
    worktreeBranch: worktree ? 'flit/abcd1234' : '',
    worktreeRemoved: removed,
  );

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) =>
      events.stream;

  @override
  Future<FlitGitStatus> gitStatus(String sessionId) async {
    statusCalls++;
    return status;
  }

  @override
  Future<FlitGitDiff> gitDiff(String sessionId, {String path = ''}) async {
    diffPaths.add(path);
    return FlitGitDiff(isRepo: true, text: path == 'lib/a.dart' ? _diff : '');
  }
}

ProviderContainer _container(_Repo repo) {
  final container = ProviderContainer(
    overrides: [
      flitRepositoryProvider.overrideWithValue(repo),
      flitGitRefreshDelayProvider.overrideWithValue(Duration.zero),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repo.events.close);
  return container;
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the header shows branch, file count and ahead/behind', (
    tester,
  ) async {
    final repo = _Repo();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(repo),
        child: const MaterialApp(home: FlitChatScreen(sessionId: 's1')),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('main · 2 files · ↑2'), findsOneWidget);
    expect(repo.statusCalls, 1);

    // A file-changing tool finishing, then the turn ending, refresh it.
    repo.status = const FlitGitStatus(isRepo: true, branch: 'main');
    repo.events
      ..add(
        const FlitTaskStateChanged(
          seq: 1,
          state: FlitTaskState.working,
          reason: '',
        ),
      )
      ..add(
        const FlitMessageStarted(
          seq: 2,
          messageId: 'a1',
          role: FlitRole.assistant,
        ),
      )
      ..add(
        const FlitToolCallStarted(
          seq: 3,
          messageId: 'a1',
          toolCallId: 't1',
          name: 'write',
          arguments: '{"path":"x"}',
        ),
      )
      ..add(
        const FlitToolCallDone(
          seq: 4,
          toolCallId: 't1',
          result: 'ok',
          isError: false,
          truncated: false,
        ),
      );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(repo.statusCalls, 2);
    expect(find.text('main'), findsOneWidget);

    repo.events.add(
      const FlitTaskStateChanged(seq: 5, state: FlitTaskState.done, reason: ''),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(repo.statusCalls, 3);
  });

  testWidgets('a session in its own worktree says so', (tester) async {
    final repo = _Repo()..worktree = true;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(repo),
        child: const MaterialApp(home: FlitChatScreen(sessionId: 's1')),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('/data/worktrees/s1'), findsOneWidget);
    expect(
      find.byTooltip('Own git worktree on flit/abcd1234, from /src/app'),
      findsOneWidget,
    );
  });

  testWidgets('Changes removes the worktree, keeping the branch', (
    tester,
  ) async {
    await _setSize(tester, const Size(400, 800));
    final repo = _Repo()..worktree = true;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(repo),
        child: const MaterialApp(home: FlitChangesScreen(sessionId: 's1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(flitRemoveWorktreeKey));
    await tester.pumpAndSettle();
    expect(find.text('Remove the worktree?'), findsOneWidget);
    await tester.tap(find.byKey(flitRemoveWorktreeConfirmKey));
    await tester.pumpAndSettle();
    expect(repo.removed, isTrue);
    expect(
      find.text('Worktree removed. Branch flit/abcd1234 keeps 2 commits.'),
      findsOneWidget,
    );
    // Once removed, the button goes.
    expect(find.byKey(flitRemoveWorktreeKey), findsNothing);
  });

  testWidgets('no chip outside a repository', (tester) async {
    final repo = _Repo()..status = FlitGitStatus.none;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(repo),
        child: const MaterialApp(home: FlitChatScreen(sessionId: 's1')),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(flitGitChipKey), findsNothing);
  });

  testWidgets('phone width: the list opens a file diff', (tester) async {
    await _setSize(tester, const Size(400, 800));
    final repo = _Repo();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(repo),
        child: const MaterialApp(home: FlitChangesScreen(sessionId: 's1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Since the session started (abcdef0)'),
      findsOneWidget,
    );
    expect(find.text('lib/a.dart'), findsOneWidget);
    expect(find.text('notes.md'), findsOneWidget);
    expect(find.text('untracked'), findsOneWidget);
    expect(repo.diffPaths, isEmpty);

    await tester.tap(find.text('lib/a.dart'));
    await tester.pumpAndSettle();
    expect(repo.diffPaths, <String>['lib/a.dart']);
    expect(find.text('new line'), findsOneWidget);
    expect(find.text('old line'), findsOneWidget);
  });

  testWidgets('wide: list and diff side by side', (tester) async {
    await _setSize(tester, const Size(1200, 800));
    final repo = _Repo();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _container(repo),
        child: const MaterialApp(home: FlitChangesScreen(sessionId: 's1')),
      ),
    );
    await tester.pumpAndSettle();
    // The first file's diff shows right away.
    expect(find.text('new line'), findsOneWidget);
    await tester.tap(find.text('notes.md'));
    await tester.pumpAndSettle();
    expect(repo.diffPaths.last, 'notes.md');
    expect(find.text('No differences.'), findsOneWidget);
  });
}
