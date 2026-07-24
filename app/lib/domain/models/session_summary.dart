/// One row of `session.list` (wire §3) — a stored (durable) conversation.
final class SessionSummary {
  const SessionSummary({
    required this.durableId,
    required this.title,
    required this.preview,
    required this.messageCount,
    this.startedAt,
    this.source,
  });

  /// The **durable** stored id (DB row id; wire `id`). Used for
  /// `session.resume` / `session.delete` (protocol §9).
  final String durableId;

  /// Conversation title.
  final String title;

  /// Last-message preview snippet.
  final String preview;

  /// Number of messages in the stored conversation.
  final int messageCount;

  /// Start time; the wire sends epoch **seconds** (wire §3), absorbed to a
  /// [DateTime] by the DTO mapper.
  final DateTime? startedAt;

  /// Where the session originated, e.g. `cli`.
  final String? source;

  @override
  bool operator ==(Object other) {
    return other is SessionSummary &&
        other.durableId == durableId &&
        other.title == title &&
        other.preview == preview &&
        other.messageCount == messageCount &&
        other.startedAt == startedAt &&
        other.source == source;
  }

  @override
  int get hashCode =>
      Object.hash(durableId, title, preview, messageCount, startedAt, source);

  @override
  String toString() {
    return 'SessionSummary(durableId: $durableId, title: $title, '
        'preview: $preview, messageCount: $messageCount, '
        'startedAt: $startedAt, source: $source)';
  }
}
