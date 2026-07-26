// Unit tests for pure fuzzy matching functions (P9-04).

import 'package:flit/application/palette/palette_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fuzzyMatches', () {
    test('empty query matches everything', () {
      expect(fuzzyMatches('', 'anything'), true);
      expect(fuzzyMatches('', ''), true);
    });

    test('case-insensitive matching', () {
      expect(fuzzyMatches('chat', 'Chat'), true);
      expect(fuzzyMatches('CHAT', 'chat'), true);
      expect(fuzzyMatches('ChAt', 'cHaT'), true);
    });

    test('exact substring match', () {
      expect(fuzzyMatches('ban', 'Kanban board'), true);
    });

    test('subsequence match', () {
      expect(fuzzyMatches('kbb', 'Kanban board'), true);
      expect(fuzzyMatches('knb', 'Kanban board'), true);
    });

    test('non-match returns false', () {
      expect(fuzzyMatches('xyz', 'Kanban board'), false);
      expect(fuzzyMatches('abc', 'def'), false);
    });

    test('partial subsequence does not match', () {
      expect(fuzzyMatches('ksz', 'Kanban board'), false);
    });
  });

  group('fuzzyScore', () {
    test('empty query returns 0', () {
      expect(fuzzyScore('', 'anything'), 0);
    });

    test('non-match returns 0', () {
      expect(fuzzyScore('xyz', 'Kanban board'), 0);
    });

    test('exact prefix scores highest (1000)', () {
      expect(fuzzyScore('kan', 'Kanban board'), 1000);
      expect(fuzzyScore('Kan', 'kanban board'), 1000);
    });

    test('word-boundary prefix scores correctly', () {
      // 'board' is exact match from word boundary after space
      expect(fuzzyScore('board', 'Kanban board'), 500);
      expect(fuzzyScore('boa', 'Kanban board'), 500);
    });

    test('scattered subsequence scores 100', () {
      expect(fuzzyScore('knb', 'Kanban board'), 100);
    });

    test('prefix beats word-boundary', () {
      final prefixScore = fuzzyScore('kan', 'Kanban board');
      final wordScore = fuzzyScore('boa', 'Kanban board');
      expect(prefixScore, greaterThan(wordScore));
    });

    test('word-boundary beats scattered', () {
      final wordScore = fuzzyScore('boa', 'Kanban board');
      final scatteredScore = fuzzyScore('knb', 'Kanban board');
      expect(wordScore, greaterThan(scatteredScore));
    });
  });

  group('rankCommands', () {
    final commands = <String>['Chat', 'Settings', 'Kanban board', 'Agents'];

    test('empty query returns all commands in original order', () {
      final result = rankCommands<String>(commands, '', (s) => s);
      expect(result, commands);
    });

    test('filters out non-matching commands', () {
      final result = rankCommands<String>(commands, 'xyz', (s) => s);
      expect(result, isEmpty);
    });

    test('ranks exact prefix above word-boundary', () {
      final result = rankCommands<String>(commands, 'kan', (s) => s);
      expect(result, ['Kanban board']);
    });

    test('ranks word-boundary above scattered', () {
      final testCommands = <String>['Kanban board', 'knb test'];
      final result = rankCommands<String>(testCommands, 'knb', (s) => s);
      expect(result.first, 'knb test'); // 'knb' is prefix of "knb test"
    });

    test('stable sort: ties preserve original order', () {
      final testCommands = <String>['Alpha foo', 'Beta foo', 'Gamma foo'];
      final result = rankCommands<String>(testCommands, 'foo', (s) => s);
      // All are word-boundary matches with score 500 → original order preserved.
      expect(result, testCommands);
    });

    test('case-insensitive matching in rankCommands', () {
      final result = rankCommands<String>(commands, 'CHAT', (s) => s);
      expect(result, contains('Chat'));
    });
  });
}
