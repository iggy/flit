// P3-02/P3-03 acceptance: composer slash autocomplete and dispatch.
//
// - P3-02: typing `/mo` populates suggestions; tapping a suggestion sets the
//   field text to item.text (includes trailing space).
// - P3-03: submitting `/model gpt` routes to dispatch (not submitPrompt) and
//   does NOT append a user message. Dispatch results fan out: DispatchPrefill
//   populates the field, DispatchSend appends a user message + triggers
//   submitPrompt.

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/slash/slash_providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/slash_completion.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flit/domain/repositories/slash_repository.dart';
import 'package:flit/presentation/chat/composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const liveId = 'test-live-id';

/// Fake slash repository for testing autocomplete and dispatch.
final class FakeSlashRepository implements SlashRepository {
  final List<String> completedTexts = <String>[];
  final List<({String name, String arg, String sessionId})> dispatched =
      <({String name, String arg, String sessionId})>[];

  /// Canned completion result.
  SlashCompletionResult completeResult = const SlashCompletionResult(
    items: <CompletionItem>[
      CompletionItem(text: '/model ', display: '/model', meta: 'Switch model'),
      CompletionItem(text: '/new ', display: '/new', meta: 'New session'),
    ],
    replaceFrom: 0,
  );

  /// Canned dispatch result (defaults to DispatchSend).
  /// Can be set to a single result or overridden per-call via dispatchFn.
  CommandDispatchResult dispatchResult = const DispatchSend(
    message: 'dispatched message',
  );

  /// Optional custom dispatch function (overrides dispatchResult).
  CommandDispatchResult Function({
    required String name,
    required String arg,
    required String sessionId,
  })? dispatchFn;

  @override
  Future<SlashCompletionResult> completeSlash(String text) async {
    completedTexts.add(text);
    return completeResult;
  }

  @override
  Future<CommandDispatchResult> dispatch({
    required String name,
    required String arg,
    required String sessionId,
  }) async {
    dispatched.add((name: name, arg: arg, sessionId: sessionId));
    final fn = dispatchFn;
    if (fn != null) {
      return fn(name: name, arg: arg, sessionId: sessionId);
    }
    return dispatchResult;
  }

  @override
  Future<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();
}

/// Fake chat repository for verifying submitPrompt calls.
final class FakeChatRepository implements ChatRepository {
  final StreamController<TypedGatewayEvent> _events =
      StreamController<TypedGatewayEvent>.broadcast();
  final List<({String liveId, String text})> submitted =
      <({String liveId, String text})>[];

  @override
  Stream<TypedGatewayEvent> turnEvents(String liveId) => _events.stream;

  @override
  Future<void> submitPrompt(String liveId, String text) async {
    submitted.add((liveId: liveId, text: text));
  }

  @override
  Future<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();

  Future<void> dispose() => _events.close();
}

/// Fake session repository for bootstrap.
final class FakeSessionRepository implements SessionRepository {
  @override
  Future<SessionCreateResult> create({
    String? profile,
    String? cwd,
    String? model,
  }) async {
    return const SessionCreateResult(liveId: liveId, durableId: 'durable-id');
  }

  @override
  Future<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();
}

