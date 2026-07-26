// P1-06 acceptance: the PURE event fold, tested hard.
//
// Case 1 feeds the EXACT frame sequence from test/fixtures/turn_basic.jsonl
// (the canonical turn, mirroring docs/reference/03-mvp-wire-shapes.md §7)
// through parseGatewayEvent → foldGatewayEvent and asserts the resulting
// message list. The rest cover terminal-error/interrupt, mid-turn
// interactive prompts, and the documented defensive edge cases.

import 'dart:convert';
import 'dart:io';

import 'package:flit/application/chat/message_fold.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/domain/models/usage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decode a full event frame the way the RPC client's router does
/// (protocol §3c): params.type / params.session_id / params.payload.
GatewayEvent _eventFromFrame(String frame) {
  final decoded = jsonDecode(frame) as Map<String, dynamic>;
  final params = decoded['params'] as Map<String, dynamic>;
  final payload = params['payload'];
  return GatewayEvent(
    type: params['type'] as String,
    sessionId: params['session_id'] as String?,
    payload: payload is Map<String, dynamic> ? payload : <String, dynamic>{},
  );
}

FoldState _foldAll(FoldState state, Iterable<TypedGatewayEvent> events) {
  var next = state;
  for (final event in events) {
    next = foldGatewayEvent(next, event);
  }
  return next;
}

