import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/presentation/flit/flit_call_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 18, 17);
  late DateTime now;
  var retries = 0;
  var stops = 0;

  Future<void> pump(WidgetTester tester, FlitPendingCall call) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitCallStatus(
            call: call,
            now: () => now,
            onRetry: () => retries++,
            onStop: () => stops++,
          ),
        ),
      ),
    );
  }

  setUp(() {
    retries = 0;
    stops = 0;
  });

  test('clock', () {
    expect(flitClock(const Duration(seconds: 5)), '0:05');
    expect(flitClock(const Duration(minutes: 2, seconds: 3)), '2:03');
    expect(
      flitClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(flitClock(const Duration(seconds: -4)), '0:00');
  });

  testWidgets('waiting, then reading the prompt, then no response', (
    tester,
  ) async {
    now = t0.add(const Duration(seconds: 12));
    await pump(
      tester,
      FlitPendingCall(messageId: 'a', attempt: 1, startedAt: t0),
    );
    expect(find.text('Waiting for the model · 0:12'), findsOneWidget);
    expect(find.byKey(flitCallRetryKey), findsNothing);

    now = t0.add(const Duration(seconds: 40));
    await pump(
      tester,
      FlitPendingCall(
        messageId: 'a',
        attempt: 1,
        startedAt: t0,
        lastActivity: t0.add(const Duration(seconds: 39)),
        processed: 12000,
        total: 48000,
      ),
    );
    expect(
      find.text('Reading the prompt: 12000 of 48000 tokens · 0:40'),
      findsOneWidget,
    );

    now = t0.add(const Duration(seconds: 75));
    await pump(
      tester,
      FlitPendingCall(messageId: 'a', attempt: 2, startedAt: t0),
    );
    expect(
      find.text("The model hasn't responded for 1:15 (attempt 2)"),
      findsOneWidget,
    );
    await tester.tap(find.byKey(flitCallRetryKey));
    await tester.tap(find.byKey(flitCallStopKey));
    expect(retries, 1);
    expect(stops, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a streaming reply shows nothing until it goes quiet', (
    tester,
  ) async {
    now = t0.add(const Duration(seconds: 30));
    final streaming = FlitPendingCall(
      messageId: 'a',
      attempt: 1,
      startedAt: t0,
      lastActivity: t0.add(const Duration(seconds: 29)),
      hasOutput: true,
    );
    await pump(tester, streaming);
    expect(find.byKey(flitCallStatusKey), findsNothing);

    now = t0.add(const Duration(seconds: 120));
    await pump(tester, streaming);
    expect(find.text('No new output from the model for 1:31'), findsOneWidget);
    // Once the reply has started it can't be resent; only Stop.
    expect(find.byKey(flitCallRetryKey), findsNothing);
    expect(find.byKey(flitCallStopKey), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
