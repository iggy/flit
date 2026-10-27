/// Text another app shared with flit through the system share sheet
/// ("Share via… flit"), for example a browser sharing a page's URL.
library;

/// What was shared. Browsers usually put the URL in [text] and the page
/// title in [subject]; either may be empty.
final class SharedContent {
  const SharedContent({this.text = '', this.subject = ''});

  final String text;
  final String subject;

  /// Whether there is anything to use.
  bool get isEmpty => text.trim().isEmpty && subject.trim().isEmpty;

  /// The composer text for a new session: the subject (when it adds
  /// something) on its own line above the text.
  String get draft {
    final t = text.trim();
    final s = subject.trim();
    if (s.isEmpty || t.contains(s)) {
      return t;
    }
    if (t.isEmpty) {
      return s;
    }
    return '$s\n$t';
  }

  @override
  bool operator ==(Object other) =>
      other is SharedContent && other.text == text && other.subject == subject;

  @override
  int get hashCode => Object.hash(text, subject);

  @override
  String toString() => 'SharedContent(${text.length} chars)';
}
