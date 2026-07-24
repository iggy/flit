// P1-10 acceptance (widget): the session drawer renders live + history
// entries with status badges, tap-to-switch works, 'New session' works,
// and the interrupt affordance is visible while the current live session
// is working. Errors land in a dismissible in-drawer message — never throw.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/chat/message_list_notifier.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/application/sessions/active_session.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/chat_message.dart';
import 'package:hermes/domain/models/gateway_status.dart';
import 'package:hermes/domain/models/session_bootstrap.dart';
import 'package:hermes/domain/models/session_summary.dart';
import 'package:hermes/domain/repositories/session_repository.dart';
import 'package:hermes/presentation/sessions/session_drawer.dart';

/// Hand-rolled fake (established pattern — see active_session_test.dart).
final class FakeSessionRepository implements SessionRepository {
  int createCalls = 0;
  Exception? createError;
  SessionCreateResult createResult = const SessionCreateResult(
    liveId: 'a1b2c3d4',
    durableId: 'durable-new',
  );

  Exception? listError;
  List<SessionSummary> listResult = const <SessionSummary>[];

  final List<String?> activeListArgs = <String?>[];
  List<ActiveSession> activeListResult = const <ActiveSession>[];

  final List<String> resumed = <String>[];
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
    return resumeResult;
  }

  @override
  Future<void> interrupt(String liveId) async {
    interrupted.add(liveId);
  }
}

/// A gateway status pre-seeded into gatewayStatusProvider (P1-16 footer).
final class FakeGatewayStatusNotifier extends GatewayStatusNotifier {
  FakeGatewayStatusNotifier(this._status);

  final GatewayStatus _status;

  @override
  GatewayStatus? build() => _status;
}

