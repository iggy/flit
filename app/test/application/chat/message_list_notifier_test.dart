// P1-06 acceptance: the thin Riverpod wrapper — events from the chat
// repository fold into state; caller-side mutations (appendUserMessage,
// dismissPrompt) behave. The fold itself is tested pure in
// message_fold_test.dart.

import 'dart:async';

import 'package:flit/application/chat/message_fold.dart';
import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flit/domain/models/prompt_submit_status.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/submit_prompt_result.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake chat repository emitting a canned typed event stream.
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();

  /// The live id turnEvents was subscribed with.
  String? subscribedLiveId;

  void emit(TypedGatewayEvent event) => _events.add(event);

  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) {
    subscribedLiveId = liveId;
    return _events.stream;
  }

  @override
  Future<SubmitPromptResult> submitPrompt(
    String liveId,
    String text, {
    int? truncateBeforeUserOrdinal,
    bool confirmTruncate = false,
    bool confirmEmptyTruncate = false,
  }) async {
    return const SubmitPromptResult(PromptSubmitStatus.streaming);
  }

  @override
  Future<void> respondApproval(String liveId, String choice) async {}

  @override
  Future<void> respondClarify(String requestId, String answer) async {}

  @override
  Future<void> respondSudo(String requestId, String password) async {}

  @override
  Future<void> respondSecret(String requestId, String value) async {}

  @override
  Future<void> respondTerminalRead(String requestId, String text) async {}

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

  test(
    'repository events fold into state for the family arg session',
    () async {
      // Reading the provider builds the notifier and opens the subscription.
      expect(container.read(messageListProvider(liveId)), const FoldState());
      expect(repository.subscribedLiveId, liveId);

      repository.emit(const TypedGatewayEvent.messageStart(sessionId: liveId));
      repository.emit(
        const TypedGatewayEvent.messageDelta(sessionId: liveId, text: 'Hi'),
      );
      await pumpEventQueue();

      final messages = container.read(messageListProvider(liveId)).messages;
      expect(messages, hasLength(1));
      expect(messages.single.role, MessageRole.assistant);
      expect(messages.single.streaming, isTrue);
      expect(messages.single.text, 'Hi');
    },
  );

  test(
    'appendUserMessage appends a user message without touching the fold',
    () async {
      container.read(messageListProvider(liveId));
      repository.emit(const TypedGatewayEvent.messageStart(sessionId: liveId));
      await pumpEventQueue();

      container
          .read(messageListProvider(liveId).notifier)
          .appendUserMessage('do the thing');

      final messages = container.read(messageListProvider(liveId)).messages;
      expect(messages, hasLength(2));
      expect(messages[0].role, MessageRole.assistant);
      expect(messages[0].streaming, isTrue);
      expect(messages[1].role, MessageRole.user);
      expect(messages[1].text, 'do the thing');
    },
  );

  test(
    'dismissPrompt removes the answered prompt from pendingPrompts',
    () async {
      container.read(messageListProvider(liveId));
      repository.emit(
        const TypedGatewayEvent.clarifyRequest(
          sessionId: liveId,
          question: 'Which environment?',
          choices: <String>['staging', 'prod'],
          requestId: '9f3a1c2b',
        ),
      );
      await pumpEventQueue();

      final pending = container
          .read(messageListProvider(liveId))
          .pendingPrompts;
      expect(pending, hasLength(1));
      expect(pending.single, isA<ClarifyPrompt>());

      container
          .read(messageListProvider(liveId).notifier)
          .dismissPrompt(pending.single);

      expect(
        container.read(messageListProvider(liveId)).pendingPrompts,
        isEmpty,
      );
    },
  );

  test('family instances are isolated per live id', () async {
    container.read(messageListProvider('sess-a'));
    container.read(messageListProvider('sess-b'));
    await pumpEventQueue();

    container
        .read(messageListProvider('sess-a').notifier)
        .appendUserMessage('only in A');

    expect(
      container.read(messageListProvider('sess-a')).messages,
      hasLength(1),
    );
    expect(container.read(messageListProvider('sess-b')).messages, isEmpty);
  });

  group('seedHistory inflight reconcile (P2-02)', () {
    test('inflight: null seeds only finalized history', () {
      container.read(messageListProvider(liveId));

      final history = <ChatMessage>[
        const ChatMessage(role: MessageRole.user, text: 'first question'),
        const ChatMessage(role: MessageRole.assistant, text: 'first answer'),
      ];

      container
          .read(messageListProvider(liveId).notifier)
          .seedHistory(history, inflight: null);

      final messages = container.read(messageListProvider(liveId)).messages;
      expect(messages, hasLength(2));
      expect(messages[0].role, MessageRole.user);
      expect(messages[0].text, 'first question');
      expect(messages[1].role, MessageRole.assistant);
      expect(messages[1].text, 'first answer');
      expect(messages[1].streaming, isFalse);
      expect(messages[1].terminalStatus, MessageTerminalStatus.complete);
    });

    test(
      'streaming inflight with user and assistant appends both messages',
      () {
        container.read(messageListProvider(liveId));

        final history = <ChatMessage>[
          const ChatMessage(role: MessageRole.user, text: 'first question'),
          const ChatMessage(role: MessageRole.assistant, text: 'first answer'),
        ];

        final inflight = const InflightTurn(
          user: 'q',
          assistant: 'partial',
          streaming: true,
        );

        container
            .read(messageListProvider(liveId).notifier)
            .seedHistory(history, inflight: inflight);

        final messages = container.read(messageListProvider(liveId)).messages;
        expect(messages, hasLength(4));
        // History messages.
        expect(messages[0].role, MessageRole.user);
        expect(messages[0].text, 'first question');
        expect(messages[1].role, MessageRole.assistant);
        expect(messages[1].text, 'first answer');
        // Inflight user message.
        expect(messages[2].role, MessageRole.user);
        expect(messages[2].text, 'q');
        // Inflight streaming assistant message.
        expect(messages[3].role, MessageRole.assistant);
        expect(messages[3].text, 'partial');
        expect(messages[3].streaming, isTrue);
        expect(messages[3].terminalStatus, MessageTerminalStatus.none);
      },
    );

    test('finished inflight marks assistant complete', () {
      container.read(messageListProvider(liveId));

      final history = <ChatMessage>[
        const ChatMessage(role: MessageRole.user, text: 'first question'),
        const ChatMessage(role: MessageRole.assistant, text: 'first answer'),
      ];

      final inflight = const InflightTurn(
        user: 'q',
        assistant: 'done',
        streaming: false,
      );

      container
          .read(messageListProvider(liveId).notifier)
          .seedHistory(history, inflight: inflight);

      final messages = container.read(messageListProvider(liveId)).messages;
      expect(messages, hasLength(4));
      // Inflight assistant message.
      expect(messages[3].role, MessageRole.assistant);
      expect(messages[3].text, 'done');
      expect(messages[3].streaming, isFalse);
      expect(messages[3].terminalStatus, MessageTerminalStatus.complete);
    });

    test(
      'streaming inflight with empty user appends only assistant bubble',
      () {
        container.read(messageListProvider(liveId));

        final history = <ChatMessage>[
          const ChatMessage(role: MessageRole.user, text: 'first question'),
          const ChatMessage(role: MessageRole.assistant, text: 'first answer'),
        ];

        final inflight = const InflightTurn(
          user: '',
          assistant: '',
          streaming: true,
        );

        container
            .read(messageListProvider(liveId).notifier)
            .seedHistory(history, inflight: inflight);

        final messages = container.read(messageListProvider(liveId)).messages;
        expect(messages, hasLength(3));
        // History messages.
        expect(messages[0].role, MessageRole.user);
        expect(messages[1].role, MessageRole.assistant);
        // Only the streaming assistant bubble is appended.
        expect(messages[2].role, MessageRole.assistant);
        expect(messages[2].text, isEmpty);
        expect(messages[2].streaming, isTrue);
        expect(messages[2].terminalStatus, MessageTerminalStatus.none);
      },
    );
  });
}
