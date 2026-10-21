import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/models/subagent.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flutter_test/flutter_test.dart';

/// A turn where the agent runs a build subagent that asks to run a command.
List<FlitEvent> subagentTurn() {
  var seq = 0;
  int n() => ++seq;
  FlitEvent sub(FlitEvent Function(int seq) e) {
    final s = n();
    return FlitSubagentEvent(seq: s, toolCallId: 'ag1', event: e(s));
  }

  return <FlitEvent>[
    FlitMessageStarted(seq: n(), messageId: 'u1', role: FlitRole.user),
    FlitMessageDone(
      seq: n(),
      messageId: 'u1',
      text: 'fix it',
      reasoning: '',
      finishReason: 'stop',
    ),
    FlitTaskStateChanged(seq: n(), state: FlitTaskState.working, reason: ''),
    FlitMessageStarted(seq: n(), messageId: 'a1', role: FlitRole.assistant),
    FlitMessageDone(
      seq: n(),
      messageId: 'a1',
      text: '',
      reasoning: '',
      finishReason: 'tool_calls',
    ),
    FlitToolCallStarted(
      seq: n(),
      messageId: 'a1',
      toolCallId: 'ag1',
      name: 'agent',
      arguments: '{"kind":"build","task":"fix the test"}',
    ),
    FlitSubagentStarted(
      seq: n(),
      toolCallId: 'ag1',
      kind: SubagentKind.build,
      provider: 'local',
      model: 'small',
      task: 'fix the test',
      maxSteps: 20,
    ),
    sub(
      (s) => FlitMessageStarted(seq: s, messageId: 's0', role: FlitRole.user),
    ),
    sub(
      (s) => FlitMessageDone(
        seq: s,
        messageId: 's0',
        text: 'fix the test',
        reasoning: '',
        finishReason: 'stop',
      ),
    ),
    sub(
      (s) =>
          FlitMessageStarted(seq: s, messageId: 's1', role: FlitRole.assistant),
    ),
    sub((s) => FlitTextDelta(seq: s, messageId: 's1', text: 'running')),
    sub(
      (s) => FlitMessageDone(
        seq: s,
        messageId: 's1',
        text: 'running',
        reasoning: '',
        finishReason: 'tool_calls',
      ),
    ),
    sub(
      (s) => FlitToolCallStarted(
        seq: s,
        messageId: 's1',
        toolCallId: 'sh1',
        name: 'shell',
        arguments: '{"command":"go test"}',
      ),
    ),
    // Its prompt and safety check are the session's own events.
    FlitPermissionCheck(
      seq: n(),
      toolCallId: 'sh1',
      command: 'go test',
      verdict: FlitPermissionVerdict.ask,
    ),
    FlitPromptRequested(
      seq: n(),
      promptId: 'p1',
      toolCallId: 'sh1',
      title: 'Run shell command',
      detail: 'go test',
    ),
  ];
}

List<FlitEvent> subagentEnd(int from) {
  var seq = from;
  int n() => ++seq;
  return <FlitEvent>[
    FlitPromptResolved(
      seq: n(),
      promptId: 'p1',
      allowed: true,
      client: 'phone',
      reason: '',
    ),
    FlitSubagentEvent(
      seq: n(),
      toolCallId: 'ag1',
      event: FlitToolCallDone(
        seq: seq,
        toolCallId: 'sh1',
        result: 'ok',
        isError: false,
        truncated: false,
      ),
    ),
    FlitSubagentDone(
      seq: n(),
      toolCallId: 'ag1',
      status: SubagentStatus.done,
      report: 'Fixed foo_test.go.',
      steps: 2,
    ),
    FlitToolCallDone(
      seq: n(),
      toolCallId: 'ag1',
      result: 'Fixed foo_test.go.',
      isError: false,
      truncated: false,
    ),
  ];
}

void main() {
  test('a subagent folds into its tool call, not the chat', () {
    final events = subagentTurn();
    final mid = foldFlitEvents(const FlitFoldState(), events);
    expect(mid.messages, hasLength(2));
    final call = mid.messages[1].toolCalls.single;
    expect(call.context, 'fix the test');
    final a = call.subagent!;
    expect(a.kind, SubagentKind.build);
    expect(a.model, 'small');
    expect(a.status, SubagentStatus.running);
    expect(a.transcript, hasLength(2));
    expect(a.transcript[1].text, 'running');
    final child = a.transcript[1].toolCalls.single;
    expect(child.id, 'sh1');
    expect(child.summary, 'safety check: ask');
    // The subagent's prompt shows like any other.
    expect(mid.prompts.single.toolCallId, 'sh1');

    final end = foldFlitEvents(mid, subagentEnd(events.last.seq));
    final done = end.messages[1].toolCalls.single;
    expect(done.status, ToolCallStatus.done);
    expect(done.subagent!.status, SubagentStatus.done);
    expect(done.subagent!.report, 'Fixed foo_test.go.');
    expect(done.subagent!.steps, 2);
    expect(
      done.subagent!.transcript[1].toolCalls.single.status,
      ToolCallStatus.done,
    );
    expect(end.prompts, isEmpty);
    expect(
      end.messages.where((m) => m.role == MessageRole.assistant),
      hasLength(1),
    );
  });

  test('replaying the log twice changes nothing', () {
    final events = <FlitEvent>[
      ...subagentTurn(),
      ...subagentEnd(subagentTurn().last.seq),
    ];
    final once = foldFlitEvents(const FlitFoldState(), events);
    expect(foldFlitEvents(once, events), once);
  });
}
