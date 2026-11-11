import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/background_job.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flutter_test/flutter_test.dart';

/// A turn that starts a background job, which ends after the turn; its
/// notice starts the next turn.
List<FlitEvent> jobTurn() {
  var seq = 0;
  int n() => ++seq;
  FlitEvent done(String id, String text, String finish) => FlitMessageDone(
    seq: n(),
    messageId: id,
    text: text,
    reasoning: '',
    finishReason: finish,
  );

  return <FlitEvent>[
    FlitMessageStarted(seq: n(), messageId: 'u1', role: FlitRole.user),
    done('u1', 'serve it', 'stop'),
    FlitMessageStarted(seq: n(), messageId: 'a1', role: FlitRole.assistant),
    done('a1', '', 'tool_calls'),
    FlitToolCallStarted(
      seq: n(),
      messageId: 'a1',
      toolCallId: 'sh1',
      name: 'shell',
      arguments: '{"command":"make test","background":true}',
    ),
    FlitJobStarted(
      seq: n(),
      jobId: 'job_1',
      toolCallId: 'sh1',
      command: 'make test',
    ),
    FlitToolCallDone(
      seq: n(),
      toolCallId: 'sh1',
      result: '[started in the background as job job_1]',
      isError: false,
      truncated: false,
    ),
    FlitJobOutput(seq: n(), jobId: 'job_1', text: 'ok 1\n'),
    FlitMessageStarted(seq: n(), messageId: 'a2', role: FlitRole.assistant),
    done('a2', 'started', 'stop'),
    FlitJobOutput(seq: n(), jobId: 'job_1', text: 'FAIL 2\n'),
    FlitJobDone(
      seq: n(),
      jobId: 'job_1',
      status: BackgroundJobStatus.exited,
      exitCode: 2,
      outputTail: 'ok 1\nFAIL 2\n',
      duration: const Duration(seconds: 75),
    ),
    FlitJobNoticeDelivered(
      seq: n(),
      jobIds: const <String>['job_1'],
      messageId: 'n1',
    ),
    FlitMessageStarted(seq: n(), messageId: 'n1', role: FlitRole.user),
    done(
      'n1',
      '[flit notice] A background job ended:\n- job_1 (make test): exited with code 2 after 1m15s',
      'stop',
    ),
  ];
}

ToolCall shellCall(FlitFoldState s) =>
    s.messages.expand((m) => m.toolCalls).firstWhere((t) => t.id == 'sh1');

void main() {
  test(
    'a background job shows on its shell call, and its notice is marked',
    () {
      final s = foldFlitEvents(const FlitFoldState(), jobTurn());
      final job = shellCall(s).job!;
      expect(job.id, 'job_1');
      expect(job.command, 'make test');
      expect(job.status, BackgroundJobStatus.exited);
      expect(job.exitCode, 2);
      expect(job.failed, isTrue);
      expect(job.output, 'ok 1\nFAIL 2\n');
      expect(job.duration, const Duration(seconds: 75));
      // The call itself finished when the job started.
      expect(shellCall(s).status, ToolCallStatus.done);
      expect(s.notices, <String>{'n1'});
    },
  );

  test('while the job runs its live output accumulates', () {
    final events = jobTurn();
    final running = foldFlitEvents(
      const FlitFoldState(),
      events.where((e) => e is! FlitJobDone && e.seq < 12),
    );
    final job = shellCall(running).job!;
    expect(job.running, isTrue);
    expect(job.output, 'ok 1\nFAIL 2\n');
  });

  test('replay without live output still shows the tail; idempotent', () {
    final events = jobTurn();
    final noLive = foldFlitEvents(
      const FlitFoldState(),
      events.where((e) => e is! FlitJobOutput),
    );
    expect(shellCall(noLive).job!.output, 'ok 1\nFAIL 2\n');

    final all = foldFlitEvents(const FlitFoldState(), events);
    final again = foldFlitEvents(all, events);
    expect(again, all);
  });

  test('a notice the agent saw itself marks no message', () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitJobNoticeDelivered(seq: 1, jobIds: <String>['job_1']),
    ]);
    expect(s.notices, isEmpty);
  });

  test('job events are session-wide', () {
    expect(
      flitSessionWide(
        const FlitJobDone(
          seq: 1,
          jobId: 'job_1',
          status: BackgroundJobStatus.cancelled,
        ),
      ),
      isTrue,
    );
    expect(
      flitSessionWide(const FlitJobNoticeDelivered(seq: 1, jobIds: <String>[])),
      isFalse,
    );
  });
}
