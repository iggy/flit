// P2-05/06/07/08 acceptance: the session info sheet — usage rendering,
// context breakdown, and the four action buttons (compress / undo / save /
// set-cwd).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_info.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/presentation/sessions/session_info_sheet.dart';

/// Fake session actions that records calls.
final class FakeSessionActions implements SessionActions {
  final List<String> compressCalls = <String>[];
  final List<String> undoCalls = <String>[];
  final List<String> saveCalls = <String>[];
  final List<({String liveId, String cwd})> setCwdCalls = <({String liveId, String cwd})>[];

  /// Errors to return (keyed by action name: 'compress', 'undo', 'save', 'setCwd').
  final Map<String, String?> errors = <String, String?>{};

  @override
  Future<String?> compress(String liveId, {String? focusTopic}) async {
    compressCalls.add(liveId);
    return errors['compress'];
  }

  @override
  Future<String?> undo(String liveId) async {
    undoCalls.add(liveId);
    return errors['undo'];
  }

  @override
  Future<String?> save(String liveId) async {
    saveCalls.add(liveId);
    return errors['save'];
  }

  @override
  Future<String?> setCwd(String liveId, String cwd) async {
    setCwdCalls.add((liveId: liveId, cwd: cwd));
    return errors['setCwd'];
  }

  // Unused methods for this test.
  @override
  Future<String?> newSession() async => null;

  @override
  Future<String?> switchToSummary(_) async => null;

  @override
  void switchToLive(_) {}

  @override
  Future<String?> interruptActive() async => null;

  @override
  Future<String?> rename(String liveId, String title) async => null;

  @override
  Future<String?> deleteSession(String durableId) async => null;

  @override
  Future<String?> branchSession(String liveId, {String? name}) async => null;
}

