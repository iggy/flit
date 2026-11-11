import 'package:fixnum/fixnum.dart';
import 'package:flit/application/flit/flit_chat_notifier.dart';
import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit_api/flit_api.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the long_turn event maps with its subagent', () {
    final e = eventFromProto(
      pb.Event(
        seq: Int64(7),
        longTurn: pb.LongTurn(steps: 40, subagentToolCallId: 'ag1'),
      ),
    );
    expect(e, isA<FlitLongTurn>());
    final lt = e as FlitLongTurn;
    expect(lt.seq, 7);
    expect(lt.steps, 40);
    expect(lt.subagent, isTrue);
  });

  test('a long turn adds a note to the chat and stops nothing', () {
    final s = foldFlitEvents(const FlitFoldState(), const <FlitEvent>[
      FlitLongTurn(seq: 1, steps: 50),
      FlitLongTurn(seq: 2, steps: 20, subagentToolCallId: 'ag1'),
    ]);
    expect(s.messages, hasLength(2));
    final turn = s.messages.first;
    expect(turn.role, MessageRole.system);
    expect(turn.terminalStatus, MessageTerminalStatus.none);
    expect(turn.text, contains('The agent has made 50 model calls'));
    expect(
      s.messages.last.text,
      contains('A subagent has made 20 model calls'),
    );
    expect(s.lastSeq, 2);
  });

  group('notifyLongTurn', () {
    final now = DateTime.utc(2026, 11, 10, 12);
    FlitLongTurn at(int seq, DateTime? time) =>
        FlitLongTurn(seq: seq, steps: 50, time: time);

    test('notifies for a new, recent event', () {
      expect(notifyLongTurn(at(5, now), 4, now), isTrue);
    });
    test('stays quiet for one already folded', () {
      expect(notifyLongTurn(at(4, now), 4, now), isFalse);
    });
    test('stays quiet when replaying an old log', () {
      final old = now.subtract(const Duration(hours: 1));
      expect(notifyLongTurn(at(5, old), 0, now), isFalse);
      expect(notifyLongTurn(at(5, null), 0, now), isFalse);
    });
  });
}
