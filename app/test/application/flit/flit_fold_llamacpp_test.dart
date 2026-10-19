import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waiting reasons, thinking, answer now', () {
    var s = foldFlitEvents(const FlitFoldState(), const <FlitEvent>[
      FlitMessageStarted(seq: 1, messageId: 'a', role: FlitRole.assistant),
      FlitModelCallStarted(seq: 2, messageId: 'a', attempt: 1),
      FlitModelCallWaiting(
        seq: 3,
        messageId: 'a',
        reason: FlitWaitReason.slotsBusy,
        totalSlots: 2,
      ),
    ]);
    expect(s.call?.waitReason, FlitWaitReason.slotsBusy);
    expect(s.call?.totalSlots, 2);

    s = foldFlitEvent(
      s,
      const FlitPromptProgress(seq: 4, messageId: 'a', processed: 0, total: 9),
    );
    expect(s.call?.waitReason, isNull, reason: 'the server started on it');

    s = foldFlitEvent(
      s,
      const FlitReasoningDelta(seq: 5, messageId: 'a', text: 'hmm'),
    );
    expect(s.call?.thinking, isTrue);
    s = foldFlitEvents(s, const <FlitEvent>[
      FlitReasoningEndRequested(seq: 6, messageId: 'a', client: 'phone'),
      FlitReasoningEndIgnored(seq: 7, messageId: 'a'),
    ]);
    expect(s.call?.endRequested, isTrue);
    expect(s.reasoningEndIgnored, <String>{'a'});

    s = foldFlitEvent(
      s,
      const FlitTextDelta(seq: 8, messageId: 'a', text: 'Answer'),
    );
    expect(s.call?.thinking, isFalse);
  });

  test('cache hits reach the speed', () {
    final s = foldFlitEvents(const FlitFoldState(), const <FlitEvent>[
      FlitMessageStarted(seq: 1, messageId: 'a', role: FlitRole.assistant),
      FlitUsage(
        seq: 2,
        messageId: 'a',
        inputTokens: 48000,
        outputTokens: 10,
        timingSource: 'llama.cpp',
        cachedTokens: 40000,
      ),
    ]);
    expect(s.speed?.cachedTokens, 40000);
    expect(s.speed?.inputTokens, 48000);
  });
}