void main() {
  late FakeSessionActions fakeActions;

  setUp(() {
    fakeActions = FakeSessionActions();
  });

  Widget sheetHarness({
    SessionUsageStats? usage,
    ContextBreakdown? breakdown,
    String? activeLiveId,
  }) {
    return ProviderScope(
      overrides: [
        sessionUsageProvider.overrideWith((ref) async => usage),
        contextBreakdownProvider.overrideWith((ref) async => breakdown),
        sessionActionsProvider.overrideWithValue(fakeActions),
        if (activeLiveId != null)
          activeSessionProvider.overrideWith(
                () => _FakeActiveSessionNotifier(
              ActiveSessionState(liveId: activeLiveId),
            ),
          ),
      ],
      child: const MaterialApp(home: Scaffold(body: SessionInfoSheet())),
    );
  }

  Future<void> pumpSheet(WidgetTester tester, Widget harness) async {
    await tester.pumpWidget(harness);
    await tester.pump(); // FutureProviders resolve
  }

  testWidgets('renders usage stats from liveUsageProvider', (tester) async {
    const usage = SessionUsageStats(
      model: 'hermes-4-405b',
      input: 100,
      output: 50,
      total: 150,
      calls: 2,
      contextUsed: 48000,
      contextMax: 128000,
      contextPercent: 38,
    );
    await pumpSheet(
      tester,
      sheetHarness(usage: usage, activeLiveId: 'a1b2c3d4'),
    );

    expect(find.text('hermes-4-405b'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('48000 / 128000 tokens (38%)'), findsOneWidget);
  });

  testWidgets('renders context breakdown when categories present', (tester) async {
    const usage = SessionUsageStats(
      model: 'm',
      input: 10,
      output: 10,
      total: 20,
      calls: 1,
    );
    const breakdown = ContextBreakdown(
      categories: <ContextCategory>[
        ContextCategory(
          id: 'system_prompt',
          label: 'System prompt',
          tokens: 1000,
          color: 'var(--context-usage-system)',
        ),
        ContextCategory(
          id: 'conversation',
          label: 'Conversation',
          tokens: 2000,
          color: 'var(--context-usage-conversation)',
        ),
      ],
      contextMax: 128000,
      contextPercent: 2,
      contextUsed: 3000,
      estimatedTotal: 3000,
      model: 'm',
    );
    await pumpSheet(
      tester,
      sheetHarness(
        usage: usage,
        breakdown: breakdown,
        activeLiveId: 'a1b2c3d4',
      ),
    );

    expect(find.text('Context breakdown'), findsOneWidget);
    expect(find.text('System prompt'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
  });

  testWidgets('renders four action buttons when session is active', (tester) async {
    const usage = SessionUsageStats(
      model: 'm',
      input: 10,
      output: 10,
      total: 20,
      calls: 1,
    );
    await pumpSheet(
      tester,
      sheetHarness(usage: usage, activeLiveId: 'a1b2c3d4'),
    );

    expect(find.byKey(sessionInfoCompressKey), findsOneWidget);
    expect(find.byKey(sessionInfoUndoKey), findsOneWidget);
    expect(find.byKey(sessionInfoSaveKey), findsOneWidget);
    expect(find.byKey(sessionInfoCwdKey), findsOneWidget);
  });

  testWidgets('tapping compress calls actions.compress with live id', (tester) async {
    const usage = SessionUsageStats(
      model: 'm',
      input: 10,
      output: 10,
      total: 20,
      calls: 1,
    );
    await pumpSheet(
      tester,
      sheetHarness(usage: usage, activeLiveId: 'a1b2c3d4'),
    );

    await tester.tap(find.byKey(sessionInfoCompressKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // async handler

    expect(fakeActions.compressCalls, <String>['a1b2c3d4']);
  });

  testWidgets('tapping undo shows confirm dialog, calls actions.undo on confirm', (
    tester,
  ) async {
    const usage = SessionUsageStats(
      model: 'm',
      input: 10,
      output: 10,
      total: 20,
      calls: 1,
    );
    await pumpSheet(
      tester,
      sheetHarness(usage: usage, activeLiveId: 'a1b2c3d4'),
    );

    await tester.tap(find.byKey(sessionInfoUndoKey));
    await tester.pump();
    await tester.pump(); // dialog opens

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Undo last turn?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Undo'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // async handler

    expect(fakeActions.undoCalls, <String>['a1b2c3d4']);
  });

  testWidgets('tapping save calls actions.save with live id', (tester) async {
    const usage = SessionUsageStats(
      model: 'm',
      input: 10,
      output: 10,
      total: 20,
      calls: 1,
    );
    await pumpSheet(
      tester,
      sheetHarness(usage: usage, activeLiveId: 'a1b2c3d4'),
    );

    await tester.tap(find.byKey(sessionInfoSaveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // async handler

    expect(fakeActions.saveCalls, <String>['a1b2c3d4']);
  });

  testWidgets('tapping set cwd shows dialog, calls actions.setCwd on set', (
    tester,
  ) async {
    const usage = SessionUsageStats(
      model: 'm',
      input: 10,
      output: 10,
      total: 20,
      calls: 1,
    );
    await pumpSheet(
      tester,
      sheetHarness(usage: usage, activeLiveId: 'a1b2c3d4'),
    );

    await tester.tap(find.byKey(sessionInfoCwdKey));
    await tester.pump();
    await tester.pump(); // dialog opens

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '/home/user/project');
    await tester.tap(find.widgetWithText(FilledButton, 'Set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // async handler

    expect(
      fakeActions.setCwdCalls,
      <({String liveId, String cwd})>[(liveId: 'a1b2c3d4', cwd: '/home/user/project')],
    );
  });
}

/// Fake active session notifier for overriding activeSessionProvider.
class _FakeActiveSessionNotifier extends ActiveSessionNotifier {
  _FakeActiveSessionNotifier(this._state);

  final ActiveSessionState _state;

  @override
  ActiveSessionState build() => _state;
}
