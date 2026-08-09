/// Session bootstrap (ticket P1-09): owns the ACTIVE session the chat
/// screen talks to. `bootstrap()` creates a session via the session
/// repository and records the two ids (protocol §9: the short live id for
/// prompt/interrupt traffic, the durable id for list/resume).
///
/// Reconnect continuity (ticket P1-16, protocol §10): after a reconnect the
/// previous session is RE-BOUND via [rebind] — `session.resume` with the
/// durable id re-attaches the detached live session before the orphan
/// reaper finalizes it, and the replayed history is seeded into the new
/// live id's message list. The old state is kept while the resume is in
/// flight so the visible conversation is never wiped during the
/// reconnecting gap.
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/desktop_contract.dart';
import 'package:flit/application/sessions/session_overrides.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the client's current (active) session. "Current" is tracked
/// entirely client-side — the gateway doesn't own it (protocol §9).
final class ActiveSessionState {
  const ActiveSessionState({
    this.liveId,
    this.durableId,
    this.bootstrapping = false,
    this.error,
  });

  /// The short LIVE session id all chat/prompt calls use, or null before
  /// bootstrap completes.
  final String? liveId;

  /// The durable stored id (list/resume), or null before bootstrap.
  final String? durableId;

  /// True while `session.create` is in flight.
  final bool bootstrapping;

  /// Human-readable bootstrap failure (token-redacted), or null. Never
  /// thrown — bootstrap errors land HERE so the UI can offer a retry.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is ActiveSessionState &&
        other.liveId == liveId &&
        other.durableId == durableId &&
        other.bootstrapping == bootstrapping &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(liveId, durableId, bootstrapping, error);

  @override
  String toString() {
    return 'ActiveSessionState(liveId: $liveId, durableId: $durableId, '
        'bootstrapping: $bootstrapping, error: $error)';
  }
}

/// The active session for the current connection.
final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
      ActiveSessionNotifier.new,
    );

class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  @override
  ActiveSessionState build() => const ActiveSessionState();

  /// Create a session and make it active, carrying the sticky model/effort/
  /// fast picks ([sessionCreateOverridesProvider]) so they survive the new
  /// session instead of resetting to the profile defaults. No-op when a
  /// session is already active or a bootstrap is in flight (idempotent —
  /// safe to call from both a post-frame hook and a connection-state
  /// listener).
  ///
  /// NEVER throws: failures are recorded in [ActiveSessionState.error] so
  /// the caller can show a retry affordance.
  Future<void> bootstrap() async {
    if (state.liveId != null || state.bootstrapping) {
      return;
    }
    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) {
      // Disconnected: there is no RPC client to create a session with.
      state = const ActiveSessionState(error: 'Not connected to a gateway.');
      return;
    }
    final overrides = ref.read(sessionCreateOverridesProvider);
    state = const ActiveSessionState(bootstrapping: true);
    try {
      final result = await repository.create(
        model: overrides.model,
        provider: overrides.provider,
        reasoningEffort: overrides.reasoningEffort,
        fast: overrides.fast,
      );
      // First place the gateway tells us which desktop contract it speaks.
      ref.read(desktopContractProvider.notifier).recordInfo(result.info);
      state = ActiveSessionState(
        liveId: result.liveId,
        durableId: result.durableId,
      );
    } on GatewayException catch (error) {
      state = ActiveSessionState(error: error.message);
    } on Object catch (error) {
      state = ActiveSessionState(error: error.toString());
    }
  }

  /// Re-bind the active session after a RECONNECT (protocol §10; ticket
  /// P1-16). Unlike a clear+bootstrap, this keeps the current ids (under
  /// the bootstrapping flag) while `session.resume` is in flight, so the
  /// chat keeps rendering the old live id's message list during the
  /// reconnecting gap.
  ///
  /// - No durable id yet (fresh connect) → plain [bootstrap].
  /// - `session.resume` succeeds → switch to the NEW live id (protocol §9)
  ///   and seed the replayed history into its message list (wire §5) — the
  ///   list starts empty and only folds NEW events.
  /// - `session.resume` fails (the reaper may have finalized the session
  ///   server-side) → fall back to a fresh create via [bootstrap].
  ///
  /// Idempotent: a rebind/bootstrap already in flight is left alone, so a
  /// ready-transition listener racing a post-frame hook resumes at most
  /// once.
  Future<void> rebind() async {
    if (state.bootstrapping) {
      return;
    }
    final durableId = state.durableId;
    if (durableId == null) {
      // Nothing to re-bind — this is a fresh connect.
      await bootstrap();
      return;
    }
    final repository = ref.read(sessionRepositoryProvider);
    if (repository != null) {
      // Keep the old live id visible while the resume is in flight.
      state = ActiveSessionState(
        liveId: state.liveId,
        durableId: durableId,
        bootstrapping: true,
      );
      try {
        final result = await repository.resume(durableId);
        ref.read(desktopContractProvider.notifier).recordInfo(result.info);
        switchTo(liveId: result.liveId, durableId: result.durableId);
        ref
            .read(messageListProvider(result.liveId).notifier)
            .seedHistory(result.messages, inflight: result.inflight);
        return;
      } on GatewayException {
        // The session is gone server-side — fall through to a fresh
        // create (protocol §10: the orphan reaper won the race).
      } on Object {
        // Unexpected failure: same fallback; bootstrap records errors.
      }
    }
    clear();
    await bootstrap();
  }

  /// Make an EXISTING session active (drawer switch — ticket P1-10 wires
  /// the UI). Pass the live id of an already-running session, or the fresh
  /// live id returned by `session.resume`.
  void switchTo({required String liveId, String? durableId}) {
    state = ActiveSessionState(liveId: liveId, durableId: durableId);
  }

  /// Forget the active session (disconnect, or dropping a stale session
  /// before re-bootstrapping after a reconnect).
  void clear() {
    state = const ActiveSessionState();
  }
}
