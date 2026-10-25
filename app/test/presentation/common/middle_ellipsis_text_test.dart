import 'package:flit/presentation/common/middle_ellipsis_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _long = 'llama / qwen/Qwen3.8-Coder-30B-A3B-Instruct:Q4_K_M';

Widget _boxed(double width, String text) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: MiddleEllipsisText(text)),
    ),
  ),
);

String _shown(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).data!;

void main() {
  group('middleEllipsis', () {
    test('keeps short text as is', () {
      expect(middleEllipsis('qwen:Q4', 7), 'qwen:Q4');
      expect(middleEllipsis('qwen:Q4', 100), 'qwen:Q4');
    });

    test('drops the middle and keeps both ends', () {
      expect(middleEllipsis('abcdefghij', 4), 'ab…ij');
      // Odd: the end gets the extra character.
      expect(middleEllipsis('abcdefghij', 5), 'ab…hij');
      expect(middleEllipsis('qwen/Qwen3-Coder:Q4_K_M', 12), 'qwen/Q…Q4_K_M');
    });

    test('degenerate budgets', () {
      expect(middleEllipsis('abc', 0), '…');
      expect(middleEllipsis('abc', -1), '…');
    });

    test('never splits a grapheme cluster', () {
      expect(middleEllipsis('a👍🏽b👍🏽c', 2), 'a…c');
    });
  });

  group('MiddleEllipsisText', () {
    testWidgets('shows the whole text when it fits', (tester) async {
      await tester.pumpWidget(_boxed(2000, _long));
      expect(_shown(tester), _long);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('keeps the tag after ":" when narrow', (tester) async {
      await tester.pumpWidget(_boxed(220, _long));
      final shown = _shown(tester);
      expect(shown, contains(kMiddleEllipsis));
      expect(shown, endsWith(':Q4_K_M'));
      expect(shown, startsWith('llama'));
      expect(tester.takeException(), isNull);
      // The full name is a long-press away and is what screen readers get.
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, _long);
      expect(find.bySemanticsLabel(_long), findsOneWidget);
    });

    testWidgets('fills the width it gets', (tester) async {
      await tester.pumpWidget(_boxed(220, _long));
      final narrow = _shown(tester).length;
      await tester.pumpWidget(_boxed(300, _long));
      expect(_shown(tester).length, greaterThan(narrow));
      expect(tester.getSize(find.byType(Text)).width, lessThanOrEqualTo(300));
    });
  });
}
