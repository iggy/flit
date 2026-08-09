// P1-07/P1-09 acceptance: the chat screen wired to providers with fakes.
//
// - Bootstrap: arrival on /chat (connection ready) creates a session; a
//   failure shows an error + retry.
// - Conversation: feeding the recorded turn_basic.jsonl frames streams
//   text into the assistant bubble, flips a tool card running → done, and
//   removes the typing indicator on message.complete.
// - Composer: send appends the user message and calls prompt.submit; the
//   stop button calls session.interrupt while a turn is in flight.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
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
import 'package:flit/presentation/chat/chat_screen.dart';
import 'package:flit/presentation/chat/composer.dart';
import 'package:flit/presentation/chat/message_bubble.dart';
import 'package:flit/presentation/chat/tool_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const liveId = 'a1b2c3d4';

/// Fake chat repository with a controllable typed event stream.
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();

  String? subscribedLiveId;
  final List<({String liveId, String text})> submitted =
      <({String liveId, String text})>[];
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
    submitted.add((liveId: liveId, text: text));
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

/// Fake session repository returning the fixture's live id.
final class FakeSessionRepository implements SessionRepository {
  int createCalls = 0;
  Exception? createError;
  final List<String> interrupted = <String>[];

  final List<String> resumed = <String>[];
  Exception? resumeError;
  SessionResumeResult resumeResult = const SessionResumeResult(
    liveId: 'e5f6a7b8',
    durableId: '2026-uuid',
    messages: <ChatMessage>[
      ChatMessage(role: MessageRole.user, text: 'resumed history line'),
      ChatMessage(role: MessageRole.assistant, text: 'resumed answer'),
    ],
    messageCount: 2,
    running: false,
    status: SessionStatus.idle,
  );

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
    final error = createError;
    if (error != null) {
      throw error;
    }
    return const SessionCreateResult(liveId: liveId, durableId: '2026-uuid');
  }

  @override
  Future<void> interrupt(String liveId) async {
    interrupted.add(liveId);
  }

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
  }) async {
    resumed.add(durableId);
    final error = resumeError;
    if (error != null) {
      throw error;
    }
    return resumeResult;
  }

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

/// Decode a full event frame the way the RPC client's router does
/// (protocol §3c) — same helper as the fold tests.
GatewayEvent eventFromFrame(String frame) {
  final decoded = jsonDecode(frame) as Map<String, dynamic>;
  final params = decoded['params'] as Map<String, dynamic>;
  final payload = params['payload'];
  return GatewayEvent(
    type: params['type'] as String,
    sessionId: params['session_id'] as String?,
    payload: payload is Map<String, dynamic> ? payload : <String, dynamic>{},
  );
}

/// The recorded turn (test/fixtures/turn_basic.jsonl), parsed to typed
/// events, in wire order.
List<TypedGatewayEvent> fixtureEvents() {
  return File('test/fixtures/turn_basic.jsonl')
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map((line) => parseGatewayEvent(eventFromFrame(line)))
      .toList();
}

Finder markdownContaining(String needle) {
  return find.byWidgetPredicate(
    (widget) => widget is MarkdownBody && widget.data.contains(needle),
  );
}

