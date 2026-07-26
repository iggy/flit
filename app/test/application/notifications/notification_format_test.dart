// P9-03 acceptance: notification formatting functions are deterministic,
// stable, and handle edge cases.

import 'package:flit/application/notifications/notification_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationIdFor', () {
    test('is deterministic — same key produces same id', () {
      const key = 'background:task123';
      final id1 = notificationIdFor(key);
      final id2 = notificationIdFor(key);
      expect(id1, id2);
    });

    test('is always non-negative', () {
      final keys = <String>[
        'background:task1',
        'approval:sess1:rm -rf',
        'some-other-key',
        '',
        'x' * 1000,
      ];
      for (final key in keys) {
        final id = notificationIdFor(key);
        expect(id, greaterThanOrEqualTo(0));
      }
    });

    test('differs for different keys', () {
      final id1 = notificationIdFor('background:task1');
      final id2 = notificationIdFor('background:task2');
      final id3 = notificationIdFor('approval:sess1:cmd');
      expect(id1, isNot(id2));
      expect(id1, isNot(id3));
      expect(id2, isNot(id3));
    });

    test('handles empty key', () {
      final id = notificationIdFor('');
      expect(id, greaterThanOrEqualTo(0));
    });
  });

  group('notificationBody', () {
    test('returns input when short', () {
      const input = 'Short text';
      expect(notificationBody(input), input);
    });

    test('truncates at maxLength with ellipsis', () {
      final input = 'a' * 200;
      final result = notificationBody(input, maxLength: 140);
      expect(result.length, 140);
      expect(result.endsWith('…'), isTrue);
      expect(result.startsWith('a'), isTrue);
    });

    test('collapses newlines into spaces', () {
      const input = 'Line one\nLine two\nLine three';
      final result = notificationBody(input);
      expect(result, 'Line one Line two Line three');
      expect(result.contains('\n'), isFalse);
    });

    test('collapses multiple spaces', () {
      const input = 'Multiple   spaces    here';
      final result = notificationBody(input);
      expect(result, 'Multiple spaces here');
    });

    test('trims leading and trailing whitespace', () {
      const input = '  \n  Leading and trailing  \n  ';
      final result = notificationBody(input);
      expect(result, 'Leading and trailing');
    });

    test('handles empty input', () {
      expect(notificationBody(''), '');
    });

    test('handles whitespace-only input', () {
      expect(notificationBody('   \n  \n   '), '');
    });

    test('truncates multi-line text correctly', () {
      final input = 'Line one\n' * 100;
      final result = notificationBody(input, maxLength: 50);
      expect(result.length, 50);
      expect(result.endsWith('…'), isTrue);
      expect(result.contains('\n'), isFalse);
    });

    test('respects custom maxLength', () {
      final input = 'a' * 200;
      final result = notificationBody(input, maxLength: 50);
      expect(result.length, 50);
      expect(result.endsWith('…'), isTrue);
    });
  });
}
