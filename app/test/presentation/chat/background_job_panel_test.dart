import 'package:flit/domain/models/background_job.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/presentation/chat/background_job_panel.dart';
import 'package:flit/presentation/chat/tool_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Future<void> Function(String)? onCancel}) {
  final body = onCancel == null
      ? child
      : BackgroundJobActions(onCancel: onCancel, child: child);
  return MaterialApp(home: Scaffold(body: body));
}

const ToolCall _call = ToolCall(
  id: 'sh1',
  name: 'shell',
  context: 'make serve',
  status: ToolCallStatus.done,
  job: BackgroundJob(id: 'job_1', command: 'make serve', output: 'listening\n'),
);

void main() {
  testWidgets('a running job shows its status, output and cancel', (
    tester,
  ) async {
    final cancelled = <String>[];
    await tester.pumpWidget(
      _host(
        const ToolCallCard(tool: _call),
        onCancel: (id) async => cancelled.add(id),
      ),
    );
    expect(find.text('job_1 · running in the background'), findsOneWidget);
    expect(find.text('listening'), findsNothing);
    await tester.tap(find.text('job_1 · running in the background'));
    await tester.pump();
    expect(find.text('listening'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('${backgroundJobCancelKeyPrefix}job_1')),
    );
    await tester.pump();
    expect(cancelled, <String>['job_1']);
  });

  testWidgets('no cancel without actions or once ended', (tester) async {
    await tester.pumpWidget(_host(const ToolCallCard(tool: _call)));
    expect(find.text('Cancel'), findsNothing);

    await tester.pumpWidget(
      _host(
        ToolCallCard(
          tool: _call.copyWith(
            job: _call.job!.copyWith(
              status: BackgroundJobStatus.cancelled,
              cancelledBy: 'phone',
              duration: const Duration(minutes: 2, seconds: 5),
            ),
          ),
        ),
        onCancel: (_) async {},
      ),
    );
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('job_1 · cancelled by phone after 2m 5s'), findsOneWidget);
  });

  test('status text', () {
    String text(BackgroundJob j) => backgroundJobStatusText(j);
    const j = BackgroundJob(id: 'job_2', detached: true);
    expect(text(j), 'job_2 · ran long, still running in the background');
    expect(
      text(
        j.copyWith(
          status: BackgroundJobStatus.exited,
          exitCode: 1,
          duration: const Duration(seconds: 9),
        ),
      ),
      'job_2 · exited with code 1 after 9s',
    );
    expect(
      text(j.copyWith(status: BackgroundJobStatus.lost)),
      'job_2 · killed: flit stopped while it ran',
    );
  });
}
