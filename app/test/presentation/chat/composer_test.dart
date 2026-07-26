// P3-02/P3-03 acceptance: composer slash autocomplete and dispatch.
//
// - P3-02: typing `/mo` populates suggestions; tapping a suggestion sets the
//   field text to item.text (includes trailing space).
// - P3-03: submitting `/model gpt` routes to dispatch (not submitPrompt) and
//   does NOT append a user message. Dispatch results fan out: DispatchPrefill
//   populates the field, DispatchSend appends a user message + triggers
//   submitPrompt.

import 'dart:async';

import 'package:flit/application/attachments/attachment_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/slash/slash_providers.dart';
import 'package:flit/application/voice/voice_providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/attachment.dart';
import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/slash_completion.dart';
import 'package:flit/domain/models/voice_state.dart';
import 'package:flit/domain/repositories/attachment_repository.dart';
import 'package:flit/domain/repositories/chat_repository.dart';
import 'package:flit/domain/repositories/session_repository.dart';
import 'package:flit/domain/repositories/slash_repository.dart';
import 'package:flit/domain/repositories/voice_repository.dart';
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

/// Fake attachment repository for testing attachment operations.
final class FakeAttachmentRepository implements AttachmentRepository {
  final List<({String sessionId, String contentBase64, String? filename})> imagesAttached =
      <({String sessionId, String contentBase64, String? filename})>[];
  final List<({String sessionId, String path})> imagesDetached =
      <({String sessionId, String path})>[];

  @override
  Future<ImageAttachment> attachImageBytes(
    String sessionId, {
    required String contentBase64,
    String? filename,
    String? ext,
  }) async {
    imagesAttached.add((
      sessionId: sessionId,
      contentBase64: contentBase64,
      filename: filename,
    ));
    return ImageAttachment(
      path: '/tmp/image_${imagesAttached.length}.jpg',
      name: filename ?? 'image.jpg',
      count: imagesAttached.length,
      tokenEstimate: 100,
    );
  }

  @override
  Future<DetachResult> detachImage(String sessionId, String path) async {
    imagesDetached.add((sessionId: sessionId, path: path));
    return DetachResult(detached: true, count: imagesAttached.length - 1);
  }

  @override
  Future<dynamic> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError();
}

/// Fake voice repository for testing voice operations.
final class FakeVoiceRepository implements VoiceRepository {
  final List<String> toggleCalls = <String>[];
  final List<({String action, String? sessionId})> recordCalls =
      <({String action, String? sessionId})>[];

  VoiceToggleResult toggleResult = const VoiceToggleResult(
    enabled: false,
    tts: false,
    recordKey: 'Ctrl+B',
  );

  VoiceRecordResult recordResult = const VoiceRecordResult(
    status: 'recording',
  );

  @override
  Future<VoiceToggleResult> toggle(String action) async {
    toggleCalls.add(action);
    return toggleResult;
  }

  @override
  Future<VoiceRecordResult> record(String action, {String? sessionId}) async {
    recordCalls.add((action: action, sessionId: sessionId));
    return recordResult;
  }

  @override
  Future<VoiceTtsResult> tts(String text) async {
    return const VoiceTtsResult(status: 'speaking');
  }
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
        voiceRepositoryProvider.overrideWithValue(null), // P7: avoid voice errors in old tests
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

  group('P7: Attachments', () {
    late FakeAttachmentRepository attachmentRepository;

    setUp(() {
      attachmentRepository = FakeAttachmentRepository();
    });

    Widget harnessWithAttachments() {
      return ProviderScope(
        overrides: [
          slashRepositoryProvider.overrideWithValue(slashRepository),
          chatRepositoryProvider.overrideWithValue(chatRepository),
          sessionRepositoryProvider.overrideWithValue(sessionRepository),
          attachmentRepositoryProvider.overrideWithValue(attachmentRepository),
          connectionStateProvider.overrideWith(
            (ref) => Stream.value(GatewayConnectionState.ready),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                ref.listen(activeSessionProvider, (previous, next) {});
                if (ref.read(activeSessionProvider).liveId == null) {
                  Future.microtask(
                    () => ref.read(activeSessionProvider.notifier).bootstrap(),
                  );
                }
                return const Composer();
              },
            ),
          ),
        ),
      );
    }

