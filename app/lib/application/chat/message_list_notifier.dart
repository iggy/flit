/// The message-list notifier (ticket P1-06): a thin Riverpod wrapper around
/// the pure [foldGatewayEvent] reducer. All folding logic lives in
/// message_fold.dart; this class only owns the subscription and the
/// caller-initiated mutations (composer messages, prompt dismissal).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flit/application/chat/message_fold.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flit/domain/models/session_detail.dart';

/// Per-session chat state, keyed by the LIVE session id (protocol §9).
///
/// Riverpod 3 note: `FamilyNotifier` was removed in Riverpod 3.x — family
/// arguments now arrive via the notifier constructor (`MessageListNotifier.new`
/// is torn off as `MessageListNotifier Function(String)`).
final messageListProvider =
    NotifierProvider.family<MessageListNotifier, FoldState, String>(
      MessageListNotifier.new,
    );

class MessageListNotifier extends Notifier<FoldState> {
  MessageListNotifier(this.liveId);

  /// The LIVE session id this list belongs to — the family argument.
  final String liveId;

  @override
  FoldState build() {
    final repository = ref.watch(chatRepositoryProvider);
    if (repository == null) {
      // Disconnected: an empty list. build() re-runs when a client appears,
      // subscribing to the fresh repository then.
      return const FoldState();
    }
    final subscription = repository.turnEvents(liveId).listen(_fold);
    // Cancelled on dispose AND on rebuild (client swap → re-subscribe).
    ref.onDispose(subscription.cancel);
    return const FoldState();
  }

  void _fold(TypedGatewayEvent event) {
    state = foldGatewayEvent(state, event);
  }

  /// Append a user message from the composer. User messages are appended by
  /// the CALLER, never by the fold (04-app-architecture.md).
  void appendUserMessage(String text) {
    state = state.copyWith(
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(
          role: MessageRole.user,
          text: text,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Replace the list with a RESUMED session's replayed history (wire §5;
  /// ticket P1-10). This provider starts empty and only folds NEW events,
  /// so the history returned by `session.resume` is seeded here on switch.
  ///
  /// The resume DTO already maps role/text; every replayed message is
  /// terminal and non-streaming (assistant turns are marked
  /// [MessageTerminalStatus.complete]), and no prompts are pending.
  ///
  /// When [inflight] is non-null (protocol P2-02), reconcile the inflight
  /// turn snapshot — the turn was streaming when the socket dropped — by
  /// appending it to the finalized history so the user sees the in-progress
  /// turn.
  void seedHistory(List<ChatMessage> messages, {InflightTurn? inflight}) {
    final historyMessages = messages.map((message) {
      return message.copyWith(
        streaming: false,
        terminalStatus:
            message.role == MessageRole.assistant &&
                message.terminalStatus == MessageTerminalStatus.none
            ? MessageTerminalStatus.complete
            : message.terminalStatus,
      );
    }).toList();

    final inflightMessages = <ChatMessage>[];
    if (inflight != null) {
      // Append the user message if the prompt is non-empty.
      if (inflight.user.isNotEmpty) {
        inflightMessages.add(
          ChatMessage(
            role: MessageRole.user,
            text: inflight.user,
          ),
        );
      }
      // Append the assistant message if the response is non-empty OR if
      // streaming is true (an empty streaming bubble must exist for the fold
      // to append NEW deltas to it).
      if (inflight.assistant.isNotEmpty || inflight.streaming) {
        inflightMessages.add(
          ChatMessage(
            role: MessageRole.assistant,
            text: inflight.assistant,
            streaming: inflight.streaming,
            terminalStatus: inflight.streaming
                ? MessageTerminalStatus.none
                : MessageTerminalStatus.complete,
          ),
        );
      }
    }

    state = FoldState(
      messages: <ChatMessage>[...historyMessages, ...inflightMessages],
    );
  }

  /// Remove [prompt] from [FoldState.pendingPrompts] once it has been
  /// answered (via ChatRepository) or dismissed. The fold only ever ADDS
  /// prompts; removal is the notifier's job.
  void dismissPrompt(InteractivePrompt prompt) {
    state = state.copyWith(
      pendingPrompts: state.pendingPrompts
          .where((candidate) => candidate != prompt)
          .toList(),
    );
  }
}
