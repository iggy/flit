import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flutter_test/flutter_test.dart';

/// A realistic turn as a flit server logs it: user message, an assistant
/// message that calls shell (with a prompt answered by another client), then
/// the final answer.
List<FlitEvent> turn() {
  var seq = 0;
  int n() => ++seq;
  return <FlitEvent>[
    FlitMessageStarted(seq: n(), messageId: 'u1', role: FlitRole.user),
    FlitTextDelta(seq: n(), messageId: 'u1', text: 'run the tests'),
    FlitMessageDone(
      seq: n(),
      messageId: 'u1',
      text: 'run the tests',
      reasoning: '',
      finishReason: 'stop',
    ),
    FlitTaskStateChanged(seq: n(), state: FlitTaskState.working, reason: ''),
    FlitMessageStarted(seq: n(), messageId: 'a1', role: FlitRole.assistant),
    FlitReasoningDelta(seq: n(), messageId: 'a1', text: 'need go test'),
    FlitMessageDone(
      seq: n(),
      messageId: 'a1',
      text: '',
      reasoning: 'need go test',
      finishReason: 'tool_calls',
    ),
    FlitUsage(seq: n(), messageId: 'a1', inputTokens: 100, outputTokens: 7),
    FlitToolCallStarted(
      seq: n(),
      messageId: 'a1',
      toolCallId: 't1',
      name: 'shell',
      arguments: '{"command":"go test ./..."}',
    ),
    FlitPromptRequested(
      seq: n(),
      promptId: 'p1',
      toolCallId: 't1',
      title: 'Run shell command',
      detail: 'go test ./...',
    ),
    FlitTaskStateChanged(seq: n(), state: FlitTaskState.waiting, reason: ''),
    FlitPromptResolved(
      seq: n(),
      promptId: 'p1',
      allowed: true,
      client: 'phone',
      reason: '',
    ),
    FlitTaskStateChanged(seq: n(), state: FlitTaskState.working, reason: ''),
    FlitToolOutput(seq: n(), toolCallId: 't1', text: 'ok  pkg\n'),
    FlitToolCallDone(
      seq: n(),
      toolCallId: 't1',
      result: 'ok  pkg\n[exit code 0]',
      isError: false,
      truncated: false,
    ),
    FlitMessageStarted(seq: n(), messageId: 'a2', role: FlitRole.assistant),
    FlitTextDelta(seq: n(), messageId: 'a2', text: 'All '),
    FlitTextDelta(seq: n(), messageId: 'a2', text: 'pass.'),
    FlitMessageDone(
      seq: n(),
      messageId: 'a2',
      text: 'All pass.',
      reasoning: '',
      finishReason: 'stop',
    ),
    FlitTaskStateChanged(seq: n(), state: FlitTaskState.done, reason: ''),
  ];
}

