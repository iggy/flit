// P9-02 acceptance: DeepLinkResolver resolves a /session/:id deep link by its
// DURABLE id (the id in the URL is the durable one — it survives restarts,
// unlike the live id).
//
// - Already-active durable id → no-op (no resume, no re-switch).
// - Durable id present in the history list → resumed and switched to the NEW
//   live id, with the replayed history seeded into messageListProvider.
// - Durable id NOT in the list → direct session.resume fallback.
// - Nothing throws: a failing gateway and a null repository both land in
//   state.error.

import 'dart:async';

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/deep_link_resolver.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/prompt_submit_status.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flit/domain/models/submit_prompt_result.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake (established pattern — see session_list_test.dart); only
/// the methods the resolver path touches are implemented.
final class FakeSessionRepository implements SessionRepository {
  List<SessionSummary> listResult = const <SessionSummary>[];

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

  @override
  Future<List<SessionSummary>> list() async => listResult;

  @override
  Future<List<ActiveSession>> activeList({String? currentLiveId}) async =>
      const <ActiveSession>[];

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
  Future<void> interrupt(String liveId) => throw UnimplementedError();

  @override
  Future<SteerOutcome> steer(String liveId, String text) =>
      throw UnimplementedError();

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
}

/// Minimal chat repository so messageListProvider can be built.
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();

  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) => _events.stream;

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
  late FakeSessionRepository repository;
  late FakeChatRepository chatRepository;
  late StreamController<GatewayEvent> gatewayEvents;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSessionRepository();
    chatRepository = FakeChatRepository();
    gatewayEvents = StreamController<GatewayEvent>.broadcast();
    container = ProviderContainer(
      // Deterministic tests: Riverpod 3 retries failing providers by default.
      retry: (retryCount, error) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
        gatewayEventsProvider.overrideWith((ref) => gatewayEvents.stream),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await chatRepository.dispose();
    await gatewayEvents.close();
  });

  DeepLinkResolver resolver() =>
      container.read(deepLinkResolverProvider.notifier);

  test('starts idle', () {
    expect(
      container.read(deepLinkResolverProvider),
      const DeepLinkResolveState(),
    );
  });

  test('an already-active durable id is a no-op', () async {
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: 'a1b2c3d4', durableId: 'durable-1');

    await resolver().resolve('durable-1');

    expect(repository.resumed, isEmpty);
    expect(container.read(activeSessionProvider).liveId, 'a1b2c3d4');
    expect(container.read(deepLinkResolverProvider).error, isNull);
  });

  test('a durable id in the history list resumes and seeds history', () async {
    repository.listResult = const <SessionSummary>[
      SessionSummary(
        durableId: 'durable-9',
        title: 'Fix the parser',
        preview: 'last message…',
        messageCount: 2,
      ),
    ];
    // The list must be loaded — the resolver reads it, it does not await it.
    await container.read(sessionListProvider.future);

    await resolver().resolve('durable-9');

    expect(repository.resumed, <String>['durable-9']);
    // Switched to the NEW live id minted by the resume.
    expect(container.read(activeSessionProvider).liveId, 'e5f6a7b8');
    expect(container.read(activeSessionProvider).durableId, 'durable-9');
    // The replayed history landed in the new live id's message list.
    final messages = container.read(messageListProvider('e5f6a7b8')).messages;
    expect(messages.length, 2);
    expect(messages.first.text, 'hello?');
    expect(container.read(deepLinkResolverProvider).error, isNull);
  });

  test('a durable id absent from the list falls back to resume', () async {
    // Empty history: the link points at a session the list does not know.
    await container.read(sessionListProvider.future);

    await resolver().resolve('durable-9');

    expect(repository.resumed, <String>['durable-9']);
    expect(container.read(activeSessionProvider).liveId, 'e5f6a7b8');
    expect(container.read(messageListProvider('e5f6a7b8')).messages.length, 2);
    expect(container.read(deepLinkResolverProvider).error, isNull);
  });

  test('a failing resume lands in state.error, never throws', () async {
    repository.resumeError = const GatewayNetworkException('host unreachable');

    await resolver().resolve('durable-9');

    expect(container.read(deepLinkResolverProvider).error, 'host unreachable');
    expect(container.read(deepLinkResolverProvider).busy, isFalse);

    resolver().clearError();
    expect(container.read(deepLinkResolverProvider).error, isNull);
  });

  test('resolving while disconnected reports not connected', () async {
    final disconnected = ProviderContainer(retry: (retryCount, error) => null);
    addTearDown(disconnected.dispose);

    await disconnected.read(deepLinkResolverProvider.notifier).resolve('d-1');

    expect(
      disconnected.read(deepLinkResolverProvider).error,
      contains('Not connected'),
    );
  });
}
