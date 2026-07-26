/// Deep-link session resolution (ticket P9-02): resolves a durable session id
/// from a deep link URL (`/session/:id`) by switching to that session or
/// resuming it if it's not currently live.
///
/// The URL contains the DURABLE id (stable across restarts) rather than the
/// ephemeral live id — see protocol §9 and `session_list.dart`.
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a deep-link session by its durable id — switching to it if
/// already live, or resuming it via `session.resume` otherwise.
///
/// Never throws: errors land in [DeepLinkResolveState.error].
final deepLinkResolverProvider =
    NotifierProvider<DeepLinkResolver, DeepLinkResolveState>(
      DeepLinkResolver.new,
    );

/// State of a deep-link resolution attempt.
final class DeepLinkResolveState {
  const DeepLinkResolveState({this.busy = false, this.error});

  /// A resolution is in flight.
  final bool busy;

  /// Human-readable failure, or null on success.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is DeepLinkResolveState &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, error);

  @override
  String toString() {
    return 'DeepLinkResolveState(busy: $busy, error: $error)';
  }
}

class DeepLinkResolver extends Notifier<DeepLinkResolveState> {
  @override
  DeepLinkResolveState build() => const DeepLinkResolveState();

  /// Resolve a durable session id from a deep link. If the id is already the
  /// active session, no-op. If it's in the session list and has a known live
  /// id, switch to it via [SessionActions.switchToSummary]. Otherwise fall
  /// back to `session.resume` to re-activate it.
  ///
  /// Never throws — errors land in state.
  Future<void> resolve(String durableId) async {
    if (state.busy) {
      return;
    }

    // No-op if already active.
    final active = ref.read(activeSessionProvider);
    if (active.durableId == durableId) {
      state = const DeepLinkResolveState();
      return;
    }

    state = const DeepLinkResolveState(busy: true);

    // Check if the durable id is in the session list.
    final sessionListAsync = ref.read(sessionListProvider);
    final sessions = sessionListAsync.value ?? const [];
    final summary = sessions.where((s) => s.durableId == durableId).firstOrNull;

    if (summary != null) {
      // Use the existing switch logic (handles live id reuse, resume, etc.).
      final errorMessage = await ref
          .read(sessionActionsProvider)
          .switchToSummary(summary);
      if (errorMessage != null) {
        state = DeepLinkResolveState(error: errorMessage);
        return;
      }
      state = const DeepLinkResolveState();
      return;
    }

    // Not in the session list — fall back to direct resume.
    final repository = ref.read(sessionRepositoryProvider);
    if (repository == null) {
      state = const DeepLinkResolveState(error: 'Not connected to a gateway.');
      return;
    }

    try {
      final result = await repository.resume(durableId);
      ref
          .read(activeSessionProvider.notifier)
          .switchTo(liveId: result.liveId, durableId: result.durableId);
      // Seed the replayed history (wire §5).
      ref
          .read(messageListProvider(result.liveId).notifier)
          .seedHistory(result.messages, inflight: result.inflight);
      state = const DeepLinkResolveState();
    } on GatewayException catch (error) {
      state = DeepLinkResolveState(error: error.message);
    } on Object catch (error) {
      state = DeepLinkResolveState(error: 'Failed to resume session: $error');
    }
  }

  /// Clear the error state.
  void clearError() {
    state = DeepLinkResolveState(busy: state.busy);
  }
}
