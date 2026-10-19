import 'dart:async';

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_call_status.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  final StreamController<FlitEvent> events = StreamController<FlitEvent>();
  final List<String> calls = <String>[];
  bool canEnd = true;

  @override
  Future<FlitSession> getSession(String id) async => const FlitSession(
    id: 's1',
    title: 'T',
    workingDir: '/src',
    provider: 'llama',
    model: 'qwen',
    state: FlitTaskState.working,
    lastSeq: 0,
  );

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) =>
      events.stream;

  @override
  Future<List<FlitModel>> listModels() async => <FlitModel>[
    FlitModel(provider: 'llama', id: 'qwen', canEndReasoning: canEnd),
  ];

  @override
  Future<void> endReasoning(String sessionId, {String client = ''}) async {
    calls.add('end');
  }
}

void main() {
  testWidgets('waiting strip says why', (tester) async {
    final t0 = DateTime.utc(2026);
    Future<void> pump(FlitPendingCall call) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitCallStatus(
            call: call,
            now: () => t0.add(const Duration(seconds: 42)),
            onRetry: () {},
            onStop: () {},
          ),
        ),
      ),
    );
    await pump(
      FlitPendingCall(
        messageId: 'a',
        attempt: 1,
        startedAt: t0,
        lastActivity: t0.add(const Duration(seconds: 40)),
        waitReason: FlitWaitReason.slotsBusy,
        totalSlots: 2,
      ),
    );
    expect(
      find.text('Waiting for a free llama.cpp slot (all 2 busy) · 0:42'),
      findsOneWidget,
    );
    await pump(
      FlitPendingCall(
        messageId: 'a',
        attempt: 1,
        startedAt: t0,
        lastActivity: t0.add(const Duration(seconds: 40)),
        waitReason: FlitWaitReason.sleeping,
      ),
    );
    expect(find.text('Waking the model up · 0:42'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('status strip shows cache hits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitStatusStrip(
            provider: 'llama',
            model: 'qwen',
            effort: '',
            contextTokens: 48000,
            contextLength: 64000,
            state: FlitTaskState.idle,
            onModelTap: () {},
            inputTokens: 48000,
            cachedTokens: 40000,
          ),
        ),
      ),
    );
    expect(find.text('40k/48k cached'), findsOneWidget);
  });

  for (final canEnd in <bool>[true, false]) {
    testWidgets('answer now while thinking (supported: $canEnd)', (
      tester,
    ) async {
      final repo = _Repo()..canEnd = canEnd;
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

      for (final e in const <FlitEvent>[
        FlitTaskStateChanged(seq: 1, state: FlitTaskState.working, reason: ''),
        FlitMessageStarted(seq: 2, messageId: 'a', role: FlitRole.assistant),
        FlitModelCallStarted(seq: 3, messageId: 'a', attempt: 1),
      ]) {
        await emit(e);
      }
      expect(find.byKey(flitAnswerNowKey), findsNothing);
      await emit(const FlitReasoningDelta(seq: 4, messageId: 'a', text: 'hmm'));
      if (!canEnd) {
        expect(find.byKey(flitAnswerNowKey), findsNothing);
        await tester.pumpWidget(const SizedBox());
        return;
      }
      expect(find.byKey(flitAnswerNowKey), findsOneWidget);
      await tester.tap(find.byKey(flitAnswerNowKey));
      await tester.pump();
      expect(repo.calls, <String>['end']);
      await emit(const FlitReasoningEndRequested(seq: 5, messageId: 'a'));
      expect(find.byKey(flitAnswerNowKey), findsNothing);
      await emit(const FlitReasoningEndIgnored(seq: 6, messageId: 'a'));
      await tester.pump();
      expect(find.textContaining("can't be cut short"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