void main() {
  late FakeSessionRepository repository;

  setUp(() {
    repository = FakeSessionRepository();
  });

  Widget harness({bool connected = true, GatewayStatus? gatewayStatus}) {
    return ProviderScope(
      // Deterministic tests: Riverpod 3 retries failing providers by
      // default (backoff), which would leave error assertions pending.
      retry: (retryCount, error) => null,
      overrides: [
        if (connected) sessionRepositoryProvider.overrideWithValue(repository),
        if (gatewayStatus != null)
          gatewayStatusProvider.overrideWith(
            () => FakeGatewayStatusNotifier(gatewayStatus),
          ),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Hermes')),
          drawer: const SessionDrawer(),
          body: const Center(child: Text('body')),
        ),
      ),
    );
  }

  ProviderContainer containerOf(WidgetTester tester) {
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
  }

  /// Pump the harness and open the drawer via the app-bar hamburger.
  Future<ProviderContainer> pumpDrawer(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    final container = containerOf(tester);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    return container;
  }

  void switchActiveTo(
    ProviderContainer container, {
    required String liveId,
    String? durableId,
  }) {
    container
        .read(activeSessionProvider.notifier)
        .switchTo(liveId: liveId, durableId: durableId);
  }

  testWidgets('renders live and history entries with badges', (tester) async {
    repository.listResult = <SessionSummary>[
      const SessionSummary(
        durableId: 'durable-1',
        title: 'Fix the parser',
        preview: 'last message…',
        messageCount: 12,
      ),
      const SessionSummary(
        durableId: 'durable-2',
        title: '',
        preview: '',
        messageCount: 0,
      ),
    ];
    repository.activeListResult = const <ActiveSession>[
      ActiveSession(
        liveId: 'aaaa1111',
        status: SessionStatus.idle,
        title: 'Live one',
        preview: 'caught up',
      ),
      ActiveSession(liveId: 'bbbb2222', status: SessionStatus.working),
    ];

    final container = await pumpDrawer(tester);
    switchActiveTo(container, liveId: 'aaaa1111', durableId: 'durable-1');
    await tester.pumpAndSettle();

    // Live section: titles, previews, status badges.
    expect(find.text('Live one'), findsOneWidget);
    expect(find.textContaining('idle'), findsWidgets);
    expect(find.textContaining('working'), findsOneWidget);

    // History section: title, preview, message count; untitled fallback.
    expect(find.text('Fix the parser'), findsOneWidget);
    expect(find.textContaining('12 messages'), findsOneWidget);
    expect(find.text('Untitled'), findsWidgets);

    // The current live id is highlighted; NO interrupt affordance while
    // the current session is idle.
    final currentTile = tester.widget<ListTile>(
      find.byKey(sessionDrawerLiveKey('aaaa1111')),
    );
    expect(currentTile.selected, isTrue);
    expect(find.byKey(sessionDrawerInterruptKey), findsNothing);

    // active_list was called WITH the current live id (protocol §9).
    expect(repository.activeListArgs, contains('aaaa1111'));
  });

  testWidgets('tapping a live row switches by live id and closes the drawer', (
    tester,
  ) async {
    repository.activeListResult = const <ActiveSession>[
      ActiveSession(liveId: 'aaaa1111', status: SessionStatus.idle),
      ActiveSession(
        liveId: 'bbbb2222',
        status: SessionStatus.idle,
        title: 'Second live',
      ),
    ];

    final container = await pumpDrawer(tester);
    switchActiveTo(container, liveId: 'aaaa1111', durableId: 'durable-1');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(sessionDrawerLiveKey('bbbb2222')));
    await tester.pumpAndSettle();

    expect(container.read(activeSessionProvider).liveId, 'bbbb2222');
    expect(repository.resumed, isEmpty); // live switch — no resume
    expect(find.byType(Drawer), findsNothing); // drawer closed
  });

  testWidgets(
    'tapping a history row resumes, switches, seeds history, and closes',
    (tester) async {
      repository.listResult = const <SessionSummary>[
        SessionSummary(
          durableId: 'durable-9',
          title: 'Old chat',
          preview: 'hi there',
          messageCount: 2,
        ),
      ];

      final container = await pumpDrawer(tester);

      await tester.tap(find.byKey(sessionDrawerHistoryKey('durable-9')));
      await tester.pumpAndSettle();

      expect(repository.resumed, <String>['durable-9']);
      final active = container.read(activeSessionProvider);
      expect(active.liveId, 'e5f6a7b8'); // the NEW live id
      expect(active.durableId, 'durable-9');

      // The replayed history was seeded into the new message list.
      final fold = container.read(messageListProvider('e5f6a7b8'));
      expect(fold.messages, hasLength(2));
      expect(fold.messages[1].text, 'hi there');

      expect(find.byType(Drawer), findsNothing); // drawer closed
    },
  );

  testWidgets("'New session' creates, switches, and closes the drawer", (
    tester,
  ) async {
    final container = await pumpDrawer(tester);

    await tester.tap(find.byKey(sessionDrawerNewKey));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    final active = container.read(activeSessionProvider);
    expect(active.liveId, 'a1b2c3d4');
    expect(active.durableId, 'durable-new');
    expect(find.byType(Drawer), findsNothing); // drawer closed
  });

  testWidgets(
    'interrupt is visible while the current live session is working',
    (tester) async {
      repository.activeListResult = const <ActiveSession>[
        ActiveSession(
          liveId: 'aaaa1111',
          status: SessionStatus.working,
          title: 'Live one',
        ),
      ];

      final container = await pumpDrawer(tester);
      switchActiveTo(container, liveId: 'aaaa1111', durableId: 'durable-1');
      await tester.pumpAndSettle();

      final interrupt = find.byKey(sessionDrawerInterruptKey);
      expect(interrupt, findsOneWidget);

      await tester.tap(interrupt);
      await tester.pumpAndSettle();

      expect(repository.interrupted, <String>['aaaa1111']);
      // Interrupt keeps the drawer open.
      expect(find.byType(Drawer), findsOneWidget);
    },
  );

  testWidgets('a failing action shows a dismissible message', (tester) async {
    repository.createError = const GatewayNetworkException('host unreachable');

    await pumpDrawer(tester);

    await tester.tap(find.byKey(sessionDrawerNewKey));
    await tester.pumpAndSettle();

    // The drawer stays open and shows the error.
    expect(find.textContaining('host unreachable'), findsOneWidget);
    expect(find.byType(Drawer), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('host unreachable'), findsNothing);
  });

  testWidgets('a list failure shows a dismissible message', (tester) async {
    repository.listError = const GatewayNetworkException('host unreachable');

    await pumpDrawer(tester);

    expect(find.textContaining('Could not load sessions'), findsOneWidget);
    expect(find.textContaining('host unreachable'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('host unreachable'), findsNothing);
  });

  testWidgets('disconnected renders empty states without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(harness(connected: false));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('No live sessions'), findsOneWidget);
    expect(find.text('No past sessions'), findsOneWidget);
  });

  testWidgets('the footer shows the connected gateway version (P1-16)', (
    tester,
  ) async {
    const status = GatewayStatus(
      version: '0.17.0',
      gatewayRunning: true,
      gatewayState: 'ready',
      gatewayBusy: false,
      activeSessions: 1,
      activeAgents: 1,
      authRequired: false,
      authProviders: <String>[],
    );
    await tester.pumpWidget(harness(gatewayStatus: status));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Gateway v0.17.0'), findsOneWidget);
  });

  testWidgets('the footer is hidden while no gateway status is recorded', (
    tester,
  ) async {
    await pumpDrawer(tester);

    expect(find.textContaining('Gateway v'), findsNothing);
  });
}
