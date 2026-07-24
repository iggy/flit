// P1-10 acceptance: the session list providers + drawer actions.
//
// - sessionListProvider / activeSessionListProvider fetch history (durable
//   ids) and live sessions; active_list is called WITH the current live id
//   (protocol §9: "current" is client-side); null repo → empty lists.
// - SessionActions.newSession calls session.create and switches with BOTH
//   ids.
// - SessionActions.switchToSummary on a durable-only session calls resume
//   with the durable id, switches to the NEW live id, and seeds the
//   replayed history into messageListProvider(newLiveId); a still-live
//   session is switched to by its live id WITHOUT a resume.
// - SessionActions.interruptActive interrupts the active live id.
// - Nothing throws: failures come back as message strings.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/chat/message_list_notifier.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/application/sessions/active_session.dart';
import 'package:hermes/application/sessions/session_list.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/dto/events/gateway_event_parser.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/chat_message.dart';
import 'package:hermes/domain/models/session_bootstrap.dart';
import 'package:hermes/domain/models/session_summary.dart';
import 'package:hermes/domain/repositories/chat_repository.dart';
import 'package:hermes/domain/repositories/session_repository.dart';

/// Hand-rolled fake (established pattern — see active_session_test.dart).
final class FakeSessionRepository implements SessionRepository {
  int createCalls = 0;
  Exception? createError;
  SessionCreateResult createResult = const SessionCreateResult(
    liveId: 'a1b2c3d4',
    durableId: 'durable-1',
  );

  int listCalls = 0;
  Exception? listError;
  List<SessionSummary> listResult = const <SessionSummary>[];

  final List<String?> activeListArgs = <String?>[];
  List<ActiveSession> activeListResult = const <ActiveSession>[];

  final List<String> resumed = <String>[];
  Exception? resumeError;
  SessionResumeResult resumeResult = const SessionResumeResult(
    liveId: 'e5f6a7b8',
    durableId: 'durable-9',
    messages: <ChatMessage>[
      ChatMessage(role: MessageRole.user, text: 'hello?'),
      ChatMessage(role: MessageRole.assistant, text: 'hi there'),
    ],
    messageCount: 2,
    running: false,
    status: SessionStatus.idle,
  );

  final List<String> interrupted = <String>[];

  @override
  Future<SessionCreateResult> create({
    String? profile,
    String? cwd,
    String? model,
  }) async {
    createCalls++;
    final error = createError;
    if (error != null) {
      throw error;
    }
    return createResult;
  }

  @override
  Future<List<SessionSummary>> list() async {
    listCalls++;
    final error = listError;
    if (error != null) {
      throw error;
    }
    return listResult;
  }

  @override
  Future<List<ActiveSession>> activeList({String? currentLiveId}) async {
    activeListArgs.add(currentLiveId);
    return activeListResult;
  }

  @override
  Future<SessionResumeResult> resume(String durableId) async {
    resumed.add(durableId);
    final error = resumeError;
    if (error != null) {
      throw error;
    }
    return resumeResult;
  }

  @override
  Future<void> interrupt(String liveId) async {
    interrupted.add(liveId);
  }
}

/// Fake chat repository with a controllable typed event stream (same
/// pattern as message_list_notifier_test.dart) — used to pre-populate a
/// message list that seedHistory must REPLACE.
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();

  void emit(TypedGatewayEvent event) => _events.add(event);

  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) => _events.stream;

  @override
  Future<void> submitPrompt(String liveId, String text) async {}

  @override
  Future<void> respondApproval(String liveId, String choice) async {}

  @override
  Future<void> respondClarify(String requestId, String answer) async {}

  Future<void> dispose() => _events.close();
}

