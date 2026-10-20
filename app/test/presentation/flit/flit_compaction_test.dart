import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/chat/message_bubble.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flit/presentation/flit/flit_compaction.dart';
import 'package:flit/presentation/flit/flit_slash_menu.dart';
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
  Future<void> send(String sessionId, String text, {String client = ''}) async {
    calls.add('send "$text"');
  }

  @override
  Future<bool> compact(
    String sessionId, {
    String instructions = '',
    String client = '',
  }) async {
    calls.add('compact "$instructions"');
    return false;
  }
}

List<FlitEvent> message(int seq, String id, FlitRole role, String text) =>
    <FlitEvent>[
      FlitMessageStarted(seq: seq, messageId: id, role: role),
      FlitMessageDone(
        seq: seq + 1,
        messageId: id,
        text: text,
        reasoning: '',
        finishReason: 'stop',
      ),
    ];

double opacityOf(WidgetTester tester, String text) {
  final opacity = tester.widget<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
  );
  return opacity.opacity;
}

void main() {
  testWidgets('/compact, compacting, then a marker with the older messages '
      'greyed out', (tester) async {
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
    Future<void> emit(FlitEvent e) async {
      repo.events.add(e);
      await tester.pump();
      await tester.pump();
    }

    for (final e in <FlitEvent>[
      ...message(1, 'u1', FlitRole.user, 'old question'),
      ...message(3, 'a1', FlitRole.assistant, 'old answer'),
      ...message(5, 'u2', FlitRole.user, 'new question'),
      ...message(7, 'a2', FlitRole.assistant, 'new answer'),
    ]) {
      await emit(e);
    }
    expect(find.byType(MessageBubble), findsNWidgets(4));

    // The slash menu offers /compact; sending it calls Compact, not Send.
    await tester.enterText(find.byType(TextField), '/comp');
    await tester.pump();
    expect(find.byKey(const Key('${flitSlashItemKeyPrefix}compact')), findsOne);
    await tester.enterText(find.byType(TextField), '/compact keep the API');
    await tester.tap(find.byKey(flitSendKey));
    await tester.pump();
    expect(repo.calls, <String>['compact "keep the API"']);

    await emit(
      const FlitTaskStateChanged(
        seq: 9,
        state: FlitTaskState.working,
        reason: 'compacting',
      ),
    );
    await emit(
      const FlitCompactionStarted(seq: 10, compactionId: 'c1', model: 'small'),
    );
    expect(find.byKey(flitCompactingKey), findsOneWidget);
    expect(find.text('Compacting the conversation…'), findsOneWidget);

    await emit(
      const FlitCompactionDone(
        seq: 11,
        compactionId: 'c1',
        summary: 'Goal: answer questions.',
        coveredSeq: 4,
        tokensBefore: 3300,
        tokensAfter: 900,
        model: 'small',
      ),
    );
    await emit(
      const FlitTaskStateChanged(
        seq: 12,
        state: FlitTaskState.done,
        reason: '',
      ),
    );
    expect(find.byKey(flitCompactingKey), findsNothing);
    final marker = find.byKey(const Key('${flitCompactionMarkerKeyPrefix}c1'));
    expect(marker, findsOneWidget);
    expect(
      find.text('Conversation compacted · ~3.3k → ~900 tokens'),
      findsOneWidget,
    );
    // The marker sits between the summarized and the kept turn.
    final markerY = tester.getTopLeft(marker).dy;
    expect(tester.getTopLeft(find.text('old answer')).dy, lessThan(markerY));
    expect(
      tester.getTopLeft(find.text('new question')).dy,
      greaterThan(markerY),
    );
    expect(opacityOf(tester, 'old question'), flitSummarizedOpacity);
    expect(opacityOf(tester, 'new question'), 1);

    // The summary expands.
    expect(find.text('Goal: answer questions.'), findsNothing);
    await tester.tap(marker);
    await tester.pump();
    expect(find.text('Goal: answer questions.'), findsOneWidget);
  });

  test('/compact instructions', () {
    expect(flitCompactInstructions('/compact'), '');
    expect(
      flitCompactInstructions(' /compact  keep it short '),
      'keep it short',
    );
    expect(flitCompactInstructions('/compactor'), isNull);
    expect(flitCompactInstructions('please /compact'), isNull);
  });
}
