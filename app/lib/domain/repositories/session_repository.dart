import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/steer_result.dart';

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

  /// `session.most_recent` (Phase 2, §session.most_recent) — query the DB for
  /// the most recent eligible session. Returns null when no session found.
  /// Takes NO session id (protocol §9).
  Future<MostRecentSession?> mostRecent({String? profile});

  /// `session.title` SET mode (Phase 2, §session.title) — rename a session.
  /// Takes LIVE id (protocol §9). Returns the resulting title.
  Future<String> setTitle(String liveId, String title);

  /// `session.delete` (Phase 2, §session.delete) — delete a stored session.
  /// Takes DURABLE id (protocol §9). Refuses active sessions.
  Future<void> delete(String durableId, {String? profile});

  /// `session.usage` (Phase 2, §session.usage) — token usage stats. Takes
  /// LIVE id (protocol §9). LONG handler.
  Future<SessionUsageStats> usage(String liveId);

  /// `session.context_breakdown` (Phase 2, §session.context_breakdown) —
  /// token breakdown by category. Takes LIVE id (protocol §9).
  Future<ContextBreakdown> contextBreakdown(String liveId);

  /// `session.compress` (Phase 2, §session.compress) — compress conversation
  /// context. Takes LIVE id (protocol §9). LONG handler.
  Future<CompressResult> compress(String liveId, {String? focusTopic});

  /// `session.undo` (Phase 2, §session.undo) — pop the last user+assistant
  /// turn. Takes LIVE id (protocol §9). Returns removed message count.
  Future<int> undo(String liveId);

  /// `session.save` (Phase 2, §session.save) — export the conversation to a
  /// JSON file. Takes LIVE id (protocol §9). Returns the file path.
  Future<String> save(String liveId);

  /// `session.branch` (Phase 2, §session.branch) — create a branch session
  /// from a parent. Takes LIVE id of the parent (protocol §9). Returns the
  /// NEW live id of the branch. LONG handler.
  Future<BranchResult> branch(String liveId, {String? name});

  /// `session.cwd.set` (Phase 2, §session.cwd.set) — set working directory.
  /// Takes LIVE id (protocol §9).
  Future<void> setCwd(String liveId, String cwd);

  /// `session.steer` (P3-07) — inject guidance into a running turn. Takes
  /// LIVE id (protocol §9). Returns whether it was queued or rejected.
  Future<SteerOutcome> steer(String liveId, String text);
}