void main() {
  late FakeSlashRepository slashRepository;
  late FakeChatRepository chatRepository;
  late FakeSessionRepository sessionRepository;

  setUp(() {
    slashRepository = FakeSlashRepository();
    chatRepository = FakeChatRepository();
    sessionRepository = FakeSessionRepository();
  });

  tearDown(() async => chatRepository.dispose());

  Widget harness() {
    return ProviderScope(
      overrides: [
        slashRepositoryProvider.overrideWithValue(slashRepository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        connectionStateProvider.overrideWith(
          (ref) => Stream.value(GatewayConnectionState.ready),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              // Bootstrap the session once on first build.
              ref.listen(activeSessionProvider, (previous, next) {});
              if (ref.read(activeSessionProvider).liveId == null) {
                Future.microtask(
                  () =>
                      ref.read(activeSessionProvider.notifier).bootstrap(),
                );
              }
              return const Composer();
            },
          ),
        ),
      ),
    );
  }

  /// Pump the harness and let bootstrap complete.
  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(); // microtask bootstrap triggers
    await tester.pump(); // session.create completes
  }

  testWidgets('P3-02: typing /mo populates suggestions', (tester) async {
    await pumpComposer(tester);

    // Type '/mo' into the field.
    await tester.enterText(find.byKey(composerFieldKey), '/mo');
    // pumpAndSettle waits for all async operations to complete.
    await tester.pumpAndSettle();

    // Verify completeSlash was called with '/mo'.
    expect(slashRepository.completedTexts, contains('/mo'));

    // Verify suggestions are visible.
    expect(find.byKey(const Key('slash_suggestions')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('slash_suggestion_/model')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('slash_suggestion_/new')),
      findsOneWidget,
    );
  });

  testWidgets('P3-02: tapping a suggestion sets field text', (tester) async {
    await pumpComposer(tester);

    await tester.enterText(find.byKey(composerFieldKey), '/mo');
    await tester.pumpAndSettle();

    // Tap the '/model' suggestion.
    await tester.tap(find.byKey(const ValueKey('slash_suggestion_/model')));
    await tester.pumpAndSettle();

    // Verify the field text is replaced with item.text (includes trailing space).
    final field = tester.widget<TextField>(find.byKey(composerFieldKey));
    expect(field.controller?.text, '/model ');

    // Suggestions should be cleared.
    expect(find.byKey(const Key('slash_suggestions')), findsNothing);
  });

  testWidgets(
    'P3-02: suggestions cleared when text no longer starts with /',
    (tester) async {
      await pumpComposer(tester);

      // Type '/mo' → suggestions appear.
      await tester.enterText(find.byKey(composerFieldKey), '/mo');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('slash_suggestions')), findsOneWidget);

      // Replace with normal text → suggestions disappear.
      await tester.enterText(find.byKey(composerFieldKey), 'hello');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('slash_suggestions')), findsNothing);
    },
  );

  testWidgets('P3-03: submitting /model gpt routes to dispatch', (tester) async {
    // Set a dispatch result that does NOT trigger submitPrompt.
    slashRepository.dispatchResult = const DispatchExec('Model switched');

    await pumpComposer(tester);

    // Enter '/model gpt' and submit.
    await tester.enterText(find.byKey(composerFieldKey), '/model gpt');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(composerSendKey));
    await tester.pumpAndSettle();

    // Wait for async dispatch.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify dispatch was called with name='/model', arg='gpt'.
    expect(slashRepository.dispatched.length, 1);
    final call = slashRepository.dispatched.first;
    expect(call.name, '/model');
    expect(call.arg, 'gpt');
    expect(call.sessionId, liveId);

    // Verify submitPrompt was NOT called (DispatchExec shows via SnackBar).
    expect(chatRepository.submitted, isEmpty);
  });

  testWidgets('P3-03: DispatchPrefill populates the field', (tester) async {
    slashRepository.dispatchResult = const DispatchPrefill(
      message: 'prefilled text',
      notice: 'Notice here',
    );

    await pumpComposer(tester);

    await tester.enterText(find.byKey(composerFieldKey), '/retry');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(composerSendKey));
    await tester.pumpAndSettle();

    // Wait for async dispatch to complete.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify the field text is populated with the message.
    final field = tester.widget<TextField>(find.byKey(composerFieldKey));
    expect(field.controller?.text, 'prefilled text');

    // Verify the notice is shown via SnackBar.
    expect(find.text('Notice here'), findsOneWidget);
  });

  testWidgets(
    'P3-03: DispatchSend appends user message and triggers submitPrompt',
    (tester) async {
      slashRepository.dispatchResult = const DispatchSend(
        message: 'transformed message',
      );

      await pumpComposer(tester);

      await tester.enterText(find.byKey(composerFieldKey), '/queue foo');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(composerSendKey));
      await tester.pumpAndSettle();

      // Wait for async dispatch.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify submitPrompt was called with the transformed message.
      expect(chatRepository.submitted.length, 1);
      expect(chatRepository.submitted.first.text, 'transformed message');
    },
  );

  testWidgets('P3-03: DispatchExec shows output via SnackBar', (tester) async {
    slashRepository.dispatchResult = const DispatchExec('Command output here');

    await pumpComposer(tester);

    await tester.enterText(find.byKey(composerFieldKey), '/help');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(composerSendKey));
    await tester.pumpAndSettle();

    // Wait for async dispatch.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify the output is shown via SnackBar.
    expect(find.text('Command output here'), findsOneWidget);
  });

  testWidgets('P3-03: DispatchAlias re-dispatches with target', (tester) async {
    // First dispatch returns an alias; second dispatch returns DispatchExec.
    slashRepository.dispatchFn = ({
      required String name,
      required String arg,
      required String sessionId,
    }) {
      if (name == '/m') {
        return const DispatchAlias('/model');
      }
      return const DispatchExec('Model switched');
    };

    await pumpComposer(tester);

    await tester.enterText(find.byKey(composerFieldKey), '/m gpt');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(composerSendKey));
    await tester.pumpAndSettle();

    // Wait for async dispatch hops.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify dispatch was called twice: first with '/m', second with '/model'.
    expect(slashRepository.dispatched.length, 2);
    expect(slashRepository.dispatched[0].name, '/m');
    expect(slashRepository.dispatched[0].arg, 'gpt');
    expect(slashRepository.dispatched[1].name, '/model');
    expect(slashRepository.dispatched[1].arg, 'gpt');
  });

  testWidgets('P3-03: non-slash text keeps existing send behavior', (tester) async {
    await pumpComposer(tester);

    // Enter normal text and submit.
    await tester.enterText(find.byKey(composerFieldKey), 'hello world');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(composerSendKey));
    await tester.pumpAndSettle();

    // Verify dispatch was NOT called.
    expect(slashRepository.dispatched, isEmpty);

    // Verify submitPrompt was called with the normal text.
    expect(chatRepository.submitted.length, 1);
    expect(chatRepository.submitted.first.text, 'hello world');
  });
}
