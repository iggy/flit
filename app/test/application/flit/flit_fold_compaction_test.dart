import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// A message's three events from seq on.
List<FlitEvent> message(int seq, String id, FlitRole role, String text) =>
    <FlitEvent>[
      FlitMessageStarted(seq: seq, messageId: id, role: role),
      FlitTextDelta(seq: seq + 1, messageId: id, text: text),
      FlitMessageDone(
        seq: seq + 2,
        messageId: id,
        text: text,
        reasoning: '',
        finishReason: 'stop',
      ),
    ];

/// Two turns: u1 a1 (seq 1-6), u2 a2 (seq 7-12).
List<FlitEvent> twoTurns() => <FlitEvent>[
  ...message(1, 'u1', FlitRole.user, 'one'),
  ...message(4, 'a1', FlitRole.assistant, '1'),
  ...message(7, 'u2', FlitRole.user, 'two'),
  ...message(10, 'a2', FlitRole.assistant, '2'),
];

void main() {
  test('compacting shows while it runs; done adds a marker at the cut', () {
    var s = foldFlitEvents(const FlitFoldState(), twoTurns());
    s = foldFlitEvent(
      s,
      const FlitCompactionStarted(
        seq: 13,
        compactionId: 'c1',
        auto: true,
        tokens: 3300,
        contextLength: 4096,
        model: 'small',
      ),
    );
    expect(s.compacting?.compactionId, 'c1');
    expect(s.compacting?.auto, isTrue);
    expect(s.compactions, isEmpty);

    s = foldFlitEvent(
      s,
      const FlitCompactionDone(
        seq: 14,
        compactionId: 'c1',
        auto: true,
        summary: 'Goal: count.',
        coveredSeq: 6,
        tokensBefore: 3300,
        tokensAfter: 900,
      ),
    );
    expect(s.compacting, isNull);
    expect(s.compactions, hasLength(1));
    final marker = s.compactions.single;
    expect(marker.beforeIndex, 2); // before u2
    expect(marker.summary, 'Goal: count.');
    // The first turn is greyed out; the kept turn isn't.
    expect(
      <bool>[for (var i = 0; i < s.messages.length; i++) s.summarized(i)],
      <bool>[true, true, false, false],
    );
    expect(s.contextTokens, 900);
    // Messages are all still there.
    expect(s.messages.map((m) => m.text), <String>['one', '1', 'two', '2']);

    // Replaying is idempotent.
    expect(foldFlitEvents(s, twoTurns()), s);
  });

  test('a cut inside a turn keeps its request un-greyed', () {
    var s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      ...twoTurns(),
      ...message(13, 'a2b', FlitRole.assistant, '2b'),
    ]);
    s = foldFlitEvent(
      s,
      const FlitCompactionDone(
        seq: 16,
        compactionId: 'c1',
        summary: 'S',
        coveredSeq: 12,
      ),
    );
    expect(s.compactions.single.beforeIndex, 4);
    expect(s.keptIndex, 2);
    expect(
      <bool>[for (var i = 0; i < s.messages.length; i++) s.summarized(i)],
      <bool>[true, true, false, true, false],
    );
  });

  test('everything covered: the marker goes at the end', () {
    var s = foldFlitEvents(const FlitFoldState(), twoTurns());
    s = foldFlitEvent(
      s,
      const FlitCompactionDone(
        seq: 13,
        compactionId: 'c1',
        summary: 'S',
        coveredSeq: 12,
      ),
    );
    expect(s.compactions.single.beforeIndex, 4);
    expect(s.summarized(3), isTrue);
  });

  test('a failed compaction is a note in the chat, not a marker', () {
    var s = foldFlitEvents(const FlitFoldState(), twoTurns());
    s = foldFlitEvent(
      s,
      const FlitCompactionStarted(seq: 13, compactionId: 'c1'),
    );
    s = foldFlitEvent(
      s,
      const FlitCompactionDone(
        seq: 14,
        compactionId: 'c1',
        error: 'the model wrote no summary',
      ),
    );
    expect(s.compacting, isNull);
    expect(s.compactions, isEmpty);
    expect(s.messages.last.role, MessageRole.system);
    expect(s.messages.last.text, contains('the model wrote no summary'));
    expect(s.summarized(0), isFalse);
  });

  test('the turn ending clears an unfinished compaction', () {
    var s = foldFlitEvent(
      const FlitFoldState(),
      const FlitCompactionStarted(seq: 1, compactionId: 'c1'),
    );
    s = foldFlitEvent(
      s,
      const FlitTaskStateChanged(seq: 2, state: FlitTaskState.done, reason: ''),
    );
    expect(s.compacting, isNull);
  });
}
