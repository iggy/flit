import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/chat_message.dart';
import 'package:hermes/domain/models/deep_equals.dart';

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
    this.info,
  });

  /// NEW short live id (wire `session_id`) — route live traffic by this.
  final String liveId;

  /// The durable id that was resumed (wire `session_key` / `resumed`).
  final String durableId;

  /// Replayed conversation history (wire `messages` of `{role, text}`).
  final List<ChatMessage> messages;

  /// Total message count reported by the gateway (wire `message_count`).
  final int messageCount;

  /// Whether a turn is currently running in the session (wire `running`).
  final bool running;

  /// Live status string parsed tolerantly via [SessionStatus.parse].
  final SessionStatus status;

  /// Opaque extra info dict, kept raw — shape not pinned by the docs.
  final Map<String, dynamic>? info;

  @override
  bool operator ==(Object other) {
    return other is SessionResumeResult &&
        other.liveId == liveId &&
        other.durableId == durableId &&
        deepListEquals(other.messages, messages) &&
        other.messageCount == messageCount &&
        other.running == running &&
        other.status == status &&
        _nullableInfoEquals(other.info, info);
  }

  @override
  int get hashCode => Object.hash(
    liveId,
    durableId,
    Object.hashAll(messages),
    messageCount,
    running,
    status,
    info == null ? null : Object.hashAll(info!.keys),
  );

  @override
  String toString() {
    return 'SessionResumeResult(liveId: $liveId, durableId: $durableId, '
        'messages: $messages, messageCount: $messageCount, '
        'running: $running, status: ${status.name}, info: $info)';
  }
}

bool _nullableInfoEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return shallowMapEquals(a, b);
}
