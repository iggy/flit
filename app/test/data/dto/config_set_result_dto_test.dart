// P1-02 acceptance: both `config.set` result variants from
// docs/reference/03-mvp-wire-shapes.md §9.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/data/dto/config_set_result_dto.dart';

Map<String, dynamic> _resultOf(String frame) {
  final decoded = jsonDecode(frame) as Map<String, dynamic>;
  return decoded['result'] as Map<String, dynamic>;
}

void main() {
  group('config.set result (§9)', () {
    test('normal {value, info} → ConfigSetApplied', () {
      // §9 normal example; the doc's `info:{...}` placeholder is
      // materialized as an empty dict to keep the frame valid JSON.
      const frame = '''
{"jsonrpc":"2.0","id":"r7","result":{"value":"hermes-4-70b","info":{}}}''';

      final result = ConfigSetResultDto.fromJson(_resultOf(frame)).toDomain();

      expect(result, isA<ConfigSetApplied>());
      final applied = result as ConfigSetApplied;
      expect(applied.value, 'hermes-4-70b');
      expect(applied.info, isNotNull);
    });

    test('value may be a bool (e.g. config.set key:"fast")', () {
      final result = ConfigSetResultDto.fromJson(
        _resultOf('{"jsonrpc":"2.0","id":"r7","result":{"value":true}}'),
      ).toDomain();

      expect(result, isA<ConfigSetApplied>());
      expect((result as ConfigSetApplied).value, true);
    });

    test('{confirm_required, confirm_message} → ConfigSetConfirmRequired', () {
      // Verbatim §9 expensive-model example.
      const frame = '''
{"jsonrpc":"2.0","id":"r7","result":{"confirm_required":true,"confirm_message":"This model is \$X/Mtok. Continue?"}}''';

      final result = ConfigSetResultDto.fromJson(_resultOf(frame)).toDomain();

      expect(result, isA<ConfigSetConfirmRequired>());
      final confirm = result as ConfigSetConfirmRequired;
      expect(confirm.message, r'This model is $X/Mtok. Continue?');
    });

    test('confirm_required:false still maps to applied', () {
      final result = const ConfigSetResultDto(
        value: 'high',
        confirmRequired: false,
      ).toDomain();

      expect(result, isA<ConfigSetApplied>());
    });
  });
}
