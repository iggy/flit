/// Domain model for insights aggregation (ticket P6-03).
///
/// Wire shape: `insights.get {days}` → `{days, sessions, messages}`.
final class Insights {
  const Insights({
    required this.days,
    required this.sessions,
    required this.messages,
  });

  /// Rolling window in days.
  final int days;

  /// Total sessions count in the window.
  final int sessions;

  /// Total messages count in the window.
  final int messages;

  @override
  bool operator ==(Object other) {
    return other is Insights &&
        other.days == days &&
        other.sessions == sessions &&
        other.messages == messages;
  }

  @override
  int get hashCode => Object.hash(days, sessions, messages);

  @override
  String toString() =>
      'Insights(days: $days, sessions: $sessions, messages: $messages)';
}
