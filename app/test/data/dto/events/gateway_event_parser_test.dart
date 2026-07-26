// P1-03 acceptance: parse EVERY example event frame from
// docs/reference/03-mvp-wire-shapes.md §1, §7, §10, §11 into the right
// TypedGatewayEvent variant with fields populated; unknown types →
// UnknownEvent; malformed frames never throw.

import 'dart:convert';
import 'dart:io';

import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decode a full event frame the way the RPC client's router does
/// (protocol §3c): params.type / params.session_id / params.payload
/// (payload normalized to a map).
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

void main() {
  group('§1 gateway.ready', () {
    // Verbatim §1 example.
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"gateway.ready",'
        '"payload":{"name":"hermes","colors":{},"branding":{},'
        '"tool_prefix":""}}}';

    test('parses to GatewayReady with the payload AS the skin dict', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<GatewayReady>());
      final ready = event as GatewayReady;
      expect(ready.skin['name'], 'hermes');
      expect(ready.skin['tool_prefix'], '');
      expect(ready.skin['colors'], isA<Map<String, dynamic>>());
    });
  });

  group('§7 one streaming turn', () {
    const sid = 'a1b2c3d4';

    test('message.start → MessageStart', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"message.start",'
          '"session_id":"a1b2c3d4"}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<MessageStart>());
      expect((event as MessageStart).sessionId, sid);
    });

    test('message.delta → MessageDelta with text', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta",'
          '"session_id":"a1b2c3d4","payload":{"text":"I\'ll "}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<MessageDelta>());
      final delta = event as MessageDelta;
      expect(delta.sessionId, sid);
      expect(delta.text, "I'll ");
      expect(delta.rendered, isNull);
    });

    test('tool.start → ToolStart with tool_id/name/context', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"tool.start",'
          '"session_id":"a1b2c3d4","payload":{"tool_id":"t1","name":"shell",'
          '"context":"ls -la"}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<ToolStart>());
      final start = event as ToolStart;
      expect(start.sessionId, sid);
      expect(start.toolId, 't1');
      expect(start.name, 'shell');
      expect(start.context, 'ls -la');
      expect(start.argsText, isNull);
      expect(start.todos, isNull);
    });

    test('tool.complete → ToolComplete with dict result (polymorphic)', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"tool.complete",'
          '"session_id":"a1b2c3d4","payload":{"tool_id":"t1","name":"shell",'
          '"result":{"stdout":"README.md\\n","code":0},"duration_s":0.12,'
          '"summary":"1 file"}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<ToolComplete>());
      final complete = event as ToolComplete;
      expect(complete.sessionId, sid);
      expect(complete.toolId, 't1');
      expect(complete.name, 'shell');
      expect(complete.result, isA<Map<String, dynamic>>());
      final result = complete.result as Map<String, dynamic>;
      expect(result['stdout'], 'README.md\n');
      expect(result['code'], 0);
      expect(complete.durationS, 0.12);
      expect(complete.summary, '1 file');
      expect(complete.error, isNull);
      expect(complete.inlineDiff, isNull);
    });

    test('tool.complete result may be a raw string (protocol §7)', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'tool.complete',
          sessionId: sid,
          payload: {
            'tool_id': 't1',
            'name': 'shell',
            'result': 'not json output',
          },
        ),
      );

      expect(event, isA<ToolComplete>());
      expect((event as ToolComplete).result, 'not json output');
    });

    test('message.complete → MessageComplete with usage + status', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"message.complete",'
          '"session_id":"a1b2c3d4","payload":{"text":"I\'ll list them. '
          'There is 1 file.","status":"complete","usage":{"input":1200,'
          '"output":42,"cost_usd":0.003}}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<MessageComplete>());
      final complete = event as MessageComplete;
      expect(complete.sessionId, sid);
      expect(complete.text, "I'll list them. There is 1 file.");
      expect(complete.status, MessageTerminalStatus.complete);
      expect(complete.usage, isNotNull);
      expect(complete.usage!.input, 1200);
      expect(complete.usage!.output, 42);
      expect(complete.usage!.costUsd, 0.003);
      expect(complete.reasoning, isNull);
    });

    test('message.complete status parsing: interrupted/error/unknown', () {
      MessageTerminalStatus statusOf(String? status) {
        final event = parseGatewayEvent(
          GatewayEvent(
            type: 'message.complete',
            sessionId: sid,
            payload: {'text': 'x', 'status': ?status},
          ),
        );
        return (event as MessageComplete).status;
      }

      expect(statusOf('interrupted'), MessageTerminalStatus.interrupted);
      expect(statusOf('error'), MessageTerminalStatus.error);
      expect(statusOf('complete'), MessageTerminalStatus.complete);
      // Unknown and missing statuses map to complete — the frame is
      // turn-terminal regardless (§6).
      expect(statusOf('surprise'), MessageTerminalStatus.complete);
      expect(statusOf(null), MessageTerminalStatus.complete);
    });

    test('session.info → SessionInfo with payload AS the info dict', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"session.info",'
          '"session_id":"a1b2c3d4","payload":{"model":"...","usage":{},'
          '"running":false}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SessionInfo>());
      final info = event as SessionInfo;
      expect(info.sessionId, sid);
      expect(info.info['model'], '...');
      expect(info.info['running'], false);
    });

    test('the §7 fixture parses verbatim, frame by frame', () {
      final lines = File(
        'test/fixtures/turn_basic.jsonl',
      ).readAsLinesSync().where((line) => line.trim().isNotEmpty).toList();

      expect(lines, hasLength(9)); // gateway.ready + the 8 §7 frames

      final events = lines
          .map((line) => parseGatewayEvent(_eventFromFrame(line)))
          .toList();

      expect(events[0], isA<GatewayReady>());
      expect(events[1], isA<MessageStart>());
      expect(events[2], isA<MessageDelta>());
      expect((events[2] as MessageDelta).text, "I'll ");
      expect(events[3], isA<MessageDelta>());
      expect((events[3] as MessageDelta).text, 'list them.');
      expect(events[4], isA<ToolStart>());
      expect(events[5], isA<ToolComplete>());
      expect(events[6], isA<MessageDelta>());
      expect((events[6] as MessageDelta).text, ' There is 1 file.');
      expect(events[7], isA<MessageComplete>());
      expect(
        (events[7] as MessageComplete).text,
        "I'll list them. There is 1 file.",
      );
      expect(events[8], isA<SessionInfo>());
    });
  });

  group('§10 approval.request', () {
    // Verbatim §10 example.
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"approval.request",'
        '"session_id":"a1b2c3d4","payload":{"command":"rm -rf build/",'
        '"description":"Delete build dir","allow_permanent":true,'
        '"pattern_key":"rm","pattern_keys":["rm"]}}}';

    test('parses to ApprovalRequestEvent with all fields populated', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<ApprovalRequestEvent>());
      final approval = event as ApprovalRequestEvent;
      expect(approval.sessionId, 'a1b2c3d4');
      expect(approval.command, 'rm -rf build/');
      expect(approval.description, 'Delete build dir');
      expect(approval.allowPermanent, isTrue);
      expect(approval.patternKey, 'rm');
      expect(approval.patternKeys, ['rm']);
    });
  });

  group('§11 clarify.request', () {
    // Verbatim §11 example.
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"clarify.request",'
        '"session_id":"a1b2c3d4","payload":{"question":"Which environment?",'
        '"choices":["staging","prod"],"request_id":"9f3a1c2b"}}}';

    test('parses to ClarifyRequestEvent with choices + request_id', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<ClarifyRequestEvent>());
      final clarify = event as ClarifyRequestEvent;
      expect(clarify.sessionId, 'a1b2c3d4');
      expect(clarify.question, 'Which environment?');
      expect(clarify.choices, ['staging', 'prod']);
      expect(clarify.requestId, '9f3a1c2b');
    });

    test('null choices means free-text (protocol §8.1)', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'clarify.request',
          sessionId: 'a1b2c3d4',
          payload: {
            'question': 'Say what?',
            'choices': null,
            'request_id': 'x',
          },
        ),
      );

      expect(event, isA<ClarifyRequestEvent>());
      expect((event as ClarifyRequestEvent).choices, isNull);
    });
  });

  group('P3-08 sudo.request', () {
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"sudo.request",'
        '"session_id":"a1b2c3d4","payload":{"request_id":"9f3a1c2b"}}}';

    test('parses to SudoRequestEvent with request_id', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SudoRequestEvent>());
      final sudo = event as SudoRequestEvent;
      expect(sudo.sessionId, 'a1b2c3d4');
      expect(sudo.requestId, '9f3a1c2b');
    });
  });

  group('P3-08 secret.request', () {
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"secret.request",'
        '"session_id":"a1b2c3d4","payload":{"prompt":"Enter your API key",'
        '"env_var":"OPENAI_API_KEY","request_id":"9f3a1c2b"}}}';

    test('parses to SecretRequestEvent with all fields', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SecretRequestEvent>());
      final secret = event as SecretRequestEvent;
      expect(secret.sessionId, 'a1b2c3d4');
      expect(secret.envVar, 'OPENAI_API_KEY');
      expect(secret.prompt, 'Enter your API key');
      expect(secret.requestId, '9f3a1c2b');
    });
  });

  group('P3-08 terminal.read.request', () {
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"terminal.read.request",'
        '"session_id":"a1b2c3d4","payload":{"request_id":"9f3a1c2b",'
        '"start":10,"count":20}}}';

    test('parses to TerminalReadRequestEvent with start/count', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<TerminalReadRequestEvent>());
      final termRead = event as TerminalReadRequestEvent;
      expect(termRead.sessionId, 'a1b2c3d4');
      expect(termRead.requestId, '9f3a1c2b');
      expect(termRead.start, 10);
      expect(termRead.count, 20);
    });

    test('start/count are nullable', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'terminal.read.request',
          sessionId: 'a1b2c3d4',
          payload: {'request_id': 'xyz'},
        ),
      );

      expect(event, isA<TerminalReadRequestEvent>());
      final termRead = event as TerminalReadRequestEvent;
      expect(termRead.start, isNull);
      expect(termRead.count, isNull);
    });
  });

  group('P3-04 subagent.* events', () {
    const sid = 'a1b2c3d4';

    test('subagent.start → SubagentEvent with identity + goal', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"subagent.start",'
          '"session_id":"a1b2c3d4","payload":{"subagent_id":"agent-123",'
          '"parent_id":"root","goal":"Analyze logs","task_count":5,'
          '"task_index":1,"depth":1,"model":"sonnet"}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SubagentEvent>());
      final sub = event as SubagentEvent;
      expect(sub.sessionId, sid);
      expect(sub.type, 'subagent.start');
      expect(sub.subagentId, 'agent-123');
      expect(sub.parentId, 'root');
      expect(sub.goal, 'Analyze logs');
      expect(sub.taskCount, 5);
      expect(sub.taskIndex, 1);
      expect(sub.depth, 1);
      expect(sub.model, 'sonnet');
    });

    test('subagent.tool → SubagentEvent with tool_name + tool_preview', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"subagent.tool",'
          '"session_id":"a1b2c3d4","payload":{"subagent_id":"agent-123",'
          '"goal":"Analyze","task_count":1,"task_index":0,'
          '"tool_name":"shell","tool_preview":"ls -la","text":"List files",'
          '"tool_count":3}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SubagentEvent>());
      final sub = event as SubagentEvent;
      expect(sub.type, 'subagent.tool');
      expect(sub.toolName, 'shell');
      expect(sub.toolPreview, 'ls -la');
      expect(sub.text, 'List files');
      expect(sub.toolCount, 3);
    });

    test('subagent.complete → SubagentEvent with status + tokens', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"subagent.complete",'
          '"session_id":"a1b2c3d4","payload":{"subagent_id":"agent-123",'
          '"goal":"Analyze","task_count":1,"task_index":0,'
          '"status":"completed","summary":"Done","duration_seconds":12.5,'
          '"cost_usd":0.05,"input_tokens":1000,"output_tokens":500,'
          '"reasoning_tokens":200,"api_calls":3,'
          '"files_read":["a.txt"],"files_written":["b.txt"]}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SubagentEvent>());
      final sub = event as SubagentEvent;
      expect(sub.type, 'subagent.complete');
      expect(sub.status, 'completed');
      expect(sub.summary, 'Done');
      expect(sub.durationSeconds, 12.5);
      expect(sub.costUsd, 0.05);
      expect(sub.inputTokens, 1000);
      expect(sub.outputTokens, 500);
      expect(sub.reasoningTokens, 200);
      expect(sub.apiCalls, 3);
      expect(sub.filesRead, ['a.txt']);
      expect(sub.filesWritten, ['b.txt']);
    });

    test('subagent.spawn_requested (thin) → SubagentEvent with no id', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":'
          '{"type":"subagent.spawn_requested","session_id":"a1b2c3d4",'
          '"payload":{"goal":"Scout","task_count":1,"task_index":0,'
          '"text":"Spawning"}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<SubagentEvent>());
      final sub = event as SubagentEvent;
      expect(sub.type, 'subagent.spawn_requested');
      expect(sub.goal, 'Scout');
      expect(sub.subagentId, isNull); // No identity on thin event.
      expect(sub.text, 'Spawning');
    });

    test('all six subagent types map to SubagentEvent', () {
      final types = [
        'subagent.spawn_requested',
        'subagent.start',
        'subagent.thinking',
        'subagent.tool',
        'subagent.progress',
        'subagent.complete',
      ];

      for (final type in types) {
        final event = parseGatewayEvent(
          GatewayEvent(
            type: type,
            sessionId: sid,
            payload: {
              'goal': 'Test',
              'task_count': 1,
              'task_index': 0,
            },
          ),
        );
        expect(event, isA<SubagentEvent>(), reason: '$type should parse');
        expect((event as SubagentEvent).type, type);
      }
    });
  });

  group('other documented event types (§6)', () {
    test('error → TurnError (turn-terminal alternative)', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'error',
          sessionId: 'a1b2c3d4',
          payload: {'message': 'boom'},
        ),
      );

      expect(event, isA<TurnError>());
      expect((event as TurnError).message, 'boom');
    });

    test('tool.progress → ToolProgress', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'tool.progress',
          sessionId: 'a1b2c3d4',
          payload: {'name': 'shell', 'preview': 'working…'},
        ),
      );

      expect(event, isA<ToolProgress>());
      final progress = event as ToolProgress;
      expect(progress.name, 'shell');
      expect(progress.preview, 'working…');
    });

    test('status.update → StatusUpdate with kind/text', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'status.update',
          sessionId: 'a1b2c3d4',
          payload: {'kind': 'retrying', 'text': 'Retry 1/3'},
        ),
      );

      expect(event, isA<StatusUpdate>());
      final update = event as StatusUpdate;
      expect(update.sessionId, 'a1b2c3d4');
      expect(update.kind, 'retrying');
      expect(update.text, 'Retry 1/3');
    });
  });

  group('never throws (P1-03 acceptance)', () {
    test('invented event type → UnknownEvent keeping the raw frame', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":'
          '{"type":"future.event.type","session_id":"a1b2c3d4",'
          '"payload":{"agent":"scout"}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<UnknownEvent>());
      final unknown = event as UnknownEvent;
      expect(unknown.type, 'future.event.type');
      expect(unknown.sessionId, 'a1b2c3d4');
      expect(unknown.payload['agent'], 'scout');
    });

    test('event with missing payload → defaults, no throw', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'message.delta',
          sessionId: null,
          payload: <String, dynamic>{},
        ),
      );

      expect(event, isA<MessageDelta>());
      final delta = event as MessageDelta;
      expect(delta.sessionId, isNull);
      expect(delta.text, '');
      expect(delta.rendered, isNull);
    });

    test('malformed payload field types fall back, no throw', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'message.delta',
          sessionId: 'a1b2c3d4',
          payload: {'text': 42, 'rendered': true},
        ),
      );

      expect(event, isA<MessageDelta>());
      final delta = event as MessageDelta;
      expect(delta.text, '');
      expect(delta.rendered, isNull);
    });

    test('approval.request with missing fields → defaults, no throw', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'approval.request',
          sessionId: 'a1b2c3d4',
          payload: <String, dynamic>{},
        ),
      );

      expect(event, isA<ApprovalRequestEvent>());
      final approval = event as ApprovalRequestEvent;
      expect(approval.command, '');
      expect(approval.description, '');
      expect(approval.patternKey, isNull);
      expect(approval.patternKeys, isEmpty);
      expect(approval.allowPermanent, isFalse);
    });

    test('union is sealed: switch is exhaustive without default', () {
      const event = TypedGatewayEvent.messageStart(sessionId: 'a1b2c3d4');

      // Compile-time exhaustiveness proof: no default branch needed.
      final label = switch (event) {
        GatewayReady() => 'ready',
        SessionInfo() => 'info',
        MessageStart() => 'start',
        MessageDelta() => 'delta',
        MessageComplete() => 'complete',
        TurnError() => 'error',
        ToolStart() => 'tool.start',
        ToolProgress() => 'tool.progress',
        ToolComplete() => 'tool.complete',
        ApprovalRequestEvent() => 'approval',
        ClarifyRequestEvent() => 'clarify',
        SudoRequestEvent() => 'sudo',
        SecretRequestEvent() => 'secret',
        TerminalReadRequestEvent() => 'terminal.read',
        SubagentEvent() => 'subagent',
        StatusUpdate() => 'status',
        BackgroundCompleteEvent() => 'background.complete',
        VoiceStatusEvent() => 'voice.status',
        VoiceTranscriptEvent() => 'voice.transcript',
        UnknownEvent() => 'unknown',
      };

      expect(label, 'start');
    });
  });

  group('P7-05 voice.status', () {
    const frame =
        '{"jsonrpc":"2.0","method":"event","params":{"type":"voice.status",'
        '"session_id":"a1b2c3d4","payload":{"state":"listening"}}}';

    test('parses to VoiceStatusEvent with state', () {
      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<VoiceStatusEvent>());
      final voiceStatus = event as VoiceStatusEvent;
      expect(voiceStatus.sessionId, 'a1b2c3d4');
      expect(voiceStatus.state, 'listening');
    });

    test('handles various states: idle|listening|transcribing', () {
      for (final state in ['idle', 'listening', 'transcribing']) {
        final event = parseGatewayEvent(
          GatewayEvent(
            type: 'voice.status',
            sessionId: 'a1b2c3d4',
            payload: {'state': state},
          ),
        );

        expect(event, isA<VoiceStatusEvent>());
        expect((event as VoiceStatusEvent).state, state);
      }
    });

    test('missing state falls back to empty string', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'voice.status',
          sessionId: 'a1b2c3d4',
          payload: <String, dynamic>{},
        ),
      );

      expect(event, isA<VoiceStatusEvent>());
      expect((event as VoiceStatusEvent).state, '');
    });

    test('empty session_id is allowed (gateway could not attribute it)', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'voice.status',
          sessionId: '',
          payload: {'state': 'idle'},
        ),
      );

      expect(event, isA<VoiceStatusEvent>());
      expect((event as VoiceStatusEvent).sessionId, '');
    });
  });

  group('P7-05 voice.transcript', () {
    test('parses to VoiceTranscriptEvent with text', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"voice.transcript",'
          '"session_id":"a1b2c3d4","payload":{"text":"Hello world"}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<VoiceTranscriptEvent>());
      final transcript = event as VoiceTranscriptEvent;
      expect(transcript.sessionId, 'a1b2c3d4');
      expect(transcript.text, 'Hello world');
      expect(transcript.noSpeechLimit, false);
    });

    test('parses no_speech_limit signal (three silent captures)', () {
      const frame =
          '{"jsonrpc":"2.0","method":"event","params":{"type":"voice.transcript",'
          '"session_id":"a1b2c3d4","payload":{"no_speech_limit":true}}}';

      final event = parseGatewayEvent(_eventFromFrame(frame));

      expect(event, isA<VoiceTranscriptEvent>());
      final transcript = event as VoiceTranscriptEvent;
      expect(transcript.sessionId, 'a1b2c3d4');
      expect(transcript.text, isNull);
      expect(transcript.noSpeechLimit, true);
    });

    test('absent text and no_speech_limit fall back to defaults', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'voice.transcript',
          sessionId: 'a1b2c3d4',
          payload: <String, dynamic>{},
        ),
      );

      expect(event, isA<VoiceTranscriptEvent>());
      final transcript = event as VoiceTranscriptEvent;
      expect(transcript.text, isNull);
      expect(transcript.noSpeechLimit, false);
    });

    test('empty session_id is allowed', () {
      final event = parseGatewayEvent(
        const GatewayEvent(
          type: 'voice.transcript',
          sessionId: '',
          payload: {'text': 'Test'},
        ),
      );

      expect(event, isA<VoiceTranscriptEvent>());
      expect((event as VoiceTranscriptEvent).sessionId, '');
    });
  });
}
