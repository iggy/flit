// P1-01 acceptance: trivial construction of every domain model,
// SessionStatus.parse tolerance, and copyWith sanity.

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/domain/models/usage.dart';

void main() {
  group('construction', () {
    test(
      'ChatMessage defaults: not streaming, no tools, no terminal status',
      () {
        const message = ChatMessage(role: MessageRole.user, text: 'hi');

        expect(message.role, MessageRole.user);
        expect(message.text, 'hi');
        expect(message.rendered, isNull);
        expect(message.streaming, isFalse);
        expect(message.toolCalls, isEmpty);
        expect(message.terminalStatus, MessageTerminalStatus.none);
        expect(message.timestamp, isNull);
      },
    );

    test('ToolCall defaults to running', () {
      const call = ToolCall(id: 't1', name: 'shell', context: 'ls -la');

      expect(call.status, ToolCallStatus.running);
      expect(call.result, isNull);
      expect(call.summary, isNull);
      expect(call.inlineDiff, isNull);
      expect(call.durationS, isNull);
    });

    test('InteractivePrompt variants construct and are sealed subtypes', () {
      const InteractivePrompt approval = ApprovalPrompt(
        sessionId: 'a1b2c3d4',
        command: 'rm -rf build/',
        description: 'Delete build dir',
        patternKey: 'rm',
        patternKeys: ['rm'],
        allowPermanent: true,
      );
      const InteractivePrompt clarify = ClarifyPrompt(
        sessionId: 'a1b2c3d4',
        question: 'Which environment?',
        choices: ['staging', 'prod'],
        requestId: '9f3a1c2b',
      );

      expect(approval, isA<ApprovalPrompt>());
      expect(clarify, isA<ClarifyPrompt>());
      expect((clarify as ClarifyPrompt).choices, hasLength(2));
    });

    test('ClarifyPrompt with null choices means free-text', () {
      const prompt = ClarifyPrompt(
        sessionId: 'a1b2c3d4',
        question: 'Say what?',
        requestId: 'x',
      );

      expect(prompt.choices, isNull);
    });

    test('SessionSummary / ActiveSession / ModelProvider / PluginInfo / '
        'Usage / bootstrap results', () {
      final summary = SessionSummary(
        durableId: '2026..-uuid',
        title: 'Fix the parser',
        preview: 'last message…',
        messageCount: 12,
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          1783200000 * 1000,
          isUtc: true,
        ),
        source: 'cli',
      );
      expect(summary.durableId, '2026..-uuid');
      expect(summary.messageCount, 12);

      const active = ActiveSession(
        liveId: 'a1b2c3d4',
        status: SessionStatus.idle,
        isCurrent: true,
      );
      expect(active.model, isNull);
      expect(active.isCurrent, isTrue);

      const provider = ModelProvider(
        name: 'Nous Portal',
        slug: 'nous',
        authenticated: true,
        isCurrent: true,
        models: ['hermes-4-405b'],
      );
      expect(provider.models, hasLength(1));
      expect(provider.warning, isNull);

      const option = ModelOption(providerSlug: 'nous', model: 'hermes-4-70b');
      expect(option.providerSlug, 'nous');

      const current = CurrentModel(model: 'hermes-4-405b', provider: 'nous');
      expect(current.provider, 'nous');

      const plugin = PluginInfo(name: 'spotify', version: '?', enabled: false);
      expect(plugin.version, '?');

      const usage = Usage(input: 1200, output: 42, costUsd: 0.003);
      expect(usage.costUsd, 0.003);

      const created = SessionCreateResult(
        liveId: 'a1b2c3d4',
        durableId: '2026..-uuid',
        info: {'lazy': true},
      );
      expect(created.liveId, 'a1b2c3d4');
      expect(created.durableId, '2026..-uuid');

      const resumed = SessionResumeResult(
        liveId: 'e5f6a7b8',
        durableId: '2026..-uuid',
        messages: [ChatMessage(role: MessageRole.user, text: '…')],
        messageCount: 12,
        running: false,
        status: SessionStatus.idle,
      );
      expect(resumed.messages, hasLength(1));
      expect(resumed.status, SessionStatus.idle);
    });
  });

  group('SessionStatus.parse', () {
    test('documented statuses map exactly (wire §4)', () {
      expect(SessionStatus.parse('idle'), SessionStatus.idle);
      expect(SessionStatus.parse('starting'), SessionStatus.starting);
      expect(SessionStatus.parse('waiting'), SessionStatus.waiting);
      expect(SessionStatus.parse('working'), SessionStatus.working);
    });

    test('unknown → working; null → working (open question #4)', () {
      expect(SessionStatus.parse('quantum-entangled'), SessionStatus.working);
      expect(SessionStatus.parse(''), SessionStatus.working);
      expect(SessionStatus.parse(null), SessionStatus.working);
    });
  });

  group('copyWith', () {
    test('ChatMessage copyWith applies the fold-style mutations', () {
      const streaming = ChatMessage(
        role: MessageRole.assistant,
        text: '',
        streaming: true,
      );

      final delta = streaming.copyWith(text: "I'll list them.");
      expect(delta.text, "I'll list them.");
      expect(delta.streaming, isTrue); // untouched fields are kept

      final withTool = delta.copyWith(
        toolCalls: const [ToolCall(id: 't1', name: 'shell', context: 'ls -la')],
      );
      expect(withTool.toolCalls, hasLength(1));
      expect(withTool.toolCalls.single.status, ToolCallStatus.running);

      final done = withTool.copyWith(
        streaming: false,
        terminalStatus: MessageTerminalStatus.complete,
      );
      expect(done.streaming, isFalse);
      expect(done.terminalStatus, MessageTerminalStatus.complete);
      expect(done.text, "I'll list them.");
    });

    test('ToolCall copyWith resolves running → done with result', () {
      const running = ToolCall(id: 't1', name: 'shell');

      final done = running.copyWith(
        status: ToolCallStatus.done,
        result: 'README.md\n',
        summary: '1 file',
        durationS: 0.12,
      );

      expect(done.status, ToolCallStatus.done);
      expect(done.result, 'README.md\n');
      expect(done.summary, '1 file');
      expect(done.durationS, 0.12);
      expect(done.id, 't1');
    });
  });

  group('value equality', () {
    test('ChatMessage equality is deep over toolCalls', () {
      const a = ChatMessage(
        role: MessageRole.assistant,
        text: 'x',
        toolCalls: [ToolCall(id: 't1', name: 'shell')],
      );
      const b = ChatMessage(
        role: MessageRole.assistant,
        text: 'x',
        toolCalls: [ToolCall(id: 't1', name: 'shell')],
      );
      const c = ChatMessage(role: MessageRole.assistant, text: 'x');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('ApprovalPrompt equality is deep over patternKeys', () {
      const a = ApprovalPrompt(
        sessionId: 's',
        command: 'rm',
        description: 'd',
        patternKeys: ['rm'],
      );
      const b = ApprovalPrompt(
        sessionId: 's',
        command: 'rm',
        description: 'd',
        patternKeys: ['rm'],
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
