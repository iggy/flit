import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/session_bootstrap.dart';
import 'package:hermes/domain/models/session_summary.dart';

/// Intent-level session operations (ticket P1-04).
///
/// The two-session-ids quirk (docs/reference/01-gateway-protocol.md §9) is
/// absorbed below this interface: callers pass and receive the RIGHT id per
/// operation — durable ids for [resume], live ids for [interrupt].
abstract interface class SessionRepository {
  /// `session.create` (wire §2) → a fresh live id + durable id.
  /// Only non-null optionals are sent.
  Future<SessionCreateResult> create({
    String? profile,
    String? cwd,
    String? model,
  });

  /// `session.list` (wire §3) → stored conversations (durable ids).
  Future<List<SessionSummary>> list();

  /// `session.active_list` (wire §4) → live sessions for the switcher.
  /// [currentLiveId] is sent as `current_session_id` ONLY when non-null —
  /// "current" is tracked entirely client-side (protocol §9).
  Future<List<ActiveSession>> activeList({String? currentLiveId});

  /// `session.resume` (wire §5): [durableId] in, a NEW live id + replayed
  /// history out.
  Future<SessionResumeResult> resume(String durableId);

  /// `session.interrupt` (wire §12) — [liveId], not the durable id.
  Future<void> interrupt(String liveId);
}
