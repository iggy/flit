/// Domain models for config viewer (ticket P4-06).
///
/// Wire shapes from `config.show` result: sections with label/value rows.
library;

import 'package:flit/domain/models/deep_equals.dart';

/// One section in the config view (from `config.show`).
final class ConfigSection {
  const ConfigSection({
    required this.title,
    required this.rows,
  });

  /// Section title (e.g. "Agent Settings").
  final String title;

  /// Rows in this section — label/value pairs.
  final List<ConfigRow> rows;

  @override
  bool operator ==(Object other) {
    return other is ConfigSection &&
        other.title == title &&
        deepListEquals(other.rows, rows);
  }

  @override
  int get hashCode => Object.hash(title, Object.hashAll(rows));

  @override
  String toString() => 'ConfigSection(title: $title, rows: $rows)';
}

/// One config row: label and value pair.
final class ConfigRow {
  const ConfigRow({
    required this.label,
    required this.value,
  });

  /// The setting label (e.g. "Model").
  final String label;

  /// The setting value (e.g. "sonnet").
  final String value;

  @override
  bool operator ==(Object other) {
    return other is ConfigRow &&
        other.label == label &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'ConfigRow(label: $label, value: $value)';
}
