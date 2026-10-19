import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flit/presentation/flit/flit_queued_message.dart';
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
    state: FlitTaskState.working,
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
  Future<void> editQueuedMessage(
    String sessionId,
    String queueId,
    String text,
  ) async {
    calls.add('edit $queueId "$text"');
  }

  @override
  Future<void> cancelQueuedMessage(String sessionId, String queueId) async {
    calls.add('cancel $queueId');
  }

  @override
  Future<bool> interrupt(String sessionId) async {
    calls.add('stop');
    return true;
  }
}

void main() {
  testWidgets('send while working, edit and cancel queued messages', (
    tester,
  ) async {
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

    await emit(
      const FlitTaskStateChanged(
        seq: 1,
        state: FlitTaskState.working,
        reason: '',
      ),
    );
    // Working: both Stop and Send are there, and Send queues.
    expect(find.byKey(flitStopKey), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'also this');
    await tester.tap(find.byKey(flitSendKey));
    await tester.pump();
    expect(repo.calls, <String>['send "also this"']);

    await emit(
      const FlitMessageQueued(
        seq: 2,
        queueId: 'q1',
        text: 'also this',
        client: 'phone',
      ),
    );
    expect(find.text('also this'), findsOneWidget);
    expect(
      find.text("Queued · sends at the agent's next step · phone"),
      findsOneWidget,
    );

    await tester.tap(find.byKey(flitQueuedEditKey('q1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'also that');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(flitQueuedCancelKey('q1')));
    await tester.pump();
    expect(repo.calls.skip(1), <String>['edit q1 "also that"', 'cancel q1']);

    // Stopped with something still queued: an empty Send sends the queue.
    await emit(const FlitMessageQueued(seq: 3, queueId: 'q2', text: 'later'));
    await emit(
      const FlitTaskStateChanged(
        seq: 4,
        state: FlitTaskState.done,
        reason: 'interrupted',
      ),
    );
    expect(find.text('Queued · sends with your next message'), findsOneWidget);
    expect(find.byKey(flitStopKey), findsNothing);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byKey(flitSendKey));
    await tester.pump();
    expect(repo.calls.last, 'send ""');

    // Delivered: it becomes an ordinary message.
    await emit(
      const FlitQueuedMessageDelivered(seq: 5, queueId: 'q2', messageId: 'm'),
    );
    expect(find.text('Queued · sends with your next message'), findsNothing);
  });
}