void main() {
  late FakeChatRepository chatRepository;
  late FakeSessionRepository sessionRepository;

  setUp(() {
    chatRepository = FakeChatRepository();
    sessionRepository = FakeSessionRepository();
  });

  tearDown(() async => chatRepository.dispose());

  Widget harness({Stream<GatewayConnectionState>? connectionStream}) {
    return ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepository),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        connectionStateProvider.overrideWith(
          (ref) =>
              connectionStream ??
              Stream<GatewayConnectionState>.value(
                GatewayConnectionState.ready,
              ),
        ),
      ],
      child: const MaterialApp(home: ChatScreen()),
    );
  }

  /// Pump the screen and let the bootstrap complete.
  Future<void> pumpChat(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(); // post-frame hook fires bootstrap()
    await tester.pump(); // session.create completes, UI rebuilds
  }

  testWidgets('arrival bootstraps a session and enables the composer', (
    tester,
  ) async {
    await pumpChat(tester);

    expect(sessionRepository.createCalls, 1);
    expect(find.text('Starting a session…'), findsNothing);
    expect(find.text('No messages yet — say hello.'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(composerFieldKey));
    expect(field.enabled, isTrue);
    expect(chatRepository.subscribedLiveId, liveId);
  });

  testWidgets('composer send appends the user bubble and submits', (
    tester,
  ) async {
    await pumpChat(tester);

    await tester.enterText(find.byKey(composerFieldKey), 'hello hermes');
    await tester.tap(find.byKey(composerSendKey));
    await tester.pump();

    expect(chatRepository.submitted.single, (
      liveId: liveId,
      text: 'hello hermes',
    ));
    expect(find.text('hello hermes'), findsOneWidget); // user bubble
    // Field cleared after send.
    expect(
      tester.widget<TextField>(find.byKey(composerFieldKey)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('enter submits; shift+enter does not', (tester) async {
    await pumpChat(tester);

    await tester.enterText(find.byKey(composerFieldKey), 'via enter key');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(chatRepository.submitted.single.text, 'via enter key');

    await tester.enterText(find.byKey(composerFieldKey), 'draft line');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(chatRepository.submitted, hasLength(1)); // still just one
  });

  testWidgets('fixture turn: text streams, tool card flips, turn finalizes', (
    tester,
  ) async {
    await pumpChat(tester);
    final events = fixtureEvents();

    // message.start → streaming bubble with the typing indicator.
    chatRepository.emit(events[1]); // message.start
    await tester.pump();
    expect(find.byKey(typingIndicatorKey), findsOneWidget);

    // Two deltas accumulate into the markdown bubble.
    chatRepository.emit(events[2]); // "I'll "
    await tester.pump();
    chatRepository.emit(events[3]); // "list them."
    await tester.pump();
    expect(markdownContaining("I'll list them."), findsOneWidget);

    // tool.start → card appears, RUNNING (spinner, no check yet).
    chatRepository.emit(events[4]); // tool.start shell "ls -la"
    await tester.pump();
    expect(find.byType(ToolCallCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ToolCallCard),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('ls -la', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // tool.complete → card flips DONE; expanding shows the pretty result.
    chatRepository.emit(events[5]); // tool.complete
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ToolCallCard),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    await tester.tap(find.byType(ToolCallCard));
    await tester.pump();
    expect(find.textContaining('"stdout"', findRichText: true), findsOneWidget);
    expect(find.textContaining('1 file', findRichText: true), findsOneWidget);

    // While streaming, the composer shows STOP instead of send.
    expect(find.byKey(composerStopKey), findsOneWidget);
    expect(find.byKey(composerSendKey), findsNothing);

    // Final delta + message.complete → indicator gone, final text shown.
    chatRepository.emit(events[6]); // " There is 1 file."
    await tester.pump();
    chatRepository.emit(events[7]); // message.complete
    await tester.pump();
    expect(find.byKey(typingIndicatorKey), findsNothing);
    expect(
      markdownContaining("I'll list them. There is 1 file."),
      findsOneWidget,
    );
    // Back to idle: the send button returns.
    expect(find.byKey(composerSendKey), findsOneWidget);
    expect(find.byKey(composerStopKey), findsNothing);
  });

  testWidgets('reasoning.delta streams into a Thinking… disclosure', (
    tester,
  ) async {
    await pumpChat(tester);

    // No reasoning yet → no disclosure at all (absent, not empty).
    chatRepository.emit(
      const TypedGatewayEvent.messageStart(sessionId: liveId),
    );
    await tester.pump();
    expect(find.byKey(reasoningDisclosureKey), findsNothing);

    // Thinking streams: header reads "Thinking…", and the tail trails in the
    // collapsed header so a silent thinking phase still looks alive.
    chatRepository.emit(
      const TypedGatewayEvent.reasoningDelta(
        sessionId: liveId,
        text: 'Checking the directory first',
        verbose: false,
      ),
    );
    await tester.pump();
    expect(find.byKey(reasoningDisclosureKey), findsOneWidget);
    expect(find.text('Thinking…'), findsOneWidget);
    expect(find.text('Checking the directory first'), findsOneWidget);

    // Expanding shows the full text.
    await tester.tap(find.byKey(reasoningDisclosureKey));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(reasoningDisclosureKey),
        matching: find.byType(SelectableText),
      ),
      findsOneWidget,
    );

    // Turn ends: the disclosure SURVIVES, but stops claiming to be thinking.
    chatRepository.emit(
      const TypedGatewayEvent.messageComplete(
        sessionId: liveId,
        text: 'One file.',
        status: MessageTerminalStatus.complete,
      ),
    );
    await tester.pump();
    expect(find.byKey(reasoningDisclosureKey), findsOneWidget);
    expect(find.text('Thinking…'), findsNothing);
    expect(find.text('Thought'), findsOneWidget);
    // Still expanded (the user opened it mid-turn).
    expect(find.text('Checking the directory first'), findsOneWidget);
  });

  testWidgets('stop button interrupts the active session', (tester) async {
    await pumpChat(tester);

    chatRepository.emit(
      const TypedGatewayEvent.messageStart(sessionId: liveId),
    );
    await tester.pump();
    expect(find.byKey(composerStopKey), findsOneWidget);

    await tester.tap(find.byKey(composerStopKey));
    await tester.pump();
    expect(sessionRepository.interrupted.single, liveId);
  });

  testWidgets('bootstrap failure shows an error and retry recovers', (
    tester,
  ) async {
    sessionRepository.createError = const GatewayNetworkException(
      'host unreachable',
    );
    await pumpChat(tester);

    expect(find.text('Could not start a session'), findsOneWidget);
    expect(find.text('host unreachable'), findsOneWidget);
    // No session → composer disabled with a hint.
    final field = tester.widget<TextField>(find.byKey(composerFieldKey));
    expect(field.enabled, isFalse);

    sessionRepository.createError = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not start a session'), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(composerFieldKey)).enabled,
      isTrue,
    );
    expect(sessionRepository.createCalls, 2);
  });

  testWidgets('reconnect re-binds: the conversation survives the '
      'reconnecting gap, then resume seeds the new live id', (tester) async {
    // A controllable connection stream (single-subscription: events added
    // before the provider subscribes are buffered, none are lost).
    final connection = StreamController<GatewayConnectionState>();
    addTearDown(connection.close);

    await tester.pumpWidget(harness(connectionStream: connection.stream));

    // Fresh connect: ready → bootstrap creates a session.
    connection.add(GatewayConnectionState.ready);
    await tester.pump(); // listener fires bootstrap()
    await tester.pump(); // session.create completes
    expect(sessionRepository.createCalls, 1);
    expect(find.byTooltip('Connected'), findsOneWidget); // app-bar chip

    // Have a visible conversation.
    await tester.enterText(find.byKey(composerFieldKey), 'before the drop');
    await tester.tap(find.byKey(composerSendKey));
    await tester.pump();
    expect(find.text('before the drop'), findsOneWidget);

    // The socket drops → reconnecting: the message list must NOT be wiped
    // (the fold for the old live id stays until the rebind lands), and the
    // chip flips to the distinct reconnecting state.
    connection.add(GatewayConnectionState.reconnecting);
    await tester.pump();
    expect(find.text('before the drop'), findsOneWidget);
    expect(find.byTooltip('Reconnecting'), findsOneWidget);
    expect(find.byTooltip('Connected'), findsNothing);

    // Back to ready → rebind: session.resume with the DURABLE id, switch
    // to the NEW live id, seed the replayed history (protocol §10).
    connection.add(GatewayConnectionState.ready);
    await tester.pump(); // resume RPC
    await tester.pump(); // ids switched + history seeded, UI rebuilt

    expect(sessionRepository.resumed, <String>['2026-uuid']);
    expect(sessionRepository.createCalls, 1); // NO fresh session created
    expect(chatRepository.subscribedLiveId, 'e5f6a7b8');
    expect(find.text('resumed history line'), findsOneWidget);
    // The old fold was replaced by the resumed session's seeded history.
    expect(find.text('before the drop'), findsNothing);
    expect(find.byTooltip('Connected'), findsOneWidget);
  });

  testWidgets('reconnect falls back to a fresh session when the resume '
      'fails', (tester) async {
    final connection = StreamController<GatewayConnectionState>();
    addTearDown(connection.close);

    await tester.pumpWidget(harness(connectionStream: connection.stream));
    connection.add(GatewayConnectionState.ready);
    await tester.pump();
    await tester.pump();
    expect(sessionRepository.createCalls, 1);

    // The session is gone server-side by the time we reconnect.
    sessionRepository.resumeError = const GatewayRpcException(
      -32000,
      'session gone',
    );
    connection.add(GatewayConnectionState.reconnecting);
    await tester.pump();
    connection.add(GatewayConnectionState.ready);
    await tester.pump(); // resume fails → fallback create
    await tester.pump(); // create completes

    expect(sessionRepository.resumed, <String>['2026-uuid']);
    expect(sessionRepository.createCalls, 2); // fresh session created
    expect(find.text('No messages yet — say hello.'), findsOneWidget);
  });
}
