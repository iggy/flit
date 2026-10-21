import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_learning.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flit/presentation/flit/flit_learn_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const FlitLearnProposal _memory = FlitLearnProposal(
  id: 'p1',
  sessionId: 's1',
  action: FlitLearnAction.add,
  target: FlitLearnTarget.project,
  status: FlitLearnStatus.pending,
  evidence: 'T2',
  newText: '- **When testing:** run python3 -m unittest.',
  path: '/data/memory/projects/proj.md',
);

const FlitLearnProposal _skill = FlitLearnProposal(
  id: 'p2',
  sessionId: 's1',
  action: FlitLearnAction.update,
  target: FlitLearnTarget.skill,
  status: FlitLearnStatus.pending,
  skill: 'deploy',
  oldText: 'old skill',
  newText: 'new skill',
  path: '/repo/.agents/skills/deploy/SKILL.md',
);

final class _Repo extends Fake implements FlitRepository {
  _Repo(this.proposals);

  final List<FlitLearnProposal> proposals;
  final List<String> calls = <String>[];
  Completer<void>? gate;

  @override
  Future<FlitLearnResult> learn(String sessionId) async {
    calls.add('learn $sessionId');
    await gate?.future;
    return FlitLearnResult(proposals: proposals, model: 'qwen');
  }

  @override
  Future<FlitLearnProposal> acceptLearnProposal(
    String id, {
    String? text,
  }) async {
    calls.add('accept $id ${text ?? '(as proposed)'}');
    final p = proposals.firstWhere((p) => p.id == id);
    return FlitLearnProposal(
      id: id,
      sessionId: p.sessionId,
      action: p.action,
      target: p.target,
      status: FlitLearnStatus.accepted,
      newText: text ?? p.newText,
      path: p.path,
    );
  }

  @override
  Future<FlitLearnProposal> rejectLearnProposal(String id) async {
    calls.add('reject $id');
    final p = proposals.firstWhere((p) => p.id == id);
    return FlitLearnProposal(
      id: id,
      sessionId: p.sessionId,
      action: p.action,
      target: p.target,
      status: FlitLearnStatus.rejected,
    );
  }

  @override
  Future<FlitSession> getSession(String id) async => const FlitSession(
    id: 's1',
    title: 'T',
    workingDir: '/src',
    provider: 'p',
    model: 'm',
    state: FlitTaskState.done,
    lastSeq: 0,
  );

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) =>
      const Stream<FlitEvent>.empty();
}

Future<void> _pumpSheet(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [flitRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(body: FlitLearnSheet(sessionId: 's1')),
      ),
    ),
  );
}

void main() {
  testWidgets('runs the pass and accepts, edits and rejects', (tester) async {
    final repo = _Repo(<FlitLearnProposal>[_memory, _skill])
      ..gate = Completer<void>();
    await _pumpSheet(tester, repo);
    await tester.pump();
    expect(find.byKey(flitLearnRunningKey), findsOneWidget);
    repo.gate!.complete();
    await tester.pumpAndSettle();

    expect(repo.calls, <String>['learn s1']);
    expect(find.text('Add to project memory'), findsOneWidget);
    expect(find.text('Change in skill deploy'), findsOneWidget);
    expect(find.text('old skill'), findsOneWidget);
    expect(find.text('From T2'), findsOneWidget);

    // Edit the memory entry, then save it.
    await tester.tap(find.byKey(const Key('${flitLearnEditKeyPrefix}p1')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('${flitLearnTextKeyPrefix}p1')),
      '- run unittest',
    );
    await tester.tap(find.byKey(const Key('${flitLearnAcceptKeyPrefix}p1')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('${flitLearnRejectKeyPrefix}p2')),
    );
    await tester.tap(find.byKey(const Key('${flitLearnRejectKeyPrefix}p2')));
    await tester.pumpAndSettle();

    expect(repo.calls, <String>[
      'learn s1',
      'accept p1 - run unittest',
      'reject p2',
    ]);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(
      find.byKey(const Key('${flitLearnAcceptKeyPrefix}p1')),
      findsNothing,
    );
  });

  testWidgets('says so when there is nothing to keep', (tester) async {
    await _pumpSheet(tester, _Repo(<FlitLearnProposal>[]));
    await tester.pumpAndSettle();
    expect(find.byKey(flitLearnEmptyKey), findsOneWidget);
  });

  test('/learn is the command, with nothing after it', () {
    expect(flitIsLearnCommand('/learn'), isTrue);
    expect(flitIsLearnCommand('  /learn  '), isTrue);
    expect(flitIsLearnCommand('/learn more'), isFalse);
    expect(flitIsLearnCommand('/learning'), isFalse);
  });

  testWidgets('/learn in the composer opens the sheet', (tester) async {
    final repo = _Repo(<FlitLearnProposal>[_memory]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [flitRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: FlitChatScreen(sessionId: 's1')),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '/learn');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.calls, <String>['learn s1']);
    expect(find.text('Learn from this session'), findsOneWidget);
  });
}
