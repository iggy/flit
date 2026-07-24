/// Session list providers + drawer actions (ticket P1-10): history via
/// `session.list` (wire §3), live sessions via `session.active_list`
/// (wire §4), and the imperative new/switch/interrupt operations the
/// session drawer calls.
///
/// Protocol §9 (two kinds of session id) drives the design:
///
/// - [sessionListProvider] deals in DURABLE ids, [activeSessionListProvider]
///   in LIVE ids, and NO wire shape joins the two (`active_list` carries no
///   durable id) — so the client keeps its own durable→live map
///   ([sessionIdMapProvider]). "Current" is client-side state: the CURRENT
///   live id is passed INTO `session.active_list`.
/// - Switching to an already-live session reuses its live id; switching to
///   a durable-only one goes through `session.resume` (new live id) and the
///   replayed history is seeded into the message list (wire §5) —
///   `messageListProvider` starts empty and only folds NEW events.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/chat/message_list_notifier.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/application/sessions/active_session.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/session_summary.dart';

/// Stored conversations (`session.list`, wire §3) — durable ids. Empty when
/// disconnected (the repository is null) so the drawer renders an empty
/// state instead of throwing.
final sessionListProvider = FutureProvider<List<SessionSummary>>((ref) async {
  final repository = ref.watch(sessionRepositoryProvider);
  if (repository == null) {
    return const <SessionSummary>[];
  }
  return repository.list();
});

/// Live sessions (`session.active_list`, wire §4) — live ids + status
/// badges. The CURRENT live id is passed in (protocol §9: the gateway
/// doesn't own "current"), so the list re-fetches when the active session
/// changes.
final activeSessionListProvider = FutureProvider<List<ActiveSession>>((
  ref,
) async {
  final repository = ref.watch(sessionRepositoryProvider);
  if (repository == null) {
    return const <ActiveSession>[];
  }
  final currentLiveId = ref.watch(activeSessionProvider).liveId;
  return repository.activeList(currentLiveId: currentLiveId);
});

/// Client-side durable→live id join (protocol §9). The wire never joins
/// the two ids, so the client remembers every pair it activates: the build
/// seed captures the session that is current when the map first builds
/// (typically the bootstrapped one), and the listener records every later
/// switch (bootstrap, new, resume).
final sessionIdMapProvider =
    NotifierProvider<SessionIdMapNotifier, Map<String, String>>(
      SessionIdMapNotifier.new,
    );

class SessionIdMapNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    ref.listen(activeSessionProvider, (previous, next) {
      final liveId = next.liveId;
      final durableId = next.durableId;
      if (liveId != null && durableId != null) {
        state = <String, String>{...state, durableId: liveId};
      }
    });
    final active = ref.read(activeSessionProvider);
    final liveId = active.liveId;
    final durableId = active.durableId;
    if (liveId == null || durableId == null) {
      return const <String, String>{};
    }
    return <String, String>{durableId: liveId};
  }
}

/// The imperative session operations behind the drawer (ticket P1-10).
///
/// Every method returns a human-readable error message on failure and null
/// on success — NOTHING throws; the drawer surfaces failures in a
/// dismissible banner.
final sessionActionsProvider = Provider<SessionActions>((ref) {
  return SessionActions(ref);
});

class SessionActions {
  const SessionActions(this._ref);

  final Ref _ref;

  static const String _notConnected = 'Not connected to a gateway.';

  /// `session.create` (wire §2) → make the fresh session active with BOTH
  /// ids (protocol §9).
  Future<String?> newSession() async {
    final repository = _ref.read(sessionRepositoryProvider);
    if (repository == null) {
      return _notConnected;
    }
    // Build the id map BEFORE the switch so its build seed captures the
    // outgoing session (the listener records the new one).
    _ref.read(sessionIdMapProvider);
    try {
      final result = await repository.create();
      _ref
          .read(activeSessionProvider.notifier)
          .switchTo(liveId: result.liveId, durableId: result.durableId);
      // A new stored session exists — the history list should refetch.
      _ref.invalidate(sessionListProvider);
      return null;
    } on GatewayException catch (error) {
      return error.message;
    } on Object catch (error) {
      return error.toString();
    }
  }

  /// Switch to a history row (durable id). When the session is still LIVE —
  /// it is the current one, or the id map joins it to an `active_list`
  /// entry — its live id is reused; otherwise `session.resume` (wire §5)
  /// mints a NEW live id and the replayed history is seeded into the
  /// (otherwise forward-only) message list.
  Future<String?> switchToSummary(SessionSummary summary) async {
    final repository = _ref.read(sessionRepositoryProvider);
    if (repository == null) {
      return _notConnected;
    }
    final liveId = _liveIdFor(summary.durableId);
    if (liveId != null) {
      _ref
          .read(activeSessionProvider.notifier)
          .switchTo(liveId: liveId, durableId: summary.durableId);
      return null;
    }
    try {
      final result = await repository.resume(summary.durableId);
      _ref
          .read(activeSessionProvider.notifier)
          .switchTo(liveId: result.liveId, durableId: result.durableId);
      // messageListProvider(liveId) starts empty and only folds NEW
      // events — seed the replayed history (wire §5) so the resumed
      // conversation is visible.
      _ref
          .read(messageListProvider(result.liveId).notifier)
          .seedHistory(result.messages);
      return null;
    } on GatewayException catch (error) {
      return error.message;
    } on Object catch (error) {
      return error.toString();
    }
  }

  /// Switch to an already-live session (a Live-section row) by its LIVE id
  /// — no resume; its message list kept folding while subscribed.
  void switchToLive(ActiveSession session) {
    if (_ref.read(activeSessionProvider).liveId == session.liveId) {
      return;
    }
    _ref
        .read(activeSessionProvider.notifier)
        .switchTo(
          liveId: session.liveId,
          durableId: _durableIdFor(session.liveId),
        );
  }

  /// `session.interrupt` (wire §12) on the ACTIVE session (live id).
  Future<String?> interruptActive() async {
    final repository = _ref.read(sessionRepositoryProvider);
    final liveId = _ref.read(activeSessionProvider).liveId;
    if (repository == null || liveId == null) {
      return null; // Nothing to interrupt.
    }
    try {
      await repository.interrupt(liveId);
      // Refresh the live badges (working → idle once the turn settles).
      _ref.invalidate(activeSessionListProvider);
      return null;
    } on GatewayException catch (error) {
      return error.message;
    } on Object catch (error) {
      return error.toString();
    }
  }

  /// The live id for [durableId] when the session is KNOWN-live: either it
  /// IS the current session, or the id map joins it to a session the
  /// gateway still reports in `active_list` (stale entries — e.g. from
  /// before a reconnect — fail that check and fall through to resume).
  String? _liveIdFor(String durableId) {
    final active = _ref.read(activeSessionProvider);
    if (active.durableId == durableId && active.liveId != null) {
      return active.liveId;
    }
    final mapped = _ref.read(sessionIdMapProvider)[durableId];
    if (mapped == null) {
      return null;
    }
    final live = _ref.read(activeSessionListProvider).value;
    final known = live ?? const <ActiveSession>[];
    if (known.any((session) => session.liveId == mapped)) {
      return mapped;
    }
    return null;
  }

  /// Reverse lookup of the id map (live → durable), when known.
  String? _durableIdFor(String liveId) {
    for (final entry in _ref.read(sessionIdMapProvider).entries) {
      if (entry.value == liveId) {
        return entry.key;
      }
    }
    return null;
  }
}