    testWidgets('attach button exists', (tester) async {
      await tester.pumpWidget(harnessWithAttachments());
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('composer_attach')), findsOneWidget);
    });

    testWidgets('staged images render attachment chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slashRepositoryProvider.overrideWithValue(slashRepository),
            chatRepositoryProvider.overrideWithValue(chatRepository),
            sessionRepositoryProvider.overrideWithValue(sessionRepository),
            attachmentRepositoryProvider.overrideWithValue(attachmentRepository),
            stagedAttachmentsProvider.overrideWith(StagedAttachmentsNotifier.new),
            connectionStateProvider.overrideWith(
              (ref) => Stream.value(GatewayConnectionState.ready),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  ref.listen(activeSessionProvider, (previous, next) {});
                  if (ref.read(activeSessionProvider).liveId == null) {
                    Future.microtask(
                      () => ref.read(activeSessionProvider.notifier).bootstrap(),
                    );
                  }
                  // Seed the staged attachments.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final notifier = ref.read(stagedAttachmentsProvider.notifier);
                    if (ref.read(stagedAttachmentsProvider).images.isEmpty) {
                      notifier.addImage(const ImageAttachment(
                        path: '/tmp/test.jpg',
                        name: 'test.jpg',
                        count: 1,
                        tokenEstimate: 150,
                      ));
                    }
                  });
                  return const Composer();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(); // Let the postFrameCallback run.

      // Verify the attachments container renders.
      expect(find.byKey(const Key('composer_attachments')), findsOneWidget);

      // Verify token estimate text renders.
      expect(find.textContaining('150 tok'), findsOneWidget);
    });

    testWidgets('tapping image delete button removes it', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slashRepositoryProvider.overrideWithValue(slashRepository),
            chatRepositoryProvider.overrideWithValue(chatRepository),
            sessionRepositoryProvider.overrideWithValue(sessionRepository),
            attachmentRepositoryProvider.overrideWithValue(attachmentRepository),
            stagedAttachmentsProvider.overrideWith(StagedAttachmentsNotifier.new),
            connectionStateProvider.overrideWith(
              (ref) => Stream.value(GatewayConnectionState.ready),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  ref.listen(activeSessionProvider, (previous, next) {});
                  if (ref.read(activeSessionProvider).liveId == null) {
                    Future.microtask(
                      () => ref.read(activeSessionProvider.notifier).bootstrap(),
                    );
                  }
                  // Seed the staged attachments.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final notifier = ref.read(stagedAttachmentsProvider.notifier);
                    if (ref.read(stagedAttachmentsProvider).images.isEmpty) {
                      notifier.addImage(const ImageAttachment(
                        path: '/tmp/test.jpg',
                        name: 'test.jpg',
                        count: 1,
                        tokenEstimate: 150,
                      ));
                    }
                  });
                  return const Composer();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(); // Let the postFrameCallback run.

      // Verify the chip renders.
      expect(find.byKey(const ValueKey('attachment_0')), findsOneWidget);

      // Tap the delete button (close icon).
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Verify detachImage was called.
      expect(attachmentRepository.imagesDetached.length, 1);
      expect(attachmentRepository.imagesDetached.first.path, '/tmp/test.jpg');

      // The chip should be gone (removeImage was called).
      expect(find.byKey(const ValueKey('attachment_0')), findsNothing);
    });
  });

  group('P7: Voice', () {
    late FakeVoiceRepository voiceRepository;

    setUp(() {
      voiceRepository = FakeVoiceRepository();
    });

    Widget harnessWithVoice() {
      return ProviderScope(
        overrides: [
          slashRepositoryProvider.overrideWithValue(slashRepository),
          chatRepositoryProvider.overrideWithValue(chatRepository),
          sessionRepositoryProvider.overrideWithValue(sessionRepository),
          voiceRepositoryProvider.overrideWithValue(voiceRepository),
          connectionStateProvider.overrideWith(
            (ref) => Stream.value(GatewayConnectionState.ready),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                ref.listen(activeSessionProvider, (previous, next) {});
                if (ref.read(activeSessionProvider).liveId == null) {
                  Future.microtask(
                    () => ref.read(activeSessionProvider.notifier).bootstrap(),
                  );
                }
                return const Composer();
              },
            ),
          ),
        ),
      );
    }

    testWidgets('mic button exists', (tester) async {
      await tester.pumpWidget(harnessWithVoice());
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('composer_mic')), findsOneWidget);
    });

    testWidgets('tts button exists and reflects state', (tester) async {
      voiceRepository.toggleResult = const VoiceToggleResult(
        enabled: true,
        tts: true,
        recordKey: 'Ctrl+B',
      );

      await tester.pumpWidget(harnessWithVoice());
      await tester.pump();
      await tester.pump();
      // Trigger status refresh.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('composer_tts')), findsOneWidget);

      // After status refresh, ttsEnabled should be true.
      // Find the button and check its icon.
      final ttsButton = find.byKey(const Key('composer_tts'));
      expect(ttsButton, findsOneWidget);
      // Icon should be volume_up when tts is enabled.
      expect(find.descendant(of: ttsButton, matching: find.byIcon(Icons.volume_up)), findsOneWidget);
    });

    testWidgets('tapping mic button starts recording', (tester) async {
      voiceRepository.toggleResult = const VoiceToggleResult(
        enabled: false,
        tts: false,
        recordKey: 'Ctrl+B',
      );

      await tester.pumpWidget(harnessWithVoice());
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap the mic button.
      await tester.tap(find.byKey(const Key('composer_mic')));
      await tester.pumpAndSettle();

      // Wait for async calls.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify toggle('on') and record('start') were called.
      expect(voiceRepository.toggleCalls, contains('on'));
      expect(voiceRepository.recordCalls.any((c) => c.action == 'start'), isTrue);
    });
  });
}
