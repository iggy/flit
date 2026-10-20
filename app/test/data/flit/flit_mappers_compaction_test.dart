import 'package:fixnum/fixnum.dart';
import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit_api/flit_api.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compaction events map to the domain', () {
    final started = eventFromProto(
      pb.Event(
        seq: Int64(5),
        compactionStarted: pb.CompactionStarted(
          compactionId: 'c1',
          auto: true,
          tokens: Int64(3300),
          contextLength: Int64(4096),
          provider: 'local',
          model: 'small',
        ),
      ),
    );
    expect(started, isA<FlitCompactionStarted>());
    started as FlitCompactionStarted;
    expect(started.auto, isTrue);
    expect(started.tokens, 3300);
    expect(started.contextLength, 4096);
    expect(started.model, 'small');

    final done = eventFromProto(
      pb.Event(
        seq: Int64(9),
        compactionDone: pb.CompactionDone(
          compactionId: 'c1',
          summary: 'Goal: x',
          coveredSeq: Int64(4),
          tokensBefore: Int64(3300),
          tokensAfter: Int64(800),
          tokensExact: true,
          keptTurns: 2,
        ),
      ),
    );
    expect(done, isA<FlitCompactionDone>());
    done as FlitCompactionDone;
    expect(done.summary, 'Goal: x');
    expect(done.coveredSeq, 4);
    expect(done.tokensAfter, 800);
    expect(done.tokensExact, isTrue);
    expect(done.keptTurns, 2);
    expect(done.error, isEmpty);
  });
}
