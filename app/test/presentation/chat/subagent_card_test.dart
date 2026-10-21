import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/subagent.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/presentation/chat/subagent_card.dart';
import 'package:flit/presentation/chat/tool_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('an agent tool call shows a collapsed subagent card', (
    tester,
  ) async {
    const tool = ToolCall(
      id: 'ag1',
      name: 'agent',
      status: ToolCallStatus.done,
      subagent: Subagent(
        kind: SubagentKind.explore,
        provider: 'local',
        model: 'small-model',
        task: 'find the config loader',
        status: SubagentStatus.done,
        steps: 3,
        report: 'It is in config.go.',
        transcript: <ChatMessage>[
          ChatMessage(role: MessageRole.user, text: 'find the config loader'),
          ChatMessage(
            role: MessageRole.assistant,
            text: '',
            toolCalls: <ToolCall>[
              ToolCall(
                id: 'g1',
                name: 'grep',
                context: 'Load',
                status: ToolCallStatus.done,
                result: 'config.go:12',
              ),
            ],
          ),
          ChatMessage(role: MessageRole.assistant, text: 'It is in config.go.'),
        ],
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ToolCallCard(tool: tool)),
        ),
      ),
    );
    expect(find.byType(SubagentCard), findsOneWidget);
    expect(find.textContaining('explore subagent'), findsOneWidget);
    expect(find.textContaining('small-model'), findsOneWidget);
    expect(find.textContaining('3 steps'), findsOneWidget);
    expect(find.text('Report'), findsNothing);

    await tester.tap(find.byKey(subagentHeaderKey));
    await tester.pumpAndSettle();
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('It is in config.go.'), findsOneWidget);
    // Its own tool calls render as ordinary tool cards.
    expect(find.byType(ToolCallCard), findsNWidgets(2));
  });
}
