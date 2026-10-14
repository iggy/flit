import 'dart:async';

import 'package:flit/application/flit/flit_chat_notifier.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server log the fake replays from any seq, like flit does.
final class FakeFlitRepository extends Fake implements FlitRepository {
  final List<FlitEvent> log = <FlitEvent>[];
  final List<int> attachedFrom = <int>[];
  final List<StreamController<FlitEvent>> streams =
      <StreamController<FlitEvent>>[];
  final List<String> answers = <String>[];

  /// Appends to the log and pushes to every live stream.
  void emit(FlitEvent event) {
    log.add(event);
    for (final s in streams) {
      if (!s.isClosed) {
        s.add(event);
      }
    }
  }

  /// Drops every live stream, like a network failure.
  Future<void> dropAll() async {
    for (final s in streams) {
      if (!s.isClosed) {
        s.addError(const GatewayNetworkException('connection reset'));
        await s.close();
      }
    }
  }

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) {
    attachedFrom.add(fromSeq);
    final controller = StreamController<FlitEvent>();
    // Replay, then go live. Deliberately overlap by one event to prove the
    // client ignores what it already has.
    for (final e in log.where((e) => e.seq >= fromSeq - 1)) {
      controller.add(e);
    }
    streams.add(controller);
    return controller.stream;
  }

  @override
  Future<void> answerPrompt(
    String sessionId,
    String promptId, {
    required bool allow,
    bool forSession = false,
    String client = '',
  }) async {
    answers.add('$promptId:$allow:$client${forSession ? ':session' : ''}');
    emit(
      FlitPromptResolved(
        seq: log.length + 1,
        promptId: promptId,
        allowed: allow,
        client: client,
        reason: '',
      ),
    );
  }

  @override
  Future<bool> interrupt(String sessionId) async => true;

  @override
  Future<void> send(String sessionId, String text) async {}
}

FlitEvent delta(int seq, String text) =>
    FlitTextDelta(seq: seq, messageId: 'a', text: text);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeFlitRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeFlitRepository();
    container = ProviderContainer(
      overrides: [
        flitRepositoryProvider.overrideWithValue(repo),
        flitDeviceNameProvider.overrideWithValue('test-phone'),
        flitReconnectDelayProvider.overrideWithValue((_) => Duration.zero),
      ],
    );
    addTearDown(container.dispose);
  });

  FlitChatState read() => container.read(flitChatProvider('s'));

  test(
    'replays, follows live, and resumes after a drop without duplicates',
    () async {
      repo
        ..emit(
          const FlitMessageStarted(
            seq: 1,
            messageId: 'a',
            role: FlitRole.assistant,
          ),
        )
        ..emit(delta(2, 'one '));
      final sub = container.listen(flitChatProvider('s'), (_, _) {});
      addTearDown(sub.close);
      await settle();
      expect(repo.attachedFrom, <int>[1]);
      expect(read().fold.messages.single.text, 'one ');
      expect(read().link, FlitLink.live);

      repo.emit(delta(3, 'two '));
      await settle();
      expect(read().fold.messages.single.text, 'one two ');

      // The connection drops; meanwhile the server logs more.
      await repo.dropAll();
      repo.emit(delta(4, 'three'));
      await settle();

      // Reattached from lastSeq + 1 = 4, despite the fake replaying 3 again.
      expect(repo.attachedFrom, <int>[1, 4]);
      expect(read().fold.messages.single.text, 'one two three');
      expect(read().fold.lastSeq, 4);
      expect(read().link, FlitLink.live);
    },
  );

  test('answering a prompt removes it via the server log', () async {
    repo.emit(
      const FlitPromptRequested(
        seq: 1,
        promptId: 'p1',
        toolCallId: 't',
        title: 'Run shell command',
        detail: 'make',
      ),
    );
    final sub = container.listen(flitChatProvider('s'), (_, _) {});
    addTearDown(sub.close);
    await settle();
    expect(read().fold.prompts.single.promptId, 'p1');

    final error = await container
        .read(flitChatProvider('s').notifier)
        .answer('p1', allow: true);
    expect(error, isNull);
    await settle();
    expect(repo.answers, <String>['p1:true:test-phone']);
    expect(read().fold.prompts, isEmpty);
  });

  test('offline without a flit connection', () {
    final offline = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(null)],
    );
    addTearDown(offline.dispose);
    expect(offline.read(flitChatProvider('s')).link, FlitLink.offline);
  });
}
