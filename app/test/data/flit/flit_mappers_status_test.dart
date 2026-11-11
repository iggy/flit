import 'package:fixnum/fixnum.dart';
import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit_api/flit_api.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sessions carry the agent status line', () {
    final s = sessionFromProto(
      pb.Session(id: 's1', status: 'running the tests'),
    );
    expect(s.status, 'running the tests');
    expect(sessionFromProto(pb.Session(id: 's2')).status, isEmpty);
  });

  test('status events are not chat material', () {
    final ev = eventFromProto(
      pb.Event(
        seq: Int64(3),
        statusUpdated: pb.StatusUpdated(text: 'done: fixed'),
      ),
    );
    expect(ev, isA<FlitUnknownEvent>());
    expect(ev.seq, 3);
  });
}
