/// The client-side view of the gateway's per-session prompt queue.
///
/// A `prompt.submit` that lands mid-turn comes back `queued` (gateway 0.20
/// `_handle_busy_submit`, server.py:7501) — the text is stashed in the
/// session's `queued_prompt` and fired as the next turn once the live one
/// ends. Nothing on the wire ever reports the queue back, so the client
/// remembers what it queued in order to show it and to know when it is gone.
///
/// Two things empty the queue, and they are NOT the same event:
///
/// - The turn ends: the gateway drains the queue into the next turn
///   (`_drain_queued_prompt`, server.py:7585). The queued text becomes a real
///   turn, so the entries simply retire.
/// - `session.interrupt`: the gateway CLEARS `queued_prompt` /
///   `queued_prompts` and bumps `_queued_prompt_generation`
///   (methods_session.py:2916, 2942) — the queued messages are DISCARDED and
///   never run. The user has to resend them, so this one has to be visible;
///   [PromptQueue.dropped] carries the count for exactly one read.
///
/// The two are told apart by which one the CLIENT asked for, not by the frame:
/// an interrupt's `message.complete{status:"interrupted"}` looks like any other
/// turn-terminal frame and can arrive BEFORE the interrupt response does. So an
/// interrupt is bracketed ([beginInterrupt] → [endInterrupt]) and any terminal
/// frame inside that bracket counts as a drop.
library;

import 'package:flit/application/providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One session's queued prompts plus the size of the last discarded batch.
final class PromptQueue {
  const PromptQueue({this.texts = const <String>[], this.dropped = 0});

  /// The messages waiting behind the running turn, in submit order.
  ///
  /// A count of MESSAGES, not of gateway queue slots: `_enqueue_prompt`
  /// (server.py:7427) merges consecutive text-only submissions into one slot,
  /// so one drained turn can carry several of these entries.
  final List<String> texts;

  /// How many queued messages the last [PromptQueueNotifier.dropAll] threw
  /// away, until read via [PromptQueueNotifier.acknowledgeDropped]. Zero at
  /// rest — a drain is not a drop.
  final int dropped;

  bool get isEmpty => texts.isEmpty;

  @override
  bool operator ==(Object other) {
    return other is PromptQueue &&
        other.dropped == dropped &&
        deepListEquals(other.texts, texts);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(texts), dropped);

  @override
  String toString() => 'PromptQueue(texts: $texts, dropped: $dropped)';
}

/// Queued prompts for one session, keyed by the LIVE session id (protocol §9)
/// — the id `prompt.submit` and `session.interrupt` both speak.
final promptQueueProvider =
    NotifierProvider.family<PromptQueueNotifier, PromptQueue, String>(
      PromptQueueNotifier.new,
    );

class PromptQueueNotifier extends Notifier<PromptQueue> {
  PromptQueueNotifier(this.liveId);

  /// The LIVE session id this queue belongs to — the family argument.
  final String liveId;

  /// Whether a `session.interrupt` for [liveId] is in flight, so a terminal
  /// frame arriving meanwhile is a discard rather than a drain.
  bool _interrupting = false;

  @override
  PromptQueue build() {
    final repository = ref.watch(chatRepositoryProvider);
    if (repository == null) {
      return const PromptQueue();
    }
    // Turn-terminal frames are BOTH `message.complete` (any status) and
    // `error` (protocol §6); either one means the gateway is about to drain.
    final subscription = repository.turnEvents(liveId).listen((event) {
      if (event is MessageComplete || event is TurnError) {
        if (_interrupting) {
          dropAll();
        } else {
          _drain();
        }
      }
    });
    ref.onDispose(subscription.cancel);
    // Reset on client swap (reconnect): the queue we remembered belonged to
    // the old connection, and no wire shape reports the gateway's back.
    return const PromptQueue();
  }

  /// Record a prompt the gateway acknowledged as `queued`.
  void enqueue(String text) {
    state = PromptQueue(texts: <String>[...state.texts, text]);
  }

  /// The queue ran: retire the entries WITHOUT flagging a drop.
  void _drain() {
    if (state.texts.isEmpty && state.dropped == 0) {
      return;
    }
    state = const PromptQueue();
  }

  /// Mark a `session.interrupt` as in flight: from here until [endInterrupt],
  /// a turn-terminal frame is the interrupt landing, not a drain.
  void beginInterrupt() {
    _interrupting = true;
  }

  /// The interrupt settled (either way). [dropAll] has normally already run —
  /// from the response or from the terminal frame, whichever came first.
  void endInterrupt() {
    _interrupting = false;
  }

  /// `session.interrupt` discarded the queue — retire the entries and flag
  /// how many were lost so the UI can say so. Idempotent: the response and
  /// the terminal frame race, and only the first one to arrive reports.
  void dropAll() {
    if (state.texts.isEmpty) {
      return;
    }
    state = PromptQueue(dropped: state.texts.length);
  }

  /// Clear [PromptQueue.dropped] once the drop has been reported.
  void acknowledgeDropped() {
    if (state.dropped == 0) {
      return;
    }
    state = PromptQueue(texts: state.texts);
  }
}
