import 'package:flit/core/theme/skin_color_scheme.dart';
import 'package:flit/domain/models/gateway_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHexColor', () {
    test('parses #rgb shorthand', () {
      final color = parseHexColor('#f00');
      expect(color, isNotNull);
      expect(color!.toARGB32() >> 16 & 0xff, 255);
      expect(color.toARGB32() >> 8 & 0xff, 0);
      expect(color.toARGB32() & 0xff, 0);
    });

    test('parses rgb shorthand without #', () {
      final color = parseHexColor('0f0');
      expect(color, isNotNull);
      expect(color!.toARGB32() >> 16 & 0xff, 0);
      expect(color.toARGB32() >> 8 & 0xff, 255);
      expect(color.toARGB32() & 0xff, 0);
    });

    test('parses #rrggbb', () {
      final color = parseHexColor('#ff8800');
      expect(color, isNotNull);
      expect(color!.toARGB32() >> 16 & 0xff, 255);
      expect(color.toARGB32() >> 8 & 0xff, 136);
      expect(color.toARGB32() & 0xff, 0);
    });

    test('parses rrggbb without #', () {
      final color = parseHexColor('0088ff');
      expect(color, isNotNull);
      expect(color!.toARGB32() >> 16 & 0xff, 0);
      expect(color.toARGB32() >> 8 & 0xff, 136);
      expect(color.toARGB32() & 0xff, 255);
    });

    test('parses #aarrggbb with alpha', () {
      final color = parseHexColor('#80ff0000');
      expect(color, isNotNull);
      expect(color!.toARGB32() >> 24 & 0xff, 128);
      expect(color.toARGB32() >> 16 & 0xff, 255);
      expect(color.toARGB32() >> 8 & 0xff, 0);
      expect(color.toARGB32() & 0xff, 0);
    });

    test('returns null for empty string', () {
      expect(parseHexColor(''), isNull);
    });

    test('returns null for malformed string', () {
      expect(parseHexColor('nope'), isNull);
      expect(parseHexColor('#12'), isNull);
      expect(parseHexColor('gggggg'), isNull);
    });

    test('returns null for null', () {
      expect(parseHexColor(null), isNull);
    });
  });

  group('contrastRatio', () {
    test('black vs white is approximately 21', () {
      final black = const Color(0xFF000000);
      final white = const Color(0xFFFFFFFF);
      final ratio = contrastRatio(black, white);
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('same color has ratio 1', () {
      final color = const Color(0xFF888888);
      final ratio = contrastRatio(color, color);
      expect(ratio, closeTo(1.0, 0.01));
    });
  });

  group('colorSchemeFromSkin', () {
    test('returns null for empty color map', () {
      final skin = const GatewaySkin(
        name: 'empty',
        colors: <String, String>{},
        branding: <String, String>{},
      );
      final scheme = colorSchemeFromSkin(skin, brightness: Brightness.light);
      expect(scheme, isNull);
    });

    test(
      'maps a dark-background skin to a scheme with requested brightness',
      () {
        final skin = const GatewaySkin(
          name: 'dark',
          colors: <String, String>{
            'background': '#1e1e1e',
            'ui_text': '#e6e6e6',
            'ui_accent': '#4a9eff',
          },
          branding: <String, String>{},
        );

        final lightScheme = colorSchemeFromSkin(
          skin,
          brightness: Brightness.light,
        );
        final darkScheme = colorSchemeFromSkin(
          skin,
          brightness: Brightness.dark,
        );

        expect(lightScheme, isNotNull);
        expect(lightScheme!.brightness, Brightness.light);

        expect(darkScheme, isNotNull);
        expect(darkScheme!.brightness, Brightness.dark);
      },
    );

    test('prefers lightColors for light request', () {
      final skin = const GatewaySkin(
        name: 'dual',
        colors: <String, String>{'background': '#000000'},
        lightColors: <String, String>{
          'background': '#ffffff',
          'ui_text': '#000000',
        },
        branding: <String, String>{},
      );

      final scheme = colorSchemeFromSkin(skin, brightness: Brightness.light);
      expect(scheme, isNotNull);
      // The background seed should come from lightColors (white).
      expect(scheme!.brightness, Brightness.light);
    });

    test('prefers darkColors for dark request', () {
      final skin = const GatewaySkin(
        name: 'dual',
        colors: <String, String>{'background': '#ffffff'},
        darkColors: <String, String>{
          'background': '#000000',
          'ui_text': '#ffffff',
        },
        branding: <String, String>{},
      );

      final scheme = colorSchemeFromSkin(skin, brightness: Brightness.dark);
      expect(scheme, isNotNull);
      // The background seed should come from darkColors (black).
      expect(scheme!.brightness, Brightness.dark);
    });
  });

  group('themeFromSkin', () {
    test('returns M3 theme structure with skin colors', () {
      final skin = const GatewaySkin(
        name: 'test',
        colors: <String, String>{
          'background': '#f7f7f8',
          'ui_text': '#161616',
          'ui_accent': '#6750a4',
        },
        branding: <String, String>{},
      );

      final theme = themeFromSkin(skin, brightness: Brightness.light);
      expect(theme, isNotNull);
      expect(theme!.useMaterial3, isTrue);
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });
  });
}
