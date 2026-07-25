/// The spawn-tree notifier (ticket P3-04): a thin Riverpod wrapper around
/// the pure [foldSubagentEvent] reducer. All folding logic lives in
/// spawn_tree_fold.dart; this class only owns the subscription.
library;

import 'package:flit/application/providers.dart';
import 'package:flit/application/subagents/spawn_tree_fold.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-session spawn-tree state, keyed by the LIVE session id (protocol §9).
///
/// Riverpod 3 note: `FamilyNotifier` was removed in Riverpod 3.x — family
/// arguments now arrive via the notifier constructor (`SpawnTreeNotifier.new`
/// is torn off as `SpawnTreeNotifier Function(String)`).
final spawnTreeProvider =
    NotifierProvider.family<SpawnTreeNotifier, SpawnTreeState, String>(
      SpawnTreeNotifier.new,
    );

class SpawnTreeNotifier extends Notifier<SpawnTreeState> {
  SpawnTreeNotifier(this.liveId);

  /// The LIVE session id this tree belongs to — the family argument.
  final String liveId;

  @override
  SpawnTreeState build() {
    final repository = ref.watch(chatRepositoryProvider);
    if (repository == null) {
      // Disconnected: an empty tree. build() re-runs when a client appears,
      // subscribing to the fresh repository then.
      return const SpawnTreeState();
    }
    final subscription = repository.turnEvents(liveId).listen(_fold);
    // Cancelled on dispose AND on rebuild (client swap → re-subscribe).
    ref.onDispose(subscription.cancel);
    return const SpawnTreeState();
  }

  void _fold(TypedGatewayEvent event) {
    if (event is SubagentEvent) {
      state = foldSubagentEvent(state, event);
    }
  }
}
