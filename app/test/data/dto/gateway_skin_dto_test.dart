import 'package:flit/data/dto/gateway_skin_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseGatewaySkinPayload', () {
    test('returns null for empty payload', () {
      final skin = parseGatewaySkinPayload(<String, dynamic>{});
      expect(skin, isNull);
    });

    test('returns null for payload with name but no colors', () {
      final skin = parseGatewaySkinPayload(<String, dynamic>{'name': 'hermes'});
      expect(skin, isNull);
    });

    test('parses full realistic payload', () {
      final payload = <String, dynamic>{
        'name': 'hermes',
        'colors': <String, dynamic>{
          'background': '#1e1e1e',
          'ui_text': '#e6e6e6',
          'ui_accent': '#4a9eff',
          'ui_error': '#e25563',
        },
        'light_colors': <String, dynamic>{
          'background': '#f7f7f8',
          'ui_text': '#161616',
        },
        'dark_colors': <String, dynamic>{
          'background': '#141414',
          'ui_text': '#e6e6e6',
        },
        'branding': <String, dynamic>{
          'agent_name': 'Hermes',
          'welcome': 'Welcome!',
        },
        'banner_logo': 'base64logo',
        'banner_hero': 'base64hero',
        'tool_prefix': '┊',
        'help_header': 'Help',
      };

      final skin = parseGatewaySkinPayload(payload);
      expect(skin, isNotNull);
      expect(skin!.name, 'hermes');
      expect(skin.colors, hasLength(4));
      expect(skin.colors['background'], '#1e1e1e');
      expect(skin.lightColors, isNotNull);
      expect(skin.lightColors!['background'], '#f7f7f8');
      expect(skin.darkColors, isNotNull);
      expect(skin.darkColors!['background'], '#141414');
      expect(skin.branding, hasLength(2));
      expect(skin.branding['agent_name'], 'Hermes');
      expect(skin.bannerLogo, 'base64logo');
      expect(skin.toolPrefix, '┊');
    });

    test('treats colors as empty when given as List (wrong type)', () {
      final payload = <String, dynamic>{
        'name': 'test',
        'colors': <dynamic>['not', 'a', 'map'],
      };

      final skin = parseGatewaySkinPayload(payload);
      expect(skin, isNull);
    });

    test('treats colors as empty when given as String (wrong type)', () {
      final payload = <String, dynamic>{'name': 'test', 'colors': 'not a map'};

      final skin = parseGatewaySkinPayload(payload);
      expect(skin, isNull);
    });

    test('drops non-string color values', () {
      final payload = <String, dynamic>{
        'name': 'test',
        'colors': <String, dynamic>{
          'background': '#1e1e1e',
          'ui_text': 42, // wrong type
          'ui_accent': <String, String>{'nested': 'map'}, // wrong type
          'ui_error': '#e25563',
        },
      };

      final skin = parseGatewaySkinPayload(payload);
      expect(skin, isNotNull);
      expect(skin!.colors, hasLength(2));
      expect(skin.colors['background'], '#1e1e1e');
      expect(skin.colors['ui_error'], '#e25563');
      expect(skin.colors.containsKey('ui_text'), isFalse);
      expect(skin.colors.containsKey('ui_accent'), isFalse);
    });

    test('never throws on malformed input', () {
      final payloads = <Map<String, dynamic>>[
        <String, dynamic>{'name': 123, 'colors': 'not a map'},
        <String, dynamic>{'name': '', 'colors': null},
        <String, dynamic>{
          'colors': <String, dynamic>{'key': 'value'},
        },
      ];

      for (final payload in payloads) {
        expect(() => parseGatewaySkinPayload(payload), returnsNormally);
      }
    });

    test('returns null for unusable skin (name empty)', () {
      final payload = <String, dynamic>{
        'name': '   ',
        'colors': <String, dynamic>{'background': '#000000'},
      };

      final skin = parseGatewaySkinPayload(payload);
      expect(skin, isNull);
    });

    test('trims skin name', () {
      final payload = <String, dynamic>{
        'name': '  hermes  ',
        'colors': <String, dynamic>{'background': '#000000'},
      };

      final skin = parseGatewaySkinPayload(payload);
      expect(skin, isNotNull);
      expect(skin!.name, 'hermes');
    });
  });
}
