// Phase 2 acceptance: session-info providers (usage, context breakdown, most
// recent, and live-updating usage from session.info events).
//
// - sessionUsageProvider / contextBreakdownProvider fetch active-session stats
//   (live id); null repo or no active session → null.
// - mostRecentSessionProvider queries the DB; null repo → null.
// - liveUsageProvider starts null and updates on session.info events with a
//   usage sub-dict.

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_info.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake session repository.
final class FakeSessionRepository implements SessionRepository {
  SessionUsageStats usageResult = const SessionUsageStats(
    model: 'claude-opus',
    input: 100,
    output: 50,
    total: 150,
    calls: 1,
  );

  ContextBreakdown contextBreakdownResult = const ContextBreakdown(
    categories: <ContextCategory>[
      ContextCategory(
        id: 'system_prompt',
        label: 'System Prompt',
        tokens: 500,
        color: 'var(--context-usage-system)',
      ),
    ],
    contextMax: 200000,
    contextPercent: 10,
    contextUsed: 20000,
    estimatedTotal: 20000,
    model: 'claude-opus',
  );

  MostRecentSession? mostRecentResult = const MostRecentSession(
    durableId: 'durable-123',
    title: 'Recent chat',
    source: 'cli',
  );

  @override
  Future<SessionUsageStats> usage(String liveId) async {
    return usageResult;
  }

  @override
  Future<ContextBreakdown> contextBreakdown(String liveId) async {
    return contextBreakdownResult;
  }

  @override
  Future<MostRecentSession?> mostRecent({String? profile}) async {
    return mostRecentResult;
  }

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
  }) => throw UnimplementedError();

  @override
  Future<List<SessionSummary>> list() => throw UnimplementedError();

  @override
  Future<List<ActiveSession>> activeList({String? currentLiveId}) =>
      throw UnimplementedError();

  @override
  Future<SessionResumeResult> resume(
    String durableId, {
    bool omitMessages = false,
    bool lazy = false,
  }) => throw UnimplementedError();

  @override
  Future<void> interrupt(String liveId) => throw UnimplementedError();

  @override
  Future<String> setTitle(String liveId, String title) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String durableId, {String? profile}) =>
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
  late StreamController<GatewayEvent> eventsController;

  setUp(() {
    repository = FakeSessionRepository();
    eventsController = StreamController<GatewayEvent>.broadcast();
    container = ProviderContainer(
      // Deterministic tests: Riverpod 3 retries failing providers by default.
      retry: (retryCount, error) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
        gatewayEventsProvider.overrideWith((ref) => eventsController.stream),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await eventsController.close();
  });

  test('sessionUsageProvider returns null when repo is null', () async {
    final disconnected = ProviderContainer();
    addTearDown(disconnected.dispose);

    final usage = await disconnected.read(sessionUsageProvider.future);

    expect(usage, isNull);
  });

  test('sessionUsageProvider returns null when no active session', () async {
    final usage = await container.read(sessionUsageProvider.future);

    expect(usage, isNull);
  });

  test('sessionUsageProvider fetches usage for active session', () async {
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: 'a1b2c3d4', durableId: 'd');

    final usage = await container.read(sessionUsageProvider.future);

    expect(usage, repository.usageResult);
    expect(usage?.model, 'claude-opus');
    expect(usage?.total, 150);
  });

  test('contextBreakdownProvider returns null when repo is null', () async {
    final disconnected = ProviderContainer();
    addTearDown(disconnected.dispose);

    final breakdown = await disconnected.read(contextBreakdownProvider.future);

    expect(breakdown, isNull);
  });

  test(
    'contextBreakdownProvider returns null when no active session',
    () async {
      final breakdown = await container.read(contextBreakdownProvider.future);

      expect(breakdown, isNull);
    },
  );

  test(
    'contextBreakdownProvider fetches breakdown for active session',
    () async {
      container
          .read(activeSessionProvider.notifier)
          .switchTo(liveId: 'a1b2c3d4', durableId: 'd');

      final breakdown = await container.read(contextBreakdownProvider.future);

      expect(breakdown, repository.contextBreakdownResult);
      expect(breakdown?.model, 'claude-opus');
      expect(breakdown?.categories, hasLength(1));
    },
  );

  test('mostRecentSessionProvider returns null when repo is null', () async {
    final disconnected = ProviderContainer();
    addTearDown(disconnected.dispose);

    final recent = await disconnected.read(mostRecentSessionProvider.future);

    expect(recent, isNull);
  });

  test('mostRecentSessionProvider fetches most recent session', () async {
    final recent = await container.read(mostRecentSessionProvider.future);

    expect(recent, repository.mostRecentResult);
    expect(recent?.durableId, 'durable-123');
    expect(recent?.title, 'Recent chat');
  });

  test('liveUsageProvider starts null', () {
    final usage = container.read(liveUsageProvider);

    expect(usage, isNull);
  });

  test('liveUsageProvider updates on session.info event with usage', () async {
    // Riverpod 3 pauses ref.listen while no one listens to the provider.
    final sub = container.listen(liveUsageProvider, (previous, next) {});
    addTearDown(sub.close);

    // Emit a session.info event with usage sub-dict.
    eventsController.add(
      const GatewayEvent(
        type: 'session.info',
        sessionId: 'a1b2c3d4',
        payload: <String, dynamic>{
          'usage': <String, dynamic>{
            'model': 'claude-sonnet',
            'input': 10,
            'output': 5,
            'total': 15,
            'calls': 1,
          },
        },
      ),
    );

    await Future<void>.delayed(Duration.zero);

    final usage = container.read(liveUsageProvider);
    expect(usage, isNotNull);
    expect(usage?.model, 'claude-sonnet');
    expect(usage?.input, 10);
    expect(usage?.output, 5);
    expect(usage?.total, 15);
    expect(usage?.calls, 1);
  });

  test('liveUsageProvider ignores session.info without usage', () async {
    final sub = container.listen(liveUsageProvider, (previous, next) {});
    addTearDown(sub.close);

    eventsController.add(
      const GatewayEvent(
        type: 'session.info',
        sessionId: 'a1b2c3d4',
        payload: <String, dynamic>{
          'model': 'claude-opus',
          // No usage field.
        },
      ),
    );

    await Future<void>.delayed(Duration.zero);

    final usage = container.read(liveUsageProvider);
    expect(usage, isNull);
  });

  test('liveUsageProvider updates on multiple session.info events', () async {
    final sub = container.listen(liveUsageProvider, (previous, next) {});
    addTearDown(sub.close);

    // First event.
    eventsController.add(
      const GatewayEvent(
        type: 'session.info',
        sessionId: 'a1b2c3d4',
        payload: <String, dynamic>{
          'usage': <String, dynamic>{
            'model': 'claude-opus',
            'input': 100,
            'output': 50,
            'total': 150,
            'calls': 1,
          },
        },
      ),
    );

    await Future<void>.delayed(Duration.zero);

    var usage = container.read(liveUsageProvider);
    expect(usage?.model, 'claude-opus');
    expect(usage?.total, 150);

    // Second event (updated stats).
    eventsController.add(
      const GatewayEvent(
        type: 'session.info',
        sessionId: 'a1b2c3d4',
        payload: <String, dynamic>{
          'usage': <String, dynamic>{
            'model': 'claude-opus',
            'input': 200,
            'output': 100,
            'total': 300,
            'calls': 2,
          },
        },
      ),
    );

    await Future<void>.delayed(Duration.zero);

    usage = container.read(liveUsageProvider);
    expect(usage?.model, 'claude-opus');
    expect(usage?.total, 300);
    expect(usage?.calls, 2);
  });
}
