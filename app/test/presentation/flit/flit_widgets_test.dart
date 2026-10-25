import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/common/middle_ellipsis_text.dart';
import 'package:flit/presentation/flit/flit_model_picker.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatTokens', () {
    expect(formatTokens(512), '512');
    expect(formatTokens(262144), '262k');
    expect(formatTokens(1000000), '1M');
    expect(formatTokens(1500000), '1.5M');
  });

  testWidgets('status strip shows model, effort, context and speed', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitStatusStrip(
            provider: 'llama',
            model: 'qwen',
            effort: 'high',
            contextTokens: 12500,
            contextLength: 262144,
            state: FlitTaskState.working,
            generationTokensPerSecond: 45.25,
            onModelTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('llama / qwen'), findsOneWidget);
    expect(find.text('effort high'), findsOneWidget);
    expect(find.text('13k / 262k'), findsOneWidget);
    expect(find.text('45.3 tok/s'), findsOneWidget);
    expect(find.text('Working'), findsOneWidget);
    await tester.tap(find.text('llama / qwen'));
    expect(tapped, isTrue);
  });

  testWidgets('status strip keeps the model tag on a narrow screen', (
    tester,
  ) async {
    // Phone-ish; the test font is far wider than a real one.
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlitStatusStrip(
            provider: 'llama',
            model: 'qwen/Qwen3.8-Coder-30B-A3B-Instruct:Q4_K_M',
            effort: 'high',
            contextTokens: 0,
            contextLength: 0,
            state: FlitTaskState.working,
            onModelTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byType(MiddleEllipsisText),
        matching: find.byType(Text),
      ),
    );
    expect(label.data, contains('…'));
    expect(label.data, endsWith(':Q4_K_M'));
  });

  testWidgets('todo panel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlitTodoPanel(
            todos: <FlitTodo>[
              FlitTodo(content: 'read', status: FlitTodoStatus.completed),
              FlitTodo(content: 'fix', status: FlitTodoStatus.inProgress),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tasks (1/2)'), findsOneWidget);
    expect(find.text('fix'), findsOneWidget);
  });

  testWidgets('model picker returns model and effort', (tester) async {
    FlitModelChoice? picked;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flitModelsProvider.overrideWith(
            (ref) async => const <FlitModel>[
              FlitModel(
                provider: 'llama',
                id: 'small',
                contextLength: 32768,
                supportsTools: true,
              ),
              FlitModel(
                provider: 'llama',
                id: 'thinker',
                contextLength: 262144,
                supportsReasoning: true,
                efforts: <String>['low', 'high'],
                loaded: true,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await showFlitModelPicker(
                  context,
                  provider: 'llama',
                  model: 'small',
                  effort: '',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('llama · 33k context · tools'), findsOneWidget);
    expect(find.text('Reasoning effort'), findsNothing);

    await tester.tap(find.text('thinker'));
    await tester.pumpAndSettle();
    expect(find.text('Reasoning effort'), findsOneWidget);
    await tester.tap(find.text('high'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this model'));
    await tester.pumpAndSettle();
    expect(picked, (provider: 'llama', model: 'thinker', effort: 'high'));
  });
}
