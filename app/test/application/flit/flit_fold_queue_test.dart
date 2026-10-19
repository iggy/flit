import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('queued messages: added, edited, cancelled, delivered', () {
    var s = foldFlitEvents(const FlitFoldState(), const <FlitEvent>[
      FlitMessageQueued(seq: 1, queueId: 'q1', text: 'one', client: 'phone'),
      FlitMessageQueued(seq: 2, queueId: 'q2', text: 'two'),
      FlitMessageQueued(seq: 3, queueId: 'q3', text: 'three'),
      FlitQueuedMessageUpdated(seq: 4, queueId: 'q2', text: 'two, fixed'),
      FlitQueuedMessageUpdated(seq: 5, queueId: 'q3', cancelled: true),
    ]);
    expect(s.queued, const <FlitQueuedMessage>[
      FlitQueuedMessage(queueId: 'q1', text: 'one', client: 'phone'),
      FlitQueuedMessage(queueId: 'q2', text: 'two, fixed'),
    ]);

    s = foldFlitEvents(s, const <FlitEvent>[
      FlitQueuedMessageDelivered(seq: 6, queueId: 'q1', messageId: 'm1'),
      FlitMessageStarted(seq: 7, messageId: 'm1', role: FlitRole.user),
      FlitTextDelta(seq: 8, messageId: 'm1', text: 'one'),
      FlitMessageDone(
        seq: 9,
        messageId: 'm1',
        text: 'one',
        reasoning: '',
        finishReason: 'stop',
      ),
    ]);
    expect(s.queued.map((q) => q.queueId), <String>['q2']);
    expect(s.messages.last.text, 'one');

    // Replaying from the start gives the same queue (every client agrees).
    final replay = foldFlitEvents(const FlitFoldState(), const <FlitEvent>[
      FlitMessageQueued(seq: 1, queueId: 'q1', text: 'one', client: 'phone'),
      FlitMessageQueued(seq: 2, queueId: 'q2', text: 'two'),
      FlitMessageQueued(seq: 3, queueId: 'q3', text: 'three'),
      FlitQueuedMessageUpdated(seq: 4, queueId: 'q2', text: 'two, fixed'),
      FlitQueuedMessageUpdated(seq: 5, queueId: 'q3', cancelled: true),
      FlitQueuedMessageDelivered(seq: 6, queueId: 'q1', messageId: 'm1'),
    ]);
    expect(replay.queued, s.queued);
  });
}
