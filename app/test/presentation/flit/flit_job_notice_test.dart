import 'package:flit/presentation/flit/flit_job_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a notice shows its summaries and expands to all of it', (
    tester,
  ) async {
    const text =
        '[flit notice] A background job ended:\n'
        '- job_1 (make test): exited with code 2 after 1m15s\n'
        '  Last output:\n'
        '    FAIL 2\n'
        'Use the job tool (action status) to see all of a job\'s output.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FlitJobNoticeView(text: text)),
      ),
    );
    expect(find.text('Background job ended'), findsOneWidget);
    expect(
      find.text('job_1 (make test): exited with code 2 after 1m15s'),
      findsOneWidget,
    );
    expect(find.textContaining('FAIL 2'), findsNothing);
    await tester.tap(find.text('Background job ended'));
    await tester.pump();
    expect(find.textContaining('FAIL 2'), findsOneWidget);
  });
}
