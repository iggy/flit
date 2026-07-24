// P1-09 acceptance: the active-session notifier — bootstrap creates a
// session and records both ids (protocol §9); failures land in state.error
// (never throw) and retry works; switchTo/clear behave.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/application/sessions/active_session.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/session_bootstrap.dart';
import 'package:hermes/domain/models/session_summary.dart';
import 'package:hermes/domain/repositories/session_repository.dart';

/// Hand-rolled fake (established pattern — see
/// test/application/chat/message_list_notifier_test.dart).
final class FakeSessionRepository implements SessionRepository {
  int createCalls = 0;
  Exception? createError;
  SessionCreateResult createResult = const SessionCreateResult(
    liveId: 'a1b2c3d4',
    durableId: '2026-uuid',
  );

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
  Future<List<SessionSummary>> list() => throw UnimplementedError();

  @override
  Future<List<ActiveSession>> activeList({String? currentLiveId}) =>
      throw UnimplementedError();

  @override
  Future<SessionResumeResult> resume(String durableId) =>
      throw UnimplementedError();

  @override
  Future<void> interrupt(String liveId) => throw UnimplementedError();
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

    // After a clear, bootstrap creates a FRESH session (reconnect path).
    await readNotifier().bootstrap();
    expect(readState().liveId, 'a1b2c3d4');
    expect(repository.createCalls, 2);
  });
}