void main() {
  const sid = 'a1b2c3d4';
  const empty = FoldState();

  test('fixture turn_basic.jsonl folds to one resolved assistant turn', () {
    // The EXACT recorded frame sequence — including the leading
    // gateway.ready (null session) and trailing session.info, which the
    // fold must pass through unchanged.
    final lines = File(
      'test/fixtures/turn_basic.jsonl',
    ).readAsLinesSync().where((line) => line.trim().isNotEmpty);
    final events = lines.map(
      (line) => parseGatewayEvent(_eventFromFrame(line)),
    );

    final state = _foldAll(empty, events);

    // Exactly ONE assistant message: deltas accumulated, tool resolved,
    // finalized by message.complete. No prompt was issued.
    expect(state.pendingPrompts, isEmpty);
    expect(state.messages, hasLength(1));

    final message = state.messages.single;
    expect(message.role, MessageRole.assistant);
    // message.complete.text is the authoritative final text (protocol §5).
    expect(message.text, "I'll list them. There is 1 file.");
    expect(message.streaming, isFalse);
    expect(message.terminalStatus, MessageTerminalStatus.complete);
    // usage from message.complete.payload.usage is recorded on the message.
    expect(message.usage, const Usage(input: 1200, output: 42, costUsd: 0.003));

    // The interleaved tool call resolved done with its full result.
    expect(message.toolCalls, hasLength(1));
    final tool = message.toolCalls.single;
    expect(tool.id, 't1');
    expect(tool.name, 'shell');
    expect(tool.context, 'ls -la');
    expect(tool.status, ToolCallStatus.done);
    // tool.complete.result is polymorphic (protocol §7) — here a dict.
    expect(tool.result, isA<Map<String, dynamic>>());
    final result = tool.result as Map<String, dynamic>;
    expect(result['stdout'], 'README.md\n');
    expect(result['code'], 0);
    expect(tool.summary, '1 file');
    expect(tool.durationS, 0.12);
  });

  test('a turn ending in TurnError finalizes with status error', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.messageDelta(sessionId: sid, text: 'Partial answer'),
      TypedGatewayEvent.turnError(sessionId: sid, message: 'model blew up'),
    ]);

    final message = state.messages.single;
    expect(message.streaming, isFalse);
    expect(message.terminalStatus, MessageTerminalStatus.error);
    // The gateway's error message is appended to the accumulated text.
    expect(message.text, 'Partial answer\n\nmodel blew up');
    expect(message.usage, isNull);
  });

  test("message.complete with status 'interrupted' mid-stream", () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.messageDelta(sessionId: sid, text: 'Half an ans'),
      TypedGatewayEvent.messageComplete(
        sessionId: sid,
        text: 'Half an ans',
        status: MessageTerminalStatus.interrupted,
      ),
    ]);

    final message = state.messages.single;
    expect(message.streaming, isFalse);
    expect(message.terminalStatus, MessageTerminalStatus.interrupted);
    expect(message.text, 'Half an ans');
  });

  test('approval.request mid-turn surfaces an ApprovalPrompt out-of-band', () {
    // Verbatim wire §10 payload fields.
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.approvalRequest(
        sessionId: sid,
        command: 'rm -rf build/',
        description: 'Delete build dir',
        patternKey: 'rm',
        patternKeys: <String>['rm'],
        allowPermanent: true,
      ),
    ]);

    // Interactive prompts are NOT chat messages — the list is untouched
    // apart from the streaming turn message.
    expect(state.messages, hasLength(1));
    expect(state.messages.single.streaming, isTrue);

    expect(state.pendingPrompts, hasLength(1));
    final prompt = state.pendingPrompts.single;
    expect(prompt, isA<ApprovalPrompt>());
    final approval = prompt as ApprovalPrompt;
    expect(approval.sessionId, sid);
    expect(approval.command, 'rm -rf build/');
    expect(approval.description, 'Delete build dir');
    expect(approval.patternKey, 'rm');
    expect(approval.patternKeys, <String>['rm']);
    expect(approval.allowPermanent, isTrue);
  });

  test('clarify.request surfaces a ClarifyPrompt out-of-band', () {
    // Verbatim wire §11 payload fields.
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.clarifyRequest(
        sessionId: sid,
        question: 'Which environment?',
        choices: <String>['staging', 'prod'],
        requestId: '9f3a1c2b',
      ),
    ]);

    expect(state.messages, hasLength(1));
    expect(state.pendingPrompts, hasLength(1));
    final prompt = state.pendingPrompts.single;
    expect(prompt, isA<ClarifyPrompt>());
    final clarify = prompt as ClarifyPrompt;
    expect(clarify.sessionId, sid);
    expect(clarify.question, 'Which environment?');
    expect(clarify.choices, <String>['staging', 'prod']);
    expect(clarify.requestId, '9f3a1c2b');
  });

  test('sudo.request surfaces a SudoPrompt out-of-band (P3-08)', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.sudoRequest(sessionId: sid, requestId: '9f3a1c2b'),
    ]);

    expect(state.messages, hasLength(1));
    expect(state.pendingPrompts, hasLength(1));
    final prompt = state.pendingPrompts.single;
    expect(prompt, isA<SudoPrompt>());
    final sudo = prompt as SudoPrompt;
    expect(sudo.sessionId, sid);
    expect(sudo.requestId, '9f3a1c2b');
  });

  test('secret.request surfaces a SecretPrompt out-of-band (P3-08)', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.secretRequest(
        sessionId: sid,
        envVar: 'OPENAI_API_KEY',
        prompt: 'Enter your API key',
        requestId: '9f3a1c2b',
      ),
    ]);

    expect(state.messages, hasLength(1));
    expect(state.pendingPrompts, hasLength(1));
    final prompt = state.pendingPrompts.single;
    expect(prompt, isA<SecretPrompt>());
    final secret = prompt as SecretPrompt;
    expect(secret.sessionId, sid);
    expect(secret.envVar, 'OPENAI_API_KEY');
    expect(secret.prompt, 'Enter your API key');
    expect(secret.requestId, '9f3a1c2b');
  });

  test(
    'terminal.read.request surfaces a TerminalReadPrompt out-of-band (P3-08)',
    () {
      final state = _foldAll(empty, const <TypedGatewayEvent>[
        TypedGatewayEvent.messageStart(sessionId: sid),
        TypedGatewayEvent.terminalReadRequest(
          sessionId: sid,
          requestId: '9f3a1c2b',
          start: 10,
          count: 20,
        ),
      ]);

      expect(state.messages, hasLength(1));
      expect(state.pendingPrompts, hasLength(1));
      final prompt = state.pendingPrompts.single;
      expect(prompt, isA<TerminalReadPrompt>());
      final termRead = prompt as TerminalReadPrompt;
      expect(termRead.sessionId, sid);
      expect(termRead.requestId, '9f3a1c2b');
      expect(termRead.start, 10);
      expect(termRead.count, 20);
    },
  );

  test('tool.complete for an unknown toolId is a no-op, never crashes', () {
    const before = FoldState(
      messages: <ChatMessage>[
        ChatMessage(
          role: MessageRole.assistant,
          text: 'working…',
          streaming: true,
          toolCalls: <ToolCall>[ToolCall(id: 't1', name: 'shell')],
        ),
      ],
    );

    final state = _foldAll(before, const <TypedGatewayEvent>[
      TypedGatewayEvent.toolComplete(
        sessionId: sid,
        toolId: 'no-such-tool',
        name: 'shell',
        result: 'x',
      ),
    ]);

    // Documented behavior: the orphan completion is DROPPED; the existing
    // tool call stays running; nothing else changes.
    expect(state, before);
    expect(
      state.messages.single.toolCalls.single.status,
      ToolCallStatus.running,
    );
  });

  test('deltas before any message.start create a streaming message', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageDelta(sessionId: sid, text: 'orphan'),
    ]);

    // Documented defensive behavior: rather than dropping text (or
    // crashing), a fresh streaming assistant message carries it.
    expect(state.messages, hasLength(1));
    final message = state.messages.single;
    expect(message.role, MessageRole.assistant);
    expect(message.streaming, isTrue);
    expect(message.text, 'orphan');
  });

  test('a new turn after a finalized one APPENDS, never merges', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.messageDelta(sessionId: sid, text: 'first'),
      TypedGatewayEvent.messageComplete(
        sessionId: sid,
        text: 'first',
        status: MessageTerminalStatus.complete,
      ),
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.messageDelta(sessionId: sid, text: 'second'),
    ]);

    expect(state.messages, hasLength(2));
    expect(state.messages[0].terminalStatus, MessageTerminalStatus.complete);
    expect(state.messages[0].text, 'first');
    expect(state.messages[1].streaming, isTrue);
    expect(state.messages[1].text, 'second');
  });

  test('tool.start attaches a running ToolCall; complete resolves by id', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.toolStart(
        sessionId: sid,
        toolId: 't1',
        name: 'shell',
        context: 'ls -la',
      ),
      TypedGatewayEvent.toolStart(
        sessionId: sid,
        toolId: 't2',
        name: 'read_file',
      ),
      // Completing t2 must not touch t1.
      TypedGatewayEvent.toolComplete(
        sessionId: sid,
        toolId: 't2',
        name: 'read_file',
        result: 'raw string result',
        error: 'boom',
      ),
    ]);

    final tools = state.messages.single.toolCalls;
    expect(tools, hasLength(2));
    expect(tools[0].status, ToolCallStatus.running);
    // error != null → status error; result still recorded.
    expect(tools[1].status, ToolCallStatus.error);
    expect(tools[1].result, 'raw string result');
  });

  test('tool.progress updates the matching running tool context by name', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.toolStart(
        sessionId: sid,
        toolId: 't1',
        name: 'shell',
        context: 'npm test',
      ),
      TypedGatewayEvent.toolProgress(
        sessionId: sid,
        name: 'shell',
        preview: '12/40 tests',
      ),
      // Unknown tool name → no-op.
      TypedGatewayEvent.toolProgress(
        sessionId: sid,
        name: 'other_tool',
        preview: 'ignored',
      ),
    ]);

    final tool = state.messages.single.toolCalls.single;
    // Documented behavior: tool.progress carries no tool_id, so the last
    // running tool with a matching name gets context := preview.
    expect(tool.context, '12/40 tests');
    expect(tool.status, ToolCallStatus.running);
  });

  test(
    'user messages appended by the caller are never touched by the fold',
    () {
      const withUser = FoldState(
        messages: <ChatMessage>[
          ChatMessage(role: MessageRole.user, text: 'do the thing'),
        ],
      );

      final state = _foldAll(withUser, const <TypedGatewayEvent>[
        TypedGatewayEvent.messageStart(sessionId: sid),
        TypedGatewayEvent.messageDelta(sessionId: sid, text: 'on it'),
      ]);

      expect(state.messages, hasLength(2));
      expect(state.messages[0].role, MessageRole.user);
      expect(state.messages[0].text, 'do the thing');
      expect(state.messages[1].text, 'on it');
    },
  );

  test('session.info / status.update / unknown events pass through', () {
    const before = FoldState(
      messages: <ChatMessage>[
        ChatMessage(
          role: MessageRole.assistant,
          text: 'streaming…',
          streaming: true,
        ),
      ],
    );

    final state = _foldAll(before, const <TypedGatewayEvent>[
      TypedGatewayEvent.sessionInfo(
        sessionId: sid,
        info: <String, dynamic>{'running': false},
      ),
      TypedGatewayEvent.statusUpdate(
        sessionId: sid,
        kind: 'tool',
        text: 'working',
      ),
      TypedGatewayEvent.gatewayReady(skin: <String, dynamic>{}),
      TypedGatewayEvent.unknown(
        type: 'moa.reference',
        sessionId: sid,
        payload: <String, dynamic>{},
      ),
    ]);

    expect(state, before);
  });

  test('delta rendered supersedes only when present', () {
    final state = _foldAll(empty, const <TypedGatewayEvent>[
      TypedGatewayEvent.messageStart(sessionId: sid),
      TypedGatewayEvent.messageDelta(
        sessionId: sid,
        text: 'a',
        rendered: '<p>a</p>',
      ),
      TypedGatewayEvent.messageDelta(sessionId: sid, text: 'b'),
    ]);

    final message = state.messages.single;
    expect(message.text, 'ab');
    expect(message.rendered, '<p>a</p>');
  });
}
