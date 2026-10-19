import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 18, 17);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  test('tracks the model call in progress from the log', () {
    var s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitTaskStateChanged(
        seq: 1,
        state: FlitTaskState.working,
        reason: '',
      ),
      const FlitMessageStarted(
        seq: 2,
        messageId: 'a1',
        role: FlitRole.assistant,
      ),
      FlitModelCallStarted(seq: 3, messageId: 'a1', attempt: 1, time: at(0)),
      FlitPromptProgress(
        seq: 4,
        messageId: 'a1',
        processed: 1000,
        total: 48000,
        time: at(5),
      ),
    ]);
    expect(
      s.call,
      FlitPendingCall(
        messageId: 'a1',
        attempt: 1,
        startedAt: at(0),
        lastActivity: at(5),
        processed: 1000,
        total: 48000,
      ),
    );

    // A stall and an automatic retry: a new attempt replaces the old.
    s = foldFlitEvents(s, <FlitEvent>[
      const FlitModelCallEnded(
        seq: 5,
        messageId: 'a1',
        attempt: 1,
        outcome: FlitCallOutcome.stalled,
        phase: 'processing_prompt',
        willRetry: true,
      ),
      FlitModelCallStarted(seq: 6, messageId: 'a1', attempt: 2, time: at(130)),
    ]);
    expect(s.call?.attempt, 2);
    expect(s.call?.processed, 0);
    expect(s.call?.startedAt, at(130));

    s = foldFlitEvent(
      s,
      FlitTextDelta(seq: 7, messageId: 'a1', text: 'Hi', time: at(140)),
    );
    expect(s.call?.hasOutput, isTrue);
    expect(s.call?.lastActivity, at(140));

    s = foldFlitEvent(
      s,
      const FlitModelCallEnded(
        seq: 8,
        messageId: 'a1',
        attempt: 2,
        outcome: FlitCallOutcome.ok,
      ),
    );
    expect(s.call, isNull);
  });

  test('the end of a turn clears a call that never ended', () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitModelCallStarted(seq: 1, messageId: 'a1', attempt: 1),
      const FlitTaskStateChanged(
        seq: 2,
        state: FlitTaskState.stuck,
        reason: 'flit restarted during the turn',
      ),
    ]);
    expect(s.call, isNull);
  });

  test("other messages' events don't touch the call", () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitModelCallStarted(seq: 1, messageId: 'a2', attempt: 1),
      const FlitPromptProgress(
        seq: 2,
        messageId: 'a1',
        processed: 5,
        total: 10,
      ),
      const FlitModelCallEnded(
        seq: 3,
        messageId: 'a1',
        attempt: 1,
        outcome: FlitCallOutcome.ok,
      ),
    ]);
    expect(s.call?.messageId, 'a2');
    expect(s.call?.total, 0);
  });
}
