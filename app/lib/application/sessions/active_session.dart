/// Session bootstrap (ticket P1-09): owns the ACTIVE session the chat
/// screen talks to. `bootstrap()` creates a session via the session
/// repository and records the two ids (protocol §9: the short live id for
/// prompt/interrupt traffic, the durable id for list/resume).
///
/// Phase 1 simplification: after a reconnect the previous session is
/// assumed STALE — the chat screen clears it and bootstraps a fresh one.
/// Reconnect-and-resume is Phase 2 (protocol §10); documented in
/// docs/phases/phase-1-mvp.md P1-09.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';

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

  /// Create a session and make it active. No-op when a session is already
  /// active or a bootstrap is in flight (idempotent — safe to call from
  /// both a post-frame hook and a connection-state listener).
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
    state = const ActiveSessionState(bootstrapping: true);
    try {
      final result = await repository.create();
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
