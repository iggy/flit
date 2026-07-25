library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/dto/session_dtos.dart';
import 'package:flit/domain/models/session_detail.dart';

/// `session.usage` query for the active session (Phase 2, §session.usage).
/// Returns null when disconnected or no active session; surfaces RPC errors as
/// [AsyncError].
final sessionUsageProvider = FutureProvider<SessionUsageStats?>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final liveId = ref.watch(activeSessionProvider).liveId;
  if (repo == null || liveId == null) {
    return null;
  }
  return repo.usage(liveId);
});

/// `session.context_breakdown` query for the active session (Phase 2,
/// §session.context_breakdown). Returns null when disconnected or no active
/// session; surfaces RPC errors as [AsyncError].
final contextBreakdownProvider = FutureProvider<ContextBreakdown?>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final liveId = ref.watch(activeSessionProvider).liveId;
  if (repo == null || liveId == null) {
    return null;
  }
  return repo.contextBreakdown(liveId);
});

/// `session.most_recent` query (Phase 2, §session.most_recent) — returns the
/// most recent eligible session for resuming, or null when disconnected or no
/// session found. Surfaces RPC errors as [AsyncError].
final mostRecentSessionProvider = FutureProvider<MostRecentSession?>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  if (repo == null) {
    return null;
  }
  return repo.mostRecent();
});

/// Live session-info notifier tracking the latest [SessionUsageStats] from
/// `session.info` events (so the UI live-updates after each turn WITHOUT an
/// extra RPC). State starts null and is updated by each `session.info` event
/// that carries a `usage` sub-dict.
final liveUsageProvider = NotifierProvider<LiveUsageNotifier, SessionUsageStats?>(
  LiveUsageNotifier.new,
);

class LiveUsageNotifier extends Notifier<SessionUsageStats?> {
  @override
  SessionUsageStats? build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        final usage = event.info['usage'];
        if (usage is Map<String, dynamic>) {
          state = SessionUsageDto.fromJson(usage).toDomain();
        }
      }
    });
    return null;
  }
}