void main() {
  test('folds a full turn into chat messages', () {
    final state = foldFlitEvents(const FlitFoldState(), turn());

    expect(state.lastSeq, 20);
    expect(state.taskState, FlitTaskState.done);
    expect(state.prompts, isEmpty);
    expect(state.messages, hasLength(3));

    final user = state.messages[0];
    expect(user.role, MessageRole.user);
    expect(user.text, 'run the tests');
    expect(user.streaming, isFalse);

    final call = state.messages[1];
    expect(call.role, MessageRole.assistant);
    expect(call.reasoning, 'need go test');
    expect(call.terminalStatus, MessageTerminalStatus.complete);
    expect(call.usage?.input, 100);
    expect(call.toolCalls, hasLength(1));
    final tool = call.toolCalls.single;
    expect(tool.name, 'shell');
    expect(tool.context, 'go test ./...');
    expect(tool.status, ToolCallStatus.done);
    expect(tool.result, 'ok  pkg\n[exit code 0]');

    final answer = state.messages[2];
    expect(answer.text, 'All pass.');
    expect(answer.streaming, isFalse);
  });

  test('streams deltas into an open message', () {
    final events = turn();
    final mid = foldFlitEvents(const FlitFoldState(), events.take(17));
    final last = mid.messages.last;
    expect(last.text, 'All ');
    expect(last.streaming, isTrue);
    expect(mid.busy, isTrue);
  });

  test('a prompt is pending until resolved, from any client', () {
    final events = turn();
    final waiting = foldFlitEvents(const FlitFoldState(), events.take(11));
    expect(waiting.taskState, FlitTaskState.waiting);
    expect(waiting.prompts.single.promptId, 'p1');
    expect(waiting.prompts.single.detail, 'go test ./...');

    final answered = foldFlitEvent(waiting, events[11]);
    expect(answered.prompts, isEmpty);
  });

  test('live tool output shows while the tool runs', () {
    final events = turn();
    final running = foldFlitEvents(const FlitFoldState(), events.take(14));
    final tool = running.messages[1].toolCalls.single;
    expect(tool.status, ToolCallStatus.running);
    expect(tool.result, 'ok  pkg\n');
  });

  test('replaying from any point converges on the same state', () {
    final events = turn();
    final once = foldFlitEvents(const FlitFoldState(), events);
    for (var cut = 0; cut <= events.length; cut++) {
      // A client that saw [0, cut) reattaches and the server replays an
      // overlapping window: everything from 1 again.
      final partial = foldFlitEvents(const FlitFoldState(), events.take(cut));
      final resumed = foldFlitEvents(partial, events);
      expect(resumed, once, reason: 'cut at $cut');
    }
  });

  test('duplicates and old events are ignored', () {
    final events = turn();
    final state = foldFlitEvents(const FlitFoldState(), events);
    expect(foldFlitEvent(state, events[16]), same(state));
    expect(foldFlitEvents(state, events.reversed), state);
  });

  test('interrupted and error endings', () {
    final interrupted = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitMessageStarted(
        seq: 1,
        messageId: 'a',
        role: FlitRole.assistant,
      ),
      const FlitTextDelta(seq: 2, messageId: 'a', text: 'partial'),
      const FlitMessageDone(
        seq: 3,
        messageId: 'a',
        text: 'partial',
        reasoning: '',
        finishReason: 'interrupted',
      ),
      const FlitTaskStateChanged(
        seq: 4,
        state: FlitTaskState.done,
        reason: 'interrupted',
      ),
    ]);
    expect(
      interrupted.messages.single.terminalStatus,
      MessageTerminalStatus.interrupted,
    );
    expect(interrupted.taskReason, 'interrupted');

    final failed = foldFlitEvent(
      interrupted,
      const FlitTurnError(seq: 5, message: 'HTTP 503', canContinue: true),
    );
    expect(failed.messages.last.role, MessageRole.system);
    expect(failed.messages.last.terminalStatus, MessageTerminalStatus.error);
    expect(failed.messages.last.text, contains('HTTP 503'));
  });

  test('a finished turn clears leftover prompts', () {
    final state = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitPromptRequested(
        seq: 1,
        promptId: 'p',
        toolCallId: 't',
        title: 'x',
        detail: 'y',
      ),
      const FlitTaskStateChanged(
        seq: 2,
        state: FlitTaskState.stuck,
        reason: '',
      ),
    ]);
    expect(state.prompts, isEmpty);
  });

  test('model changes and unknown events', () {
    final state = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      const FlitModelChanged(seq: 1, provider: 'local', model: 'qwen'),
      const FlitUnknownEvent(seq: 2),
    ]);
    expect(state.provider, 'local');
    expect(state.model, 'qwen');
    expect(state.lastSeq, 2);
  });

  test('toolContext summarizes arguments', () {
    expect(toolContext('shell', '{"command":"ls -la"}'), 'ls -la');
    expect(toolContext('read', '{"path":"a.go"}'), 'a.go');
    expect(toolContext('grep', '{"pattern":"foo","path":"lib"}'), 'foo in lib');
    expect(toolContext('list', '{}'), '.');
    expect(toolContext('read', 'not json'), isNull);
  });
}
