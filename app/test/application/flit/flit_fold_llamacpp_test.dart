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

  test('each message keeps the speed of its own call', () {
    final s = foldFlitEvents(const FlitFoldState(), const <FlitEvent>[
      FlitMessageStarted(seq: 1, messageId: 'a', role: FlitRole.assistant),
      FlitUsage(
        seq: 2,
        messageId: 'a',
        inputTokens: 100,
        outputTokens: 10,
        timeToFirstTokenMs: 400,
        promptTokensPerSecond: 250,
        generationTokensPerSecond: 40.5,
        timingSource: 'llama.cpp',
        cachedTokens: 60,
      ),
      FlitMessageStarted(seq: 3, messageId: 'b', role: FlitRole.assistant),
      FlitUsage(
        seq: 4,
        messageId: 'b',
        inputTokens: 200,
        outputTokens: 20,
        generationTokensPerSecond: 12,
        timingSource: 'measured',
      ),
      FlitMessageStarted(seq: 5, messageId: 'c', role: FlitRole.assistant),
      FlitUsage(seq: 6, messageId: 'c', inputTokens: 5, outputTokens: 1),
    ]);
    final a = s.messages[0].usage?.speed;
    expect(a?.generationTokensPerSecond, 40.5);
    expect(a?.promptTokensPerSecond, 250);
    expect(a?.timeToFirstTokenMs, 400);
    expect(a?.cachedTokens, 60);
    expect(a?.inputTokens, 100);
    expect(a?.source, 'llama.cpp');
    expect(s.messages[1].usage?.speed?.generationTokensPerSecond, 12);
    expect(s.messages[1].usage?.speed?.source, 'measured');
    expect(s.messages[2].usage?.speed, isNull, reason: 'no timings reported');
  });
}
