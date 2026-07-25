/// Completion models for slash commands and paths
/// (docs/reference/08-agent-transparency-wire-shapes.md
/// §complete.slash, §complete.path).
library;

/// One completion item (wire `{text, display, meta}`).
final class CompletionItem {
  const CompletionItem({
    required this.text,
    required this.display,
    required this.meta,
  });

  /// Replacement text (full command with trailing space, e.g. "/model ").
  final String text;

  /// Display text (command without trailing space, e.g. "/model").
  final String display;

  /// Metadata string (description or "dir"/"" for paths).
  final String meta;

  @override
  bool operator ==(Object other) {
    return other is CompletionItem &&
        other.text == text &&
        other.display == display &&
        other.meta == meta;
  }

  @override
  int get hashCode => Object.hash(text, display, meta);

  @override
  String toString() =>
      'CompletionItem(text: $text, display: $display, meta: $meta)';
}

/// Result of `complete.slash` (P3-02).
final class SlashCompletionResult {
  const SlashCompletionResult({
    required this.items,
    required this.replaceFrom,
  });

  /// Completion items.
  final List<CompletionItem> items;

  /// Character index to replace from (wire `replace_from`).
  final int replaceFrom;

  @override
  bool operator ==(Object other) {
    return other is SlashCompletionResult &&
        _listEquals(other.items, items) &&
        other.replaceFrom == replaceFrom;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), replaceFrom);

  @override
  String toString() =>
      'SlashCompletionResult(items: $items, replaceFrom: $replaceFrom)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
