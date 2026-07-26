import 'package:flit/core/util/semver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareSemver', () {
    test('compares versions numerically, not lexicographically', () {
      expect(compareSemver('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareSemver('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareSemver('1.10.0', '1.2.0'), greaterThan(0));
    });

    test('returns zero for equal versions', () {
      expect(compareSemver('1.2.3', '1.2.3'), equals(0));
      expect(compareSemver('0.0.1', '0.0.1'), equals(0));
      expect(compareSemver('10.20.30', '10.20.30'), equals(0));
    });

    test('compares major, minor, patch in order', () {
      expect(compareSemver('2.0.0', '1.9.9'), greaterThan(0));
      expect(compareSemver('1.3.0', '1.2.9'), greaterThan(0));
      expect(compareSemver('1.2.5', '1.2.4'), greaterThan(0));

      expect(compareSemver('1.0.0', '2.0.0'), lessThan(0));
      expect(compareSemver('1.2.0', '1.3.0'), lessThan(0));
      expect(compareSemver('1.2.3', '1.2.4'), lessThan(0));
    });

    test('ignores build metadata', () {
      expect(compareSemver('1.2.3+100', '1.2.3+200'), equals(0));
      expect(compareSemver('1.2.3+abc', '1.2.3'), equals(0));
      expect(compareSemver('1.0.0+1', '1.0.0+999'), equals(0));
    });

    test('ignores pre-release tags', () {
      expect(compareSemver('1.2.3-beta', '1.2.3-alpha'), equals(0));
      expect(compareSemver('1.2.3-rc.1', '1.2.3'), equals(0));
      expect(compareSemver('2.0.0-beta', '2.0.0'), equals(0));
    });

    test('handles short forms', () {
      expect(compareSemver('1', '1.0.0'), equals(0));
      expect(compareSemver('1.2', '1.2.0'), equals(0));
      expect(compareSemver('2', '1.9.9'), greaterThan(0));
      expect(compareSemver('1.3', '1.2.9'), greaterThan(0));
    });

    test('returns zero for unparsable input', () {
      expect(compareSemver('abc', 'xyz'), equals(0));
      expect(compareSemver('', '1.2.3'), equals(0));
      expect(compareSemver('1.2.3', ''), equals(0));
      expect(compareSemver('1.x.3', '1.2.3'), equals(0));
      expect(compareSemver('1.2.3', '1.y.3'), equals(0));
    });

    test('handles both build metadata and pre-release', () {
      expect(compareSemver('1.2.3-beta+100', '1.2.3-alpha+200'), equals(0));
      expect(compareSemver('1.2.3-rc.1+456', '1.2.3'), equals(0));
    });

    test('real-world version comparisons', () {
      expect(compareSemver('0.17.0', '0.16.5'), greaterThan(0));
      expect(compareSemver('1.0.0', '0.99.99'), greaterThan(0));
      expect(compareSemver('1.0.0-beta', '1.0.0-alpha'), equals(0));
      expect(compareSemver('2.1.0+20260725', '2.1.0+20260724'), equals(0));
    });
  });
}
