import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/presentation/chat/collapse_footer.dart';
import 'package:flit/presentation/chat/message_bubble.dart';
import 'package:flit/presentation/chat/tool_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: ListView(children: <Widget>[child])),
);

void main() {
  test('needsCollapseFooter', () {
    expect(needsCollapseFooter('short'), isFalse);
    expect(needsCollapseFooter('x' * 801), isTrue);
    expect(
      needsCollapseFooter(List<String>.filled(16, 'line').join('\n')),
      isTrue,
    );
  });

  testWidgets('long thinking can be collapsed from the bottom', (tester) async {
    final long = List<String>.generate(40, (i) => 'thought $i').join('\n');
    await tester.pumpWidget(
      _app(
        MessageBubble(
          message: ChatMessage(
            role: MessageRole.assistant,
            text: 'answer',
            reasoning: long,
            terminalStatus: MessageTerminalStatus.complete,
          ),
        ),
      ),
    );
    expect(find.byKey(reasoningCollapseFooterKey), findsNothing);
    await tester.tap(find.byKey(reasoningDisclosureKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('thought 39'), findsOneWidget);
    await tester.ensureVisible(find.byKey(reasoningCollapseFooterKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(reasoningCollapseFooterKey),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('thought 39'), findsNothing);
    expect(find.byKey(reasoningCollapseFooterKey), findsNothing);
  });

  testWidgets('short thinking has no bottom control', (tester) async {
    await tester.pumpWidget(
      _app(
        const MessageBubble(
          message: ChatMessage(
            role: MessageRole.assistant,
            text: 'answer',
            reasoning: 'brief',
            terminalStatus: MessageTerminalStatus.complete,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(reasoningDisclosureKey));
    await tester.pumpAndSettle();
    expect(find.byKey(reasoningCollapseFooterKey), findsNothing);
  });

  testWidgets('long tool output can be collapsed from the bottom', (
    tester,
  ) async {
    final out = List<String>.generate(30, (i) => 'line $i').join('\n');
    await tester.pumpWidget(
      _app(
        ToolCallCard(
          tool: ToolCall(
            id: 't',
            name: 'shell',
            context: 'make',
            status: ToolCallStatus.done,
            result: out,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('line 29'), findsOneWidget);
    await tester.ensureVisible(find.text('Collapse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collapse'));
    await tester.pumpAndSettle();
    expect(find.textContaining('line 29'), findsNothing);
  });
}
