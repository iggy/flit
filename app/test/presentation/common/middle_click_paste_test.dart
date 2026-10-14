import 'package:flit/presentation/common/middle_click_paste.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TextEditingController> pump(
    WidgetTester tester, {
    String initial = 'hello world',
    String? selection = 'PASTED',
    bool readOnly = false,
    bool enabled = true,
  }) async {
    final controller = TextEditingController(text: initial);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MiddleClickPaste(
          enabled: enabled,
          readSelection: () async => selection,
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: TextField(controller: controller, readOnly: readOnly),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  Future<void> middleClick(WidgetTester tester, Offset at) async {
    final gesture = await tester.startGesture(
      at,
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('inserts the selection where you click', (tester) async {
    final controller = await pump(tester);
    // Click near the start of the field: lands before "hello".
    final rect = tester.getRect(find.byType(TextField));
    await middleClick(tester, Offset(rect.left + 2, rect.center.dy));
    expect(controller.text, 'PASTEDhello world');
    expect(controller.selection.baseOffset, 'PASTED'.length);

    // Click past the end: appends.
    await middleClick(tester, Offset(rect.right - 2, rect.center.dy));
    expect(controller.text, 'PASTEDhello worldPASTED');
  });

  testWidgets('ignores read-only fields, empty selections, other buttons', (
    tester,
  ) async {
    var controller = await pump(tester, readOnly: true);
    final center = tester.getCenter(find.byType(TextField));
    await middleClick(tester, center);
    expect(controller.text, 'hello world');

    controller = await pump(tester, selection: null);
    await middleClick(tester, center);
    expect(controller.text, 'hello world');

    controller = await pump(tester);
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.text, 'hello world');
  });

  testWidgets('does nothing where there is no PRIMARY selection', (
    tester,
  ) async {
    final controller = await pump(tester, enabled: false);
    await middleClick(tester, tester.getCenter(find.byType(TextField)));
    expect(controller.text, 'hello world');
  });
}
