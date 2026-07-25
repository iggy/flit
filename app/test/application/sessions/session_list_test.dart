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

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // Phase 2 mutation action support
  final List<({String liveId, String title})> renamed = <({String liveId, String title})>[];
  String setTitleResult = 'Updated Title';
  Exception? setTitleError;

  final List<String> deleted = <String>[];
  Exception? deleteError;

  final List<String> saved = <String>[];
  String saveResult = '/tmp/session-export.json';
  Exception? saveError;

  final List<({String liveId, String? name})> branched = <({String liveId, String? name})>[];
  BranchResult branchResult = const BranchResult(
    liveId: 'c9d0e1f2',
    title: 'branch',
    parentDurableId: 'durable-9',
  );
  Exception? branchError;

  final List<({String liveId, String? focusTopic})> compressed = <({String liveId, String? focusTopic})>[];
  CompressResult compressResult = const CompressResult(
    status: 'compressed',
    removed: 5,
    beforeMessages: 20,
    afterMessages: 15,
  );
  Exception? compressError;

  final List<String> undone = <String>[];
  int undoResult = 2;
  Exception? undoError;

  final List<({String liveId, String cwd})> cwdSet = <({String liveId, String cwd})>[];
  Exception? setCwdError;

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

  @override
  Future<MostRecentSession?> mostRecent({String? profile}) =>
      throw UnimplementedError();

  @override
  Future<String> setTitle(String liveId, String title) async {
    renamed.add((liveId: liveId, title: title));
    final error = setTitleError;
    if (error != null) {
      throw error;
    }
    return setTitleResult;
  }

  @override
  Future<void> delete(String durableId, {String? profile}) async {
    deleted.add(durableId);
    final error = deleteError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<SessionUsageStats> usage(String liveId) => throw UnimplementedError();

  @override
  Future<ContextBreakdown> contextBreakdown(String liveId) =>
      throw UnimplementedError();

  @override
  Future<CompressResult> compress(String liveId, {String? focusTopic}) async {
    compressed.add((liveId: liveId, focusTopic: focusTopic));
    final error = compressError;
    if (error != null) {
      throw error;
    }
    return compressResult;
  }

  @override
  Future<int> undo(String liveId) async {
    undone.add(liveId);
    final error = undoError;
    if (error != null) {
      throw error;
    }
    return undoResult;
  }

  @override
  Future<String> save(String liveId) async {
    saved.add(liveId);
    final error = saveError;
    if (error != null) {
      throw error;
    }
    return saveResult;
  }

  @override
  Future<BranchResult> branch(String liveId, {String? name}) async {
    branched.add((liveId: liveId, name: name));
    final error = branchError;
    if (error != null) {
      throw error;
    }
    return branchResult;
  }

  @override
  Future<void> setCwd(String liveId, String cwd) async {
    cwdSet.add((liveId: liveId, cwd: cwd));
    final error = setCwdError;
    if (error != null) {
      throw error;
    }
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
  late StreamController<GatewayEvent> gatewayEvents;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSessionRepository();
    chatRepository = FakeChatRepository();
    gatewayEvents = StreamController<GatewayEvent>.broadcast();
    container = ProviderContainer(
      // Deterministic tests: Riverpod 3 retries failing providers by
      // default (backoff), which would leave error assertions pending.
      retry: (retryCount, error) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
        gatewayEventsProvider.overrideWith(
          (ref) => gatewayEvents.stream,
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await chatRepository.dispose();
    await gatewayEvents.close();
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

  test('activeSessionListProvider re-fetches on session.info event (P2-10)',
      () async {
    repository.activeListResult = const <ActiveSession>[
      ActiveSession(liveId: 'live-1', status: SessionStatus.idle),
    ];
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: 'live-1', durableId: 'durable-1');

    // Initial fetch.
    await container.read(activeSessionListProvider.future);
    expect(repository.activeListArgs, hasLength(1));

    // Keep the provider subscribed (listening) so invalidation triggers a rebuild.
    final listener = container.listen(
      activeSessionListProvider,
      (previous, next) {},
    );

    // Emit a session.info event.
    gatewayEvents.add(const GatewayEvent(
      type: 'session.info',
      sessionId: 'live-1',
      payload: <String, Object?>{'info': <String, Object?>{}},
    ));
    await pumpEventQueue();

    // The provider should have invalidated and re-fetched (call count increased).
    expect(repository.activeListArgs.length, 2);

    listener.close();
  });

  group('mutation actions (P2-03/04/06/07/08)', () {
    test('rename calls setTitle with liveId+title and returns null', () async {
      final error = await readActions().rename('live-1', 'New Title');

      expect(error, isNull);
      expect(repository.renamed, <({String liveId, String title})>[
        (liveId: 'live-1', title: 'New Title'),
      ]);
    });

    test('rename returns error message on GatewayException', () async {
      repository.setTitleError = const GatewayRpcException(-32000, 'bad title');

      final error = await readActions().rename('live-1', 'Bad');

      expect(error, 'bad title');
    });

    test('deleteSession calls delete with DURABLE id and returns null',
        () async {
      final error = await readActions().deleteSession('durable-1');

      expect(error, isNull);
      expect(repository.deleted, <String>['durable-1']);
    });

    test('deleteSession returns error message on GatewayException', () async {
      repository.deleteError = const GatewayRpcException(-32000, 'still active');

      final error = await readActions().deleteSession('durable-1');

      expect(error, 'still active');
    });

    test('save calls save(liveId) and returns null', () async {
      final error = await readActions().save('live-1');

      expect(error, isNull);
      expect(repository.saved, <String>['live-1']);
    });

    test('save returns error message on GatewayException', () async {
      repository.saveError = const GatewayRpcException(-32000, 'disk full');

      final error = await readActions().save('live-1');

      expect(error, 'disk full');
    });

    test('branchSession calls branch and switches to new liveId', () async {
      final error = await readActions().branchSession('live-1', name: 'fork');

      expect(error, isNull);
      expect(repository.branched, <({String liveId, String? name})>[
        (liveId: 'live-1', name: 'fork'),
      ]);
      final active = readActive();
      expect(active.liveId, 'c9d0e1f2'); // branchResult.liveId
    });

    test('branchSession returns error message on GatewayException', () async {
      repository.branchError = const GatewayRpcException(-32000, 'no parent');

      final error = await readActions().branchSession('live-1');

      expect(error, 'no parent');
      expect(readActive().liveId, isNull); // not switched
    });

    test(
      'compress with lockHeld=true returns the lock message',
      () async {
        repository.compressResult = const CompressResult(
          lockHeld: true,
          message: 'busy',
        );

        final error = await readActions().compress('live-1');

        expect(error, 'busy');
        expect(repository.compressed, <({String liveId, String? focusTopic})>[
          (liveId: 'live-1', focusTopic: null),
        ]);
      },
    );

    test('compress with lockHeld=true and no message returns default',
        () async {
      repository.compressResult = const CompressResult(lockHeld: true);

      final error = await readActions().compress('live-1');

      expect(error, 'Compression is already in progress.');
    });

    test('compress with normal result returns null', () async {
      repository.compressResult = const CompressResult(
        status: 'compressed',
        removed: 5,
      );

      final error = await readActions().compress('live-1', focusTopic: 'auth');

      expect(error, isNull);
      expect(repository.compressed, <({String liveId, String? focusTopic})>[
        (liveId: 'live-1', focusTopic: 'auth'),
      ]);
    });

    test('compress returns error message on GatewayException', () async {
      repository.compressError = const GatewayRpcException(-32000, 'no context');

      final error = await readActions().compress('live-1');

      expect(error, 'no context');
    });

    test('undo calls undo(liveId) and returns null', () async {
      final error = await readActions().undo('live-1');

      expect(error, isNull);
      expect(repository.undone, <String>['live-1']);
    });

    test('undo returns error message on GatewayException', () async {
      repository.undoError = const GatewayRpcException(-32000, 'empty history');

      final error = await readActions().undo('live-1');

      expect(error, 'empty history');
    });

    test('setCwd calls setCwd(liveId, cwd) and returns null', () async {
      final error = await readActions().setCwd('live-1', '/tmp/workspace');

      expect(error, isNull);
      expect(repository.cwdSet, <({String liveId, String cwd})>[
        (liveId: 'live-1', cwd: '/tmp/workspace'),
      ]);
    });

    test('setCwd returns error message on GatewayException', () async {
      repository.setCwdError = const GatewayRpcException(-32000, 'invalid path');

      final error = await readActions().setCwd('live-1', '/bad/path');

      expect(error, 'invalid path');
    });

    test('mutation actions when disconnected return not-connected message',
        () async {
      final disconnected = ProviderContainer();
      addTearDown(disconnected.dispose);
      final actions = disconnected.read(sessionActionsProvider);

      expect(await actions.rename('live-1', 'Title'), contains('Not connected'));
      expect(await actions.deleteSession('durable-1'), contains('Not connected'));
      expect(await actions.save('live-1'), contains('Not connected'));
      expect(await actions.branchSession('live-1'), contains('Not connected'));
      expect(await actions.compress('live-1'), contains('Not connected'));
      expect(await actions.undo('live-1'), contains('Not connected'));
      expect(await actions.setCwd('live-1', '/tmp'), contains('Not connected'));
    });
  });
}
