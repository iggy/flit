import 'package:flit/presentation/common/primary_selection_sync.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester, Widget body) async {
    final written = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PrimarySelectionSync(
          enabled: true,
          writeSelection: (text) async => written.add(text),
          child: child!,
        ),
        home: Scaffold(
          body: Center(child: SizedBox(width: 400, child: body)),
        ),
      ),
    );
    return written;
  }

  Future<void> settle(WidgetTester tester) =>
      tester.pump(PrimarySelectionSync.settle * 2);

  testWidgets('a selection in a focused field is written once settled', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello world');
    addTearDown(controller.dispose);
    final written = await pump(tester, TextField(controller: controller));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();
    expect(written, isEmpty, reason: 'waits for the selection to settle');
    await settle(tester);
    expect(written, <String>['hello']);

    // Collapsing the selection leaves PRIMARY alone.
    controller.selection = const TextSelection.collapsed(offset: 2);
    await settle(tester);
    expect(written, <String>['hello']);
  });

  testWidgets('mouse selection in selectable text is written', (tester) async {
    final written = await pump(tester, const SelectableText('copy me please'));
    final rect = tester.getRect(find.byType(SelectableText));
    final gesture = await tester.startGesture(
      Offset(rect.left + 1, rect.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveTo(Offset(rect.right - 1, rect.center.dy));
    await tester.pump();
    await gesture.up();
    await settle(tester);
    expect(written, isNotEmpty);
    expect('copy me please', contains(written.last));
    expect(written.last.length, greaterThan(3));
  });

  testWidgets('password fields are never copied', (tester) async {
    final controller = TextEditingController(text: 'secret');
    addTearDown(controller.dispose);
    final written = await pump(
      tester,
      TextField(controller: controller, obscureText: true),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    await settle(tester);
    expect(written, isEmpty);
  });
}
