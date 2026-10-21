import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fileToolsDone counts finished tools that may change files', () {
    var seq = 0;
    int n() => ++seq;
    FlitEvent started(String id, String name) => FlitToolCallStarted(
      seq: n(),
      messageId: 'a1',
      toolCallId: id,
      name: name,
      arguments: '{}',
    );
    FlitEvent done(String id) => FlitToolCallDone(
      seq: n(),
      toolCallId: id,
      result: 'ok',
      isError: false,
      truncated: false,
    );
    final events = <FlitEvent>[
      FlitMessageStarted(seq: n(), messageId: 'a1', role: FlitRole.assistant),
      started('t1', 'read'),
      done('t1'),
      started('t2', 'write'),
      started('t3', 'shell'),
      done('t2'),
      done('t3'),
    ];
    final state = foldFlitEvents(const FlitFoldState(), events);
    expect(state.fileToolsDone, 2);
    // Replaying the same events changes nothing.
    expect(foldFlitEvents(state, events).fileToolsDone, 2);
  });
}
