import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/presentation/flit/flit_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester,
    FlitPendingPrompt prompt,
  ) async {
    final answers = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitPromptCard(
            prompt: prompt,
            onAnswer: ({required allow, forSession = false}) async {
              answers.add('$allow:$forSession');
              return null;
            },
          ),
        ),
      ),
    );
    return answers;
  }

  testWidgets('offers allow for this session with the exact patterns', (
    tester,
  ) async {
    final answers = await pump(
      tester,
      const FlitPendingPrompt(
        promptId: 'p',
        toolCallId: 't',
        title: 'Run shell command',
        detail: 'cd app && go test ./...',
        sessionPatterns: <String>['go test *'],
      ),
    );
    expect(find.text('Allow "go test *" for this session'), findsOneWidget);
    await tester.tap(find.byKey(flitAllowSessionButtonKey));
    await tester.pumpAndSettle();
    expect(answers, <String>['true:true']);
  });

  testWidgets('no session button when nothing is offered', (tester) async {
    final answers = await pump(
      tester,
      const FlitPendingPrompt(
        promptId: 'p',
        toolCallId: 't',
        title: 'Run shell command',
        detail: 'echo hi > out.txt',
      ),
    );
    expect(find.byKey(flitAllowSessionButtonKey), findsNothing);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(answers, <String>['true:false']);
  });

  testWidgets('shows the safety check reason when there is one', (
    tester,
  ) async {
    await pump(
      tester,
      const FlitPendingPrompt(
        promptId: 'p',
        toolCallId: 't',
        title: 'Run shell command',
        detail: 'rm -rf build',
        safetyReason: 'deletes the build directory',
      ),
    );
    expect(
      find.text('Safety check: deletes the build directory'),
      findsOneWidget,
    );
  });

  testWidgets('no safety line without a check', (tester) async {
    await pump(
      tester,
      const FlitPendingPrompt(
        promptId: 'p',
        toolCallId: 't',
        title: 'Run shell command',
        detail: 'make',
      ),
    );
    expect(find.byKey(flitSafetyReasonKey), findsNothing);
  });
}
