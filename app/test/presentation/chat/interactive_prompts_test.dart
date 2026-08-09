// P1-08 acceptance: inline interactive prompts.
//
// - approval.request renders command + description; Approve sends
//   approval.respond{session_id, choice:"approve"} (correlated BY SESSION,
//   protocol §8.2) and dismisses the card.
// - "Always allow" is only offered when allow_permanent, and sends the
//   approve-and-remember choice (see ApprovalChoice for the literal
//   deviation note).
// - clarify.request with choices renders chips and answers by request_id;
//   choices == null means free text.

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/prompt_submit_status.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flit/domain/models/submit_prompt_result.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flit/presentation/chat/approval_prompt_card.dart';
import 'package:flit/presentation/chat/chat_screen.dart';
import 'package:flit/presentation/chat/clarify_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const liveId = 'a1b2c3d4';

/// Same hand-rolled fakes as chat_screen_test.dart (tests are
/// self-contained by convention).
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();

  final List<({String liveId, String choice})> approvals =
      <({String liveId, String choice})>[];
  final List<({String requestId, String answer})> clarifies =
      <({String requestId, String answer})>[];
  final List<({String requestId, String password})> sudos =
      <({String requestId, String password})>[];
  final List<({String requestId, String value})> secrets =
      <({String requestId, String value})>[];
  final List<({String requestId, String text})> terminalReads =
      <({String requestId, String text})>[];

  void emit(TypedGatewayEvent event) => _events.add(event);

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
  Future<void> respondApproval(String liveId, String choice) async {
    approvals.add((liveId: liveId, choice: choice));
  }

  @override
  Future<void> respondClarify(String requestId, String answer) async {
    clarifies.add((requestId: requestId, answer: answer));
  }

  @override
  Future<void> respondSudo(String requestId, String password) async {
    sudos.add((requestId: requestId, password: password));
  }

  @override
  Future<void> respondSecret(String requestId, String value) async {
    secrets.add((requestId: requestId, value: value));
  }

  @override
  Future<void> respondTerminalRead(String requestId, String text) async {
    terminalReads.add((requestId: requestId, text: text));
  }

  Future<void> dispose() => _events.close();
}

final class FakeSessionRepository implements SessionRepository {
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
    return const SessionCreateResult(liveId: liveId, durableId: '2026-uuid');
  }

  @override
  Future<void> interrupt(String liveId) async {}

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
  }) =>
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

  @override
  Future<SteerOutcome> steer(String liveId, String text) async {
    return SteerOutcome.queued;
  }
}

void main() {
  late FakeChatRepository chatRepository;

  setUp(() => chatRepository = FakeChatRepository());
  tearDown(() async => chatRepository.dispose());

  Future<void> pumpChat(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepository),
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          connectionStateProvider.overrideWith(
            (ref) => Stream<GatewayConnectionState>.value(
              GatewayConnectionState.ready,
            ),
          ),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await tester.pump(); // post-frame hook fires bootstrap()
    await tester.pump(); // session.create completes
  }

  testWidgets('approval card renders command + description; Approve responds '
      'by session and dismisses', (tester) async {
    await pumpChat(tester);

    chatRepository.emit(
      const TypedGatewayEvent.approvalRequest(
        sessionId: liveId,
        command: 'rm -rf build/',
        description: 'Delete build dir',
        patternKey: 'rm',
        patternKeys: <String>['rm'],
        allowPermanent: false,
      ),
    );
    await tester.pump();

    expect(find.text('Delete build dir'), findsOneWidget);
    expect(find.text('rm -rf build/', findRichText: true), findsOneWidget);
    // No permanent option when allow_permanent is false.
    expect(find.text('Always allow'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pump();

    expect(chatRepository.approvals.single, (
      liveId: liveId,
      choice: ApprovalChoice.approve,
    ));
    // Card dismissed from the fold state.
    expect(find.text('Delete build dir'), findsNothing);
  });

  testWidgets('Deny sends choice "deny" and dismisses', (tester) async {
    await pumpChat(tester);

    chatRepository.emit(
      const TypedGatewayEvent.approvalRequest(
        sessionId: liveId,
        command: 'rm -rf build/',
        description: 'Delete build dir',
        patternKey: 'rm',
        patternKeys: <String>['rm'],
        allowPermanent: true,
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Deny'));
    await tester.pump();

    expect(chatRepository.approvals.single, (
      liveId: liveId,
      choice: ApprovalChoice.deny,
    ));
    expect(find.text('Delete build dir'), findsNothing);
  });

  testWidgets('"Always allow" appears only with allow_permanent and sends '
      'the approve-and-remember choice', (tester) async {
    await pumpChat(tester);

    chatRepository.emit(
      const TypedGatewayEvent.approvalRequest(
        sessionId: liveId,
        command: 'rm -rf build/',
        description: 'Delete build dir',
        patternKey: 'rm',
        patternKeys: <String>['rm'],
        allowPermanent: true,
      ),
    );
    await tester.pump();

    expect(find.text('Always allow'), findsOneWidget);
    await tester.tap(find.text('Always allow'));
    await tester.pump();

    expect(chatRepository.approvals.single, (
      liveId: liveId,
      choice: ApprovalChoice.approveAndRemember,
    ));
    expect(chatRepository.approvals.single.choice, 'approve_and_remember');
    expect(find.text('Delete build dir'), findsNothing);
  });

  testWidgets('clarify with choices renders chips and answers by request id', (
    tester,
  ) async {
    await pumpChat(tester);

    chatRepository.emit(
      const TypedGatewayEvent.clarifyRequest(
        sessionId: liveId,
        question: 'Which environment?',
        choices: <String>['staging', 'prod'],
        requestId: '9f3a1c2b',
      ),
    );
    await tester.pump();

    expect(find.text('Which environment?'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'staging'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'prod'), findsOneWidget);
    // Choices given → no free-text field.
    expect(find.byKey(clarifyFieldKey), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, 'prod'));
    await tester.pump();

    expect(chatRepository.clarifies.single, (
      requestId: '9f3a1c2b',
      answer: 'prod',
    ));
    expect(find.text('Which environment?'), findsNothing);
  });

  testWidgets('clarify with choices == null is free text', (tester) async {
    await pumpChat(tester);

    chatRepository.emit(
      const TypedGatewayEvent.clarifyRequest(
        sessionId: liveId,
        question: 'What color should the build banner be?',
        choices: null,
        requestId: '1b2c3d4e',
      ),
    );
    await tester.pump();

    expect(find.byKey(clarifyFieldKey), findsOneWidget);
    await tester.enterText(find.byKey(clarifyFieldKey), 'blue');
    await tester.tap(find.byKey(clarifySubmitKey));
    await tester.pump();

    expect(chatRepository.clarifies.single, (
      requestId: '1b2c3d4e',
      answer: 'blue',
    ));
    expect(find.text('What color should the build banner be?'), findsNothing);
  });
}
