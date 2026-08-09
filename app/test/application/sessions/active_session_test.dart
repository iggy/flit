// P1-09 acceptance: the active-session notifier — bootstrap creates a
// session and records both ids (protocol §9); failures land in state.error
// (never throw) and retry works; switchTo/clear behave.
//
// P1-16 acceptance: rebind (reconnect path, protocol §10) resumes the
// durable session, switches to the NEW live id, and seeds the replayed
// history; a resume failure falls back to a fresh create; the old session
// stays visible while the resume is in flight.

import 'dart:async';

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_overrides.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake (established pattern — see
/// test/application/chat/message_list_notifier_test.dart).
final class FakeSessionRepository implements SessionRepository {
  int createCalls = 0;
  Exception? createError;
  SessionCreateResult createResult = const SessionCreateResult(
    liveId: 'a1b2c3d4',
    durableId: '2026-uuid',
  );

  final List<String> resumed = <String>[];
  Exception? resumeError;

  /// When set, resume blocks on this completer (in-flight assertions).
  Completer<SessionResumeResult>? resumeGate;
  SessionResumeResult resumeResult = const SessionResumeResult(
    liveId: 'e5f6a7b8',
    durableId: '2026-uuid',
    messages: <ChatMessage>[
      ChatMessage(role: MessageRole.user, text: 'before the drop'),
      ChatMessage(role: MessageRole.assistant, text: 'still here'),
    ],
    messageCount: 2,
    running: false,
    status: SessionStatus.idle,
  );

  /// Per-session overrides of the LAST create call (contract v4).
  ({String? model, String? provider, String? reasoningEffort, bool? fast})?
  createOverrides;

  @override
  Future<SessionCreateResult> create({
    String? profile,
    String? cwd,
    String? model,
    String? provider,
    String? reasoningEffort,
    bool? fast,
    String? parentSessionId,
    String? source,
  }) async {
    createCalls++;
    createOverrides = (
      model: model,
      provider: provider,
      reasoningEffort: reasoningEffort,
      fast: fast,
    );
    final error = createError;
    if (error != null) {
      throw error;
    }
    return createResult;
  }

  @override
  Future<List<SessionSummary>> list() => throw UnimplementedError();

  @override
  Future<List<ActiveSession>> activeList({String? currentLiveId}) =>
      throw UnimplementedError();

  @override
  Future<SessionResumeResult> resume(String durableId) {
    resumed.add(durableId);
    final gate = resumeGate;
    if (gate != null) {
      return gate.future;
    }
    final error = resumeError;
    if (error != null) {
      return Future<SessionResumeResult>.error(error);
    }
    return Future<SessionResumeResult>.value(resumeResult);
  }

  @override
  Future<void> interrupt(String liveId) => throw UnimplementedError();

  @override
  Future<MostRecentSession?> mostRecent({String? profile}) =>
      throw UnimplementedError();

  @override
  Future<String> setTitle(String liveId, String title) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String durableId, {String? profile}) =>
      throw UnimplementedError();

  @override
  Future<SessionUsageStats> usage(String liveId) => throw UnimplementedError();

  @override
  Future<ContextBreakdown> contextBreakdown(String liveId) =>
      throw UnimplementedError();

  @override
  Future<CompressResult> compress(String liveId, {String? focusTopic}) =>
      throw UnimplementedError();

  @override
  Future<int> undo(String liveId) => throw UnimplementedError();

  @override
  Future<String> save(String liveId) => throw UnimplementedError();

  @override
  Future<BranchResult> branch(String liveId, {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> setCwd(String liveId, String cwd) => throw UnimplementedError();

  @override
  Future<SteerOutcome> steer(String liveId, String text) async {
    return SteerOutcome.queued;
  }
}

void main() {
  late FakeSessionRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSessionRepository();
    container = ProviderContainer(
      overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  ActiveSessionState readState() => container.read(activeSessionProvider);
  ActiveSessionNotifier readNotifier() =>
      container.read(activeSessionProvider.notifier);

  test('starts empty', () {
    expect(readState(), const ActiveSessionState());
  });

  test('bootstrap creates a session and records live + durable ids', () async {
    await readNotifier().bootstrap();

    final state = readState();
    expect(state.liveId, 'a1b2c3d4');
    expect(state.durableId, '2026-uuid');
    expect(state.bootstrapping, isFalse);
    expect(state.error, isNull);
    expect(repository.createCalls, 1);
  });

  test('bootstrap inherits the profile when nothing is picked yet', () async {
    await readNotifier().bootstrap();

    // Nothing sent = inherit the profile (contract v4).
    expect(repository.createOverrides, (
      model: null,
      provider: null,
      reasoningEffort: null,
      fast: null,
    ));
  });

  test('bootstrap carries the sticky model/effort/fast picks', () async {
    final picked = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
        sessionCreateOverridesProvider.overrideWithValue(
          const SessionOverrides(
            model: 'hermes-4-70b',
            provider: 'nous',
            reasoningEffort: 'high',
            fast: false,
          ),
        ),
      ],
    );
    addTearDown(picked.dispose);

    await picked.read(activeSessionProvider.notifier).bootstrap();

    expect(repository.createOverrides, (
      model: 'hermes-4-70b',
      provider: 'nous',
      reasoningEffort: 'high',
      // Explicitly pinned to normal — NOT the same as omitting it.
      fast: false,
    ));
  });

  test('bootstrap is idempotent once a session is active', () async {
    await readNotifier().bootstrap();
    await readNotifier().bootstrap();

    expect(repository.createCalls, 1);
  });

  test('bootstrap failure sets state.error and never throws', () async {
    repository.createError = const GatewayNetworkException('host unreachable');

    await expectLater(readNotifier().bootstrap(), completes);

    final state = readState();
    expect(state.liveId, isNull);
    expect(state.bootstrapping, isFalse);
    expect(state.error, 'host unreachable');
  });

  test('retry after a failure bootstraps successfully', () async {
    repository.createError = const GatewayNetworkException('host unreachable');
    await readNotifier().bootstrap();
    expect(readState().error, isNotNull);

    repository.createError = null;
    await readNotifier().bootstrap();

    final state = readState();
    expect(state.error, isNull);
    expect(state.liveId, 'a1b2c3d4');
    expect(repository.createCalls, 2);
  });

  test(
    'bootstrap without a repository (disconnected) reports an error',
    () async {
      final disconnected = ProviderContainer();
      addTearDown(disconnected.dispose);

      await disconnected.read(activeSessionProvider.notifier).bootstrap();

      final state = disconnected.read(activeSessionProvider);
      expect(state.liveId, isNull);
      expect(state.error, contains('Not connected'));
    },
  );

  test('switchTo replaces the active session; clear resets', () async {
    await readNotifier().bootstrap();

    readNotifier().switchTo(liveId: 'e5f6a7b8', durableId: 'other-uuid');
    expect(readState().liveId, 'e5f6a7b8');
    expect(readState().durableId, 'other-uuid');

    readNotifier().clear();
    expect(readState(), const ActiveSessionState());

    // After a clear, bootstrap creates a FRESH session.
    await readNotifier().bootstrap();
    expect(readState().liveId, 'a1b2c3d4');
    expect(repository.createCalls, 2);
  });

  group('rebind (reconnect path, P1-16)', () {
    test('resumes the durable id, switches to the NEW live id, and seeds '
        'the replayed history', () async {
      await readNotifier().bootstrap(); // a1b2c3d4 / 2026-uuid

      await readNotifier().rebind();

      // Resume with the DURABLE id (protocol §9); NO fresh create.
      expect(repository.resumed, <String>['2026-uuid']);
      expect(repository.createCalls, 1);
      final state = readState();
      expect(state.liveId, 'e5f6a7b8');
      expect(state.durableId, '2026-uuid');
      expect(state.bootstrapping, isFalse);
      expect(state.error, isNull);

      // The replayed history is seeded into the NEW live id's message
      // list: terminal, non-streaming (wire §5).
      final fold = container.read(messageListProvider('e5f6a7b8'));
      expect(fold.messages, hasLength(2));
      expect(fold.messages[0].role, MessageRole.user);
      expect(fold.messages[0].text, 'before the drop');
      expect(fold.messages[0].streaming, isFalse);
      expect(fold.messages[1].role, MessageRole.assistant);
      expect(fold.messages[1].text, 'still here');
      expect(fold.messages[1].terminalStatus, MessageTerminalStatus.complete);
    });

    test('with no durable id is a plain bootstrap (fresh connect)', () async {
      await readNotifier().rebind();

      expect(repository.resumed, isEmpty);
      expect(repository.createCalls, 1);
      expect(readState().liveId, 'a1b2c3d4');
    });

    test('keeps the old session (and its message list) while the resume is '
        'in flight', () async {
      await readNotifier().bootstrap();
      final gate = Completer<SessionResumeResult>();
      repository.resumeGate = gate;

      final rebindFuture = readNotifier().rebind();
      await pumpEventQueue(); // let rebind reach the resume await

      // The reconnecting gap: old ids still active, flagged bootstrapping —
      // the chat keeps rendering the old live id's message list.
      final during = readState();
      expect(during.liveId, 'a1b2c3d4');
      expect(during.durableId, '2026-uuid');
      expect(during.bootstrapping, isTrue);

      gate.complete(repository.resumeResult);
      await rebindFuture;
      expect(readState().liveId, 'e5f6a7b8');
    });

    test('is idempotent while a rebind is in flight', () async {
      await readNotifier().bootstrap();
      final gate = Completer<SessionResumeResult>();
      repository.resumeGate = gate;

      final rebindFuture = readNotifier().rebind();
      await pumpEventQueue();
      await readNotifier().rebind(); // in-flight → no-op

      gate.complete(repository.resumeResult);
      await rebindFuture;
      expect(repository.resumed, <String>['2026-uuid']); // resumed once
    });

    test('falls back to a fresh create when the resume fails', () async {
      await readNotifier().bootstrap(); // a1b2c3d4 / 2026-uuid
      repository.resumeError = const GatewayRpcException(
        -32000,
        'session gone',
      );
      repository.createResult = const SessionCreateResult(
        liveId: 'f00d1234',
        durableId: 'new-uuid',
      );

      await readNotifier().rebind();

      expect(repository.resumed, <String>['2026-uuid']);
      expect(repository.createCalls, 2); // fresh create after the failure
      final state = readState();
      expect(state.liveId, 'f00d1234');
      expect(state.durableId, 'new-uuid');
      expect(state.error, isNull);
    });

    test('falls back to a fresh-create error when resume fails and create '
        'fails too', () async {
      await readNotifier().bootstrap();
      repository.resumeError = const GatewayRpcException(
        -32000,
        'session gone',
      );
      repository.createError = const GatewayNetworkException(
        'host unreachable',
      );

      await readNotifier().rebind();

      final state = readState();
      expect(state.liveId, isNull);
      expect(state.error, 'host unreachable');
    });
  });
}
