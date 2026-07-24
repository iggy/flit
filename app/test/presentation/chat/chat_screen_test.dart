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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/dto/events/gateway_event_parser.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/session_bootstrap.dart';
import 'package:hermes/domain/models/session_summary.dart';
import 'package:hermes/domain/repositories/chat_repository.dart';
import 'package:hermes/domain/repositories/session_repository.dart';
import 'package:hermes/presentation/chat/chat_screen.dart';
import 'package:hermes/presentation/chat/composer.dart';
import 'package:hermes/presentation/chat/message_bubble.dart';
import 'package:hermes/presentation/chat/tool_call_card.dart';

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

  void emit(TypedGatewayEvent event) => _events.add(event);

  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) {
    subscribedLiveId = liveId;
    return _events.stream;
  }

  @override
  Future<void> submitPrompt(String liveId, String text) async {
    submitted.add((liveId: liveId, text: text));
  }

  @override
  Future<void> respondApproval(String liveId, String choice) async {
    approvals.add((liveId: liveId, choice: choice));
  }

  @override
  Future<void> respondClarify(String requestId, String answer) async {
    clarifies.add((requestId: requestId, answer: answer));
  }

  Future<void> dispose() => _events.close();
}

/// Fake session repository returning the fixture's live id.
final class FakeSessionRepository implements SessionRepository {
  int createCalls = 0;
  Exception? createError;
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
  Future<SessionResumeResult> resume(String durableId) =>
      throw UnimplementedError();
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

  Widget harness() {
    return ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(chatRepository),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        connectionStateProvider.overrideWith(
          (ref) => Stream<GatewayConnectionState>.value(
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
}
