import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_branch_controls.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  final StreamController<FlitEvent> events = StreamController<FlitEvent>();
  final List<String> calls = <String>[];

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
      events.stream;

  @override
  Future<List<FlitSkill>> listSkills(String sessionId) async =>
      const <FlitSkill>[];

  @override
  Future<List<FlitModel>> listModels() async => const <FlitModel>[];

  @override
  Future<void> retryFromMessage(
    String sessionId,
    String messageId, {
    String client = '',
  }) async {
    calls.add('retry $messageId');
  }

  @override
  Future<void> editMessage(
    String sessionId,
    String messageId,
    String text, {
    String client = '',
  }) async {
    calls.add('edit $messageId "$text"');
  }

  @override
  Future<void> switchBranch(
    String sessionId,
    String branchId, {
    String client = '',
  }) async {
    calls.add('switch "$branchId"');
  }
}

List<FlitEvent> _message(
  int seq,
  String id,
  String text,
  FlitRole role, {
  String branch = '',
}) => <FlitEvent>[
  FlitMessageStarted(seq: seq, messageId: id, role: role, branchId: branch),
  FlitMessageDone(
    seq: seq + 1,
    messageId: id,
    text: text,
    reasoning: '',
    finishReason: 'stop',
    branchId: branch,
  ),
];

void main() {
  for (final size in <Size>[const Size(375, 812), const Size(1280, 800)]) {
    testWidgets('retry, edit and switch branches at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _Repo();
      addTearDown(repo.events.close);
      final container = ProviderContainer(
        overrides: [flitRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FlitChatScreen(sessionId: 's1')),
        ),
      );
      Future<void> emit(List<FlitEvent> es) async {
        es.forEach(repo.events.add);
        await tester.pump();
        await tester.pump();
      }

      await emit(<FlitEvent>[
        ..._message(1, 'u1', 'question', FlitRole.user),
        ..._message(3, 'a1', 'first answer', FlitRole.assistant),
        const FlitTaskStateChanged(
          seq: 5,
          state: FlitTaskState.done,
          reason: '',
        ),
      ]);
      // No fork yet: no switch, but the user message can be retried.
      expect(find.byType(FlitBranchSwitcher), findsNothing);
      await tester.tap(find.byKey(flitRetryFromKey));
      await tester.pump();
      expect(repo.calls, <String>['retry u1']);

      await emit(<FlitEvent>[
        const FlitBranchCreated(
          seq: 6,
          newBranchId: 'b1',
          parentBranchId: '',
          forkSeq: 2,
          kind: FlitBranchKind.retry,
          messageId: 'u1',
        ),
        const FlitBranchSwitched(seq: 7, newBranchId: 'b1', branchId: 'b1'),
        const FlitTaskStateChanged(
          seq: 8,
          state: FlitTaskState.working,
          reason: '',
        ),
        ..._message(9, 'a2', 'second answer', FlitRole.assistant, branch: 'b1'),
      ]);
      expect(find.text('second answer'), findsOneWidget);
      expect(find.text('first answer'), findsNothing);
      expect(find.text('2 / 2'), findsOneWidget);
      // While the turn runs: no switching, no forking.
      expect(find.byKey(flitRetryFromKey), findsNothing);
      final prev = tester.widget<IconButton>(find.byKey(flitBranchPrevKey));
      expect(prev.onPressed, isNull);

      await emit(<FlitEvent>[
        const FlitTaskStateChanged(
          seq: 11,
          state: FlitTaskState.done,
          reason: '',
          branchId: 'b1',
        ),
      ]);
      await tester.tap(find.byKey(flitBranchPrevKey));
      await tester.pump();
      expect(repo.calls.last, 'switch ""');

      // The server records the switch; every client shows the root again.
      await emit(<FlitEvent>[
        const FlitBranchSwitched(seq: 12, newBranchId: ''),
      ]);
      expect(find.text('first answer'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      // Edit and resend.
      await tester.tap(find.byKey(flitEditMessageKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'better question');
      await tester.tap(find.byKey(flitEditSendKey));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'edit u1 "better question"');
      expect(tester.takeException(), isNull);
    });
  }
}
