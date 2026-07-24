/// Live status of a running session (wire §4:
/// `status` ∈ `idle|starting|waiting|working` — `_session_live_status`).
enum SessionStatus {
  idle,
  starting,
  waiting,
  working;

  /// Tolerates unknown/missing strings: unknown or null →
  /// [SessionStatus.working] (roadmap open question #4 — optimistically
  /// assume the session is busy rather than idle).
  static SessionStatus parse(String? value) {
    return switch (value) {
      'idle' => SessionStatus.idle,
      'starting' => SessionStatus.starting,
      'waiting' => SessionStatus.waiting,
      'working' => SessionStatus.working,
      _ => SessionStatus.working,
    };
  }
}

/// One row of `session.active_list` (wire §4) — a live session for the
/// switcher.
final class ActiveSession {
  const ActiveSession({
    required this.liveId,
    required this.status,
    this.model,
    this.title,
    this.preview,
    this.lastActive,
    this.messageCount,
    this.isCurrent = false,
  });

  /// The **short live id** (wire `id`) — used for `prompt.submit` /
  /// `session.interrupt` (protocol §9).
  final String liveId;

  /// Live status, parsed tolerantly ([SessionStatus.parse]).
  final SessionStatus status;

  /// Active model name, when reported.
  final String? model;

  /// Conversation title, when known.
  final String? title;

  /// Last-message preview snippet, when known.
  final String? preview;

  /// Last activity time; the wire sends epoch **seconds** (wire §4),
  /// absorbed to a [DateTime] by the DTO mapper.
  final DateTime? lastActive;

  /// Number of messages, when reported.
  final int? messageCount;

  /// Whether this is the client's current session. Tracked **entirely
  /// client-side** — the gateway doesn't own "current" (protocol §9); the
  /// client passes `current_session_id` into `session.active_list`.
  final bool isCurrent;

  @override
  bool operator ==(Object other) {
    return other is ActiveSession &&
        other.liveId == liveId &&
        other.status == status &&
        other.model == model &&
        other.title == title &&
        other.preview == preview &&
        other.lastActive == lastActive &&
        other.messageCount == messageCount &&
        other.isCurrent == isCurrent;
  }

  @override
  int get hashCode => Object.hash(
    liveId,
    status,
    model,
    title,
    preview,
    lastActive,
    messageCount,
    isCurrent,
  );

  @override
  String toString() {
    return 'ActiveSession(liveId: $liveId, status: ${status.name}, '
        'model: $model, title: $title, preview: $preview, '
        'lastActive: $lastActive, messageCount: $messageCount, '
        'isCurrent: $isCurrent)';
  }
}
