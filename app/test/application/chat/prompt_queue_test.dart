// Gateway 0.20 item #5: interrupt queue semantics.
//
// - A `queued` ack is remembered per LIVE session id.
// - A turn-terminal frame (message.complete OR error) retires the queue as a
//   DRAIN — the gateway ran it, so nothing was lost.
// - dropAll (interrupt) retires it as a DROP, flagging the count once.
// - Queues are per session, and reset on client swap (reconnect).

import 'dart:async';

import 'package:flit/application/chat/prompt_queue.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/prompt_submit_status.dart';
import 'package:flit/domain/models/submit_prompt_result.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake chat repository emitting a canned typed event stream.
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();

  void emit(TypedGatewayEvent event) => _events.add(event);

  /// Mirrors the real impl: events are filtered to one session BEFORE they
  /// reach a subscriber ([TypedGatewayEvent] has no shared session id —
  /// `gateway.ready` carries none).
  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) {
    return _events.stream.where((event) {
      return switch (event) {
        MessageComplete(:final sessionId) => sessionId == liveId,
        TurnError(:final sessionId) => sessionId == liveId,
        _ => false,
      };
    });
  }

  @override
  Future<SubmitPromptResult> submitPrompt(
    String liveId,
    String text, {
    int? truncateBeforeUserOrdinal,
    bool confirmTruncate = false,
    bool confirmEmptyTruncate = false,
  }) async {
    return const SubmitPromptResult(PromptSubmitStatus.queued);
  }

  @override
  Future<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();

  Future<void> dispose() => _events.close();
}

void main() {
  const liveId = 'a1b2c3d4';

  late FakeChatRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeChatRepository();
    container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  PromptQueue read() => container.read(promptQueueProvider(liveId));
  PromptQueueNotifier notifier() =>
      container.read(promptQueueProvider(liveId).notifier);

  test('starts empty and records queued acks in submit order', () {
    expect(read(), const PromptQueue());
    expect(read().isEmpty, isTrue);

    notifier().enqueue('first');
    notifier().enqueue('second');

    expect(read().texts, <String>['first', 'second']);
    expect(read().dropped, 0);
  });

  test('message.complete drains the queue without flagging a drop', () async {
    notifier().enqueue('runs next');

    repository.emit(
      const TypedGatewayEvent.messageComplete(
        sessionId: liveId,
        text: 'done',
        status: MessageTerminalStatus.complete,
      ),
    );
    await pumpEventQueue();

    expect(read().texts, isEmpty);
    expect(read().dropped, 0);
  });

  test('error is the other turn-terminal frame and also drains', () async {
    notifier().enqueue('runs next');

    repository.emit(
      const TypedGatewayEvent.turnError(sessionId: liveId, message: 'boom'),
    );
    await pumpEventQueue();

    expect(read().texts, isEmpty);
    expect(read().dropped, 0);
  });

  test('a terminal frame outside an interrupt bracket is a drain', () async {
    notifier().enqueue('runs next');

    // Status alone does not mean the client asked to stop — an interrupted
    // turn whose interrupt came from elsewhere still drains the queue.
    repository.emit(
      const TypedGatewayEvent.messageComplete(
        sessionId: liveId,
        text: 'stopped',
        status: MessageTerminalStatus.interrupted,
      ),
    );
    await pumpEventQueue();

    expect(read().dropped, 0);
  });

  test('a terminal frame inside the bracket reports the drop', () async {
    notifier().enqueue('lost');
    notifier().beginInterrupt();

    // The interrupted turn's terminal frame beats the interrupt response back.
    repository.emit(
      const TypedGatewayEvent.messageComplete(
        sessionId: liveId,
        text: 'stopped',
        status: MessageTerminalStatus.interrupted,
      ),
    );
    await pumpEventQueue();

    expect(read().texts, isEmpty);
    expect(read().dropped, 1);

    // The response's own dropAll must not double-report.
    notifier().dropAll();
    notifier().endInterrupt();
    expect(read().dropped, 1);
  });

  test('the bracket closes: later terminal frames drain again', () async {
    notifier().beginInterrupt();
    notifier().dropAll();
    notifier().endInterrupt();
    notifier().acknowledgeDropped();

    notifier().enqueue('queued after the stop');
    repository.emit(
      const TypedGatewayEvent.messageComplete(
        sessionId: liveId,
        text: 'next turn',
        status: MessageTerminalStatus.complete,
      ),
    );
    await pumpEventQueue();

    expect(read().texts, isEmpty);
    expect(read().dropped, 0);
  });

  test('dropAll flags the discarded count until acknowledged', () {
    notifier().enqueue('lost one');
    notifier().enqueue('lost two');

    notifier().dropAll();

    expect(read().texts, isEmpty);
    expect(read().dropped, 2);

    notifier().acknowledgeDropped();
    expect(read().dropped, 0);
  });

  test('dropAll on an empty queue reports nothing', () {
    notifier().dropAll();

    expect(read().dropped, 0);
    expect(read().isEmpty, isTrue);
  });

  test('queues are per live session id', () {
    notifier().enqueue('for a1b2c3d4');

    expect(container.read(promptQueueProvider('e5f6a7b8')).texts, isEmpty);
    expect(read().texts, <String>['for a1b2c3d4']);
  });

  test("another session's terminal frame does not drain this queue", () async {
    notifier().enqueue('still queued');

    repository.emit(
      const TypedGatewayEvent.messageComplete(
        sessionId: 'e5f6a7b8',
        text: 'other session',
        status: MessageTerminalStatus.complete,
      ),
    );
    await pumpEventQueue();

    expect(read().texts, <String>['still queued']);
  });

  test('client swap (reconnect) resets the queue', () async {
    final swapped = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(swapped.dispose);

    final listener = swapped.listen(
      promptQueueProvider(liveId),
      (previous, next) {},
    );
    swapped.read(promptQueueProvider(liveId).notifier).enqueue('pre-reconnect');
    expect(listener.read().texts, <String>['pre-reconnect']);

    // A fresh repository stands in for the reconnect's new client: the
    // notifier rebuilds and the remembered queue belongs to the old socket.
    final reconnected = FakeChatRepository();
    addTearDown(reconnected.dispose);
    swapped.updateOverrides([
      chatRepositoryProvider.overrideWithValue(reconnected),
    ]);
    await pumpEventQueue();

    expect(listener.read().texts, isEmpty);
  });

  test('disconnected (null repository) is an inert empty queue', () {
    final disconnected = ProviderContainer();
    addTearDown(disconnected.dispose);

    expect(disconnected.read(promptQueueProvider(liveId)), const PromptQueue());
  });
}
