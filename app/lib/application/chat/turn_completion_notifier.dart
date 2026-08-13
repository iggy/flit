/// Turn completion tracking for notifications and UI feedback.
///
/// Listens for turn completion events and exposes state for:
/// - Sound notifications (when enabled)
/// - Desktop notifications (when enabled)
/// - Visual indicators (checkmark animation, etc.)
library;

import 'dart:async';

import 'package:flit/application/chat/message_fold.dart';
import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for turn completion tracking.
class TurnCompletionState {
  const TurnCompletionState({
    this.lastCompletedTime,
    this.wasInterrupted = false,
    this.hadError = false,
  });

  /// When the last turn completed.
  final DateTime? lastCompletedTime;

  /// Whether the last turn was interrupted.
  final bool wasInterrupted;

  /// Whether the last turn ended with an error.
  final bool hadError;

  TurnCompletionState copyWith({
    DateTime? lastCompletedTime,
    bool? wasInterrupted,
    bool? hadError,
  }) {
    return TurnCompletionState(
      lastCompletedTime: lastCompletedTime ?? this.lastCompletedTime,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
      hadError: hadError ?? this.hadError,
    );
  }
}

/// Notifier that tracks turn completion events.
class TurnCompletionNotifier extends Notifier<TurnCompletionState> {
  @override
  TurnCompletionState build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) return;

      final event = parseGatewayEvent(raw);
      _handleEvent(event);
    });

    // Also watch message list for terminal status changes
    final liveId = ref.watch(activeSessionProvider).liveId;
    if (liveId != null) {
      ref.listen(messageListProvider(liveId), _checkMessageListForCompletion);
    }

    return const TurnCompletionState();
  }

  void _handleEvent(TypedGatewayEvent event) {
    switch (event) {
      case MessageComplete(:final status):
        _onTurnComplete(
          interrupted: status == MessageTerminalStatus.interrupted,
          error: status == MessageTerminalStatus.error,
        );
      case TurnError():
        _onTurnComplete(interrupted: false, error: true);
      default:
        break;
    }
  }

  void _checkMessageListForCompletion(FoldState? previous, FoldState next) {
    if (next.messages.isEmpty) return;

    // Check if the last message just completed streaming
    final lastMessage = next.messages.last;
    if (lastMessage.role != MessageRole.assistant) return;
    if (lastMessage.streaming) return;

    // Check if there was a previous message in the same position
    if (previous != null &&
        previous.messages.isNotEmpty &&
        previous.messages.last.role == MessageRole.assistant) {
      final prevLast = previous.messages.last;

      // If it was streaming before and is now complete, trigger notification
      if (prevLast.streaming && !lastMessage.streaming) {
        _onTurnComplete(
          interrupted:
              lastMessage.terminalStatus == MessageTerminalStatus.interrupted,
          error: lastMessage.terminalStatus == MessageTerminalStatus.error,
        );
      }
    }
  }

  void _onTurnComplete({required bool interrupted, required bool error}) {
    state = TurnCompletionState(
      lastCompletedTime: DateTime.now(),
      wasInterrupted: interrupted,
      hadError: error,
    );

    // Notification logic placeholder:
    // When user preferences are available, implement:
    // - Play sound notification (if enabled)
    // - Show desktop notification (if enabled and app is in background)
    // The flutter_local_notifications package is already in pubspec.yaml
  }

  /// Clear the last completion state (acknowledge).
  void clear() {
    state = const TurnCompletionState();
  }
}

/// Provider for turn completion state.
final turnCompletionProvider =
    NotifierProvider<TurnCompletionNotifier, TurnCompletionState>(
      TurnCompletionNotifier.new,
    );

/// Stream of turn completion events (for one-shot listeners).
final turnCompletionEventsProvider = StreamProvider<DateTime?>((ref) {
  final controller = StreamController<DateTime?>.broadcast();

  ref.listen(gatewayEventsProvider, (previous, next) {
    final raw = next.value;
    if (raw == null) return;

    final event = parseGatewayEvent(raw);
    switch (event) {
      case MessageComplete():
        controller.add(DateTime.now());
      case TurnError():
        controller.add(DateTime.now());
      default:
        break;
    }
  });

  ref.onDispose(controller.close);
  return controller.stream;
});
