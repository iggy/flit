import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/session_detail.dart';

/// Result of `session.create` (wire §2). Absorbs the two-session-ids quirk
/// (protocol §9): [liveId] is the short id for `prompt.submit` /
/// `session.interrupt`; [durableId] is the stored id for list/resume/delete.
final class SessionCreateResult {
  const SessionCreateResult({
    required this.liveId,
    required this.durableId,
    this.info,
  });

  /// Short live id (wire `session_id`, `uuid4().hex[:8]`).
  final String liveId;

  /// Durable stored id (wire `stored_session_id`, falling back to
  /// `session_key`).
  final String durableId;

  /// Opaque extra info dict from the gateway (`model`, `provider`, `lazy`,
  /// ...), kept raw — its shape is not pinned by the docs.
  final Map<String, dynamic>? info;

  @override
  bool operator ==(Object other) {
    return other is SessionCreateResult &&
        other.liveId == liveId &&
        other.durableId == durableId &&
        _nullableInfoEquals(other.info, info);
  }

  @override
  int get hashCode => Object.hash(
    liveId,
    durableId,
    info == null ? null : Object.hashAll(info!.keys),
  );

  @override
  String toString() {
    return 'SessionCreateResult(liveId: $liveId, durableId: $durableId, '
        'info: $info)';
  }
}

/// Continuation turn the gateway scheduled while answering `session.resume`,
/// because the session's last turn died with the process (wire
/// `auto_continue`). Present ONLY in that case: the turn is already running
/// server-side by the time the resume result lands, and its events stream to
/// the resuming client like any other turn.
final class AutoContinue {
  const AutoContinue({required this.attempt, this.interruptedAt});

  /// 1-based attempt counter — the gateway stops retrying after a configured
  /// maximum, so a high number means the continuation keeps crashing.
  final int attempt;

  /// When the interrupted turn started (wire `interrupted_at`, fractional
  /// epoch seconds).
  final DateTime? interruptedAt;

  @override
  bool operator ==(Object other) {
    return other is AutoContinue &&
        other.attempt == attempt &&
        other.interruptedAt == interruptedAt;
  }

  @override
  int get hashCode => Object.hash(attempt, interruptedAt);

  @override
  String toString() {
    return 'AutoContinue(attempt: $attempt, interruptedAt: $interruptedAt)';
  }
}

/// Result of `session.resume` (wire §5): the durable id you passed comes
/// back as [durableId], plus a **new** short [liveId] for live traffic.
final class SessionResumeResult {
  const SessionResumeResult({
    required this.liveId,
    required this.durableId,
    required this.messages,
    required this.messageCount,
    required this.running,
    required this.status,
    this.messagesOmitted = false,
    this.info,
    this.inflight,
    this.autoContinue,
  });

  /// NEW short live id (wire `session_id`) — route live traffic by this.
  final String liveId;

  /// The durable id that was resumed (wire `session_key` / `resumed`).
  final String durableId;

  /// Replayed conversation history (wire `messages` of `{role, text}`), EMPTY
  /// when [messagesOmitted].
  final List<ChatMessage> messages;

  /// Total message count reported by the gateway (wire `message_count`) — the
  /// raw history's length when [messagesOmitted], so it is a usable count
  /// either way.
  final int messageCount;

  /// Whether a turn is currently running in the session (wire `running`).
  final bool running;

  /// Live status string parsed tolerantly via [SessionStatus.parse].
  final SessionStatus status;

  /// The gateway honored `omit_messages` and left the transcript out (wire
  /// `messages_omitted`): [messages] is empty because it was NOT sent, not
  /// because the session is. Callers must not clear a seeded history on this.
  final bool messagesOmitted;

  /// Opaque extra info dict, kept raw — shape not pinned by the docs. Carries
  /// `lazy: true` for a lazy resume.
  final Map<String, dynamic>? info;

  /// Inflight turn snapshot (P2-02) — present ONLY when a turn was streaming
  /// at the time of socket drop. Both `null` and missing are treated as "no
  /// inflight turn."
  final InflightTurn? inflight;

  /// Continuation turn scheduled by the gateway for a crash-interrupted
  /// session, or null (the ordinary case).
  final AutoContinue? autoContinue;

  @override
  bool operator ==(Object other) {
    return other is SessionResumeResult &&
        other.liveId == liveId &&
        other.durableId == durableId &&
        deepListEquals(other.messages, messages) &&
        other.messageCount == messageCount &&
        other.running == running &&
        other.status == status &&
        other.messagesOmitted == messagesOmitted &&
        _nullableInfoEquals(other.info, info) &&
        other.inflight == inflight &&
        other.autoContinue == autoContinue;
  }

  @override
  int get hashCode => Object.hash(
    liveId,
    durableId,
    Object.hashAll(messages),
    messageCount,
    running,
    status,
    messagesOmitted,
    info == null ? null : Object.hashAll(info!.keys),
    inflight,
    autoContinue,
  );

  @override
  String toString() {
    return 'SessionResumeResult(liveId: $liveId, durableId: $durableId, '
        'messages: $messages, messageCount: $messageCount, '
        'running: $running, status: ${status.name}, '
        'messagesOmitted: $messagesOmitted, info: $info, '
        'inflight: $inflight, autoContinue: $autoContinue)';
  }
}

bool _nullableInfoEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return shallowMapEquals(a, b);
}