void main() {
  late FakeSessionRepository repository;
  late FakeChatRepository chatRepository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSessionRepository();
    chatRepository = FakeChatRepository();
    container = ProviderContainer(
      // Deterministic tests: Riverpod 3 retries failing providers by
      // default (backoff), which would leave error assertions pending.
      retry: (retryCount, error) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await chatRepository.dispose();
  });

  SessionActions readActions() => container.read(sessionActionsProvider);
  ActiveSessionState readActive() => container.read(activeSessionProvider);

  test('sessionListProvider returns the repository history', () async {
    repository.listResult = const <SessionSummary>[
      SessionSummary(
        durableId: 'durable-1',
        title: 'Fix the parser',
        preview: 'last message…',
        messageCount: 12,
      ),
    ];

    final list = await container.read(sessionListProvider.future);

    expect(list, repository.listResult);
    expect(repository.listCalls, 1);
  });

  test('sessionListProvider surfaces a repository error', () async {
    repository.listError = const GatewayNetworkException('host unreachable');

    await expectLater(
      container.read(sessionListProvider.future),
      throwsA(isA<GatewayNetworkException>()),
    );
  });

  test(
    'activeSessionListProvider is called WITH the current live id',
    () async {
      repository.activeListResult = const <ActiveSession>[
        ActiveSession(liveId: 'live-1', status: SessionStatus.working),
      ];
      container
          .read(activeSessionProvider.notifier)
          .switchTo(liveId: 'live-1', durableId: 'durable-1');

      final live = await container.read(activeSessionListProvider.future);

      expect(live, repository.activeListResult);
      expect(repository.activeListArgs, <String?>['live-1']);
    },
  );

  test('newSession calls create and switches with BOTH ids', () async {
    final error = await readActions().newSession();

    expect(error, isNull);
    expect(repository.createCalls, 1);
    final active = readActive();
    expect(active.liveId, 'a1b2c3d4');
    expect(active.durableId, 'durable-1');
  });

  test('newSession failure returns a message and does not switch', () async {
    repository.createError = const GatewayNetworkException('host unreachable');

    final error = await readActions().newSession();

    expect(error, 'host unreachable');
    expect(readActive(), const ActiveSessionState());
  });

  test('switchToSummary on a durable-only session resumes with the durable '
      'id, switches to the NEW live id, and seeds the history', () async {
    const newLiveId = 'e5f6a7b8';
    // Pre-existing state for the new live id: a streaming message and a
    // pending prompt — seedHistory must REPLACE both.
    container.read(messageListProvider(newLiveId));
    chatRepository.emit(
      const TypedGatewayEvent.messageStart(sessionId: newLiveId),
    );
    chatRepository.emit(
      const TypedGatewayEvent.clarifyRequest(
        sessionId: newLiveId,
        question: 'Which environment?',
        choices: <String>['staging'],
        requestId: 'req-1',
      ),
    );
    await pumpEventQueue();
    final before = container.read(messageListProvider(newLiveId));
    expect(before.messages.single.streaming, isTrue);
    expect(before.pendingPrompts, hasLength(1));

    final error = await readActions().switchToSummary(
      const SessionSummary(
        durableId: 'durable-9',
        title: 'Old chat',
        preview: '',
        messageCount: 2,
      ),
    );

    expect(error, isNull);
    // Resume with the DURABLE id (protocol §9), switch to the NEW live id.
    expect(repository.resumed, <String>['durable-9']);
    final active = readActive();
    expect(active.liveId, newLiveId);
    expect(active.durableId, 'durable-9');

    // The replayed history is seeded: terminal, non-streaming, prompts
    // cleared.
    final fold = container.read(messageListProvider(newLiveId));
    expect(fold.messages, hasLength(2));
    expect(fold.messages[0].role, MessageRole.user);
    expect(fold.messages[0].text, 'hello?');
    expect(fold.messages[0].streaming, isFalse);
    expect(fold.messages[1].role, MessageRole.assistant);
    expect(fold.messages[1].text, 'hi there');
    expect(fold.messages[1].streaming, isFalse);
    expect(fold.messages[1].terminalStatus, MessageTerminalStatus.complete);
    expect(fold.pendingPrompts, isEmpty);
  });

  test(
    'switchToSummary resume failure returns a message and does not switch',
    () async {
      repository.resumeError = const GatewayRpcException(-32000, 'gone');

      final error = await readActions().switchToSummary(
        const SessionSummary(
          durableId: 'durable-9',
          title: 'Old chat',
          preview: '',
          messageCount: 2,
        ),
      );

      expect(error, 'gone');
      expect(readActive(), const ActiveSessionState());
    },
  );

  test('switchToSummary on the current session does not resume', () async {
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: 'live-1', durableId: 'durable-1');

    final error = await readActions().switchToSummary(
      const SessionSummary(
        durableId: 'durable-1',
        title: 'Current',
        preview: '',
        messageCount: 1,
      ),
    );

    expect(error, isNull);
    expect(repository.resumed, isEmpty);
    expect(readActive().liveId, 'live-1');
  });

  test(
    'switchToSummary reuses the live id of a session still in active_list',
    () async {
      // Session 1 becomes current and lands in the client-side id map…
      await readActions().newSession(); // a1b2c3d4 / durable-1
      // …then session 2 takes over as current.
      repository.createResult = const SessionCreateResult(
        liveId: 'b2c3d4e5',
        durableId: 'durable-2',
      );
      await readActions().newSession();
      expect(readActive().liveId, 'b2c3d4e5');

      // The gateway still reports session 1 as live; the drawer always has
      // the active list loaded, so populate .value the same way.
      repository.activeListResult = const <ActiveSession>[
        ActiveSession(liveId: 'a1b2c3d4', status: SessionStatus.idle),
        ActiveSession(liveId: 'b2c3d4e5', status: SessionStatus.idle),
      ];
      await container.read(activeSessionListProvider.future);

      final error = await readActions().switchToSummary(
        const SessionSummary(
          durableId: 'durable-1',
          title: 'One',
          preview: '',
          messageCount: 3,
        ),
      );

      expect(error, isNull);
      expect(repository.resumed, isEmpty); // NO resume — still live.
      final active = readActive();
      expect(active.liveId, 'a1b2c3d4');
      expect(active.durableId, 'durable-1');
    },
  );

  test('switchToSummary falls back to resume when the mapped session is no '
      'longer live', () async {
    await readActions().newSession(); // durable-1 → a1b2c3d4
    repository.createResult = const SessionCreateResult(
      liveId: 'b2c3d4e5',
      durableId: 'durable-2',
    );
    await readActions().newSession();

    // a1b2c3d4 is gone from the gateway's active list (stale mapping).
    repository.activeListResult = const <ActiveSession>[
      ActiveSession(liveId: 'b2c3d4e5', status: SessionStatus.idle),
    ];
    await container.read(activeSessionListProvider.future);

    final error = await readActions().switchToSummary(
      const SessionSummary(
        durableId: 'durable-1',
        title: 'One',
        preview: '',
        messageCount: 3,
      ),
    );

    expect(error, isNull);
    expect(repository.resumed, <String>['durable-1']);
    expect(readActive().liveId, 'e5f6a7b8'); // resume's NEW live id
  });

  test('switchToLive switches by live id without a resume', () {
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: 'live-1', durableId: 'durable-1');

    readActions().switchToLive(
      const ActiveSession(liveId: 'live-2', status: SessionStatus.idle),
    );

    expect(repository.resumed, isEmpty);
    expect(readActive().liveId, 'live-2');
  });

  test('interruptActive interrupts the active live id', () async {
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: 'live-1', durableId: 'durable-1');

    final error = await readActions().interruptActive();

    expect(error, isNull);
    expect(repository.interrupted, <String>['live-1']);
  });

  test('interruptActive with no active session is a no-op', () async {
    final error = await readActions().interruptActive();

    expect(error, isNull);
    expect(repository.interrupted, isEmpty);
  });

  test('disconnected: lists are empty and actions report it', () async {
    final disconnected = ProviderContainer();
    addTearDown(disconnected.dispose);

    expect(await disconnected.read(sessionListProvider.future), isEmpty);
    expect(await disconnected.read(activeSessionListProvider.future), isEmpty);

    final actions = disconnected.read(sessionActionsProvider);
    expect(await actions.newSession(), contains('Not connected'));
    expect(
      await actions.switchToSummary(
        const SessionSummary(
          durableId: 'durable-1',
          title: 'One',
          preview: '',
          messageCount: 1,
        ),
      ),
      contains('Not connected'),
    );
    expect(await actions.interruptActive(), isNull); // nothing to interrupt
  });
}
