/// One flit session's live chat: attaches to the session's event log,
/// folds it with [foldFlitEvent], and reattaches from the last seen seq when
/// the stream drops, so nothing is lost and nothing is shown twice.
library;

import 'dart:async';

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the event stream behind a session view.
enum FlitLink {
  /// First attach in progress.
  connecting,

  /// Replayed and following live.
  live,

  /// Dropped; reattaching soon.
  reconnecting,

  /// No flit connection at all.
  offline,
}

/// A session view: the folded log plus the stream's health.
final class FlitChatState {
  const FlitChatState({
    this.fold = const FlitFoldState(),
    this.link = FlitLink.connecting,
    this.linkError,
  });

  final FlitFoldState fold;
  final FlitLink link;

  /// Why the last attach failed, while [link] is reconnecting.
  final String? linkError;

  FlitChatState copyWith({
    FlitFoldState? fold,
    FlitLink? link,
    String? linkError,
  }) {
    return FlitChatState(
      fold: fold ?? this.fold,
      link: link ?? this.link,
      linkError: linkError,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlitChatState &&
      other.fold == fold &&
      other.link == link &&
      other.linkError == linkError;

  @override
  int get hashCode => Object.hash(fold, link, linkError);
}

/// Per-session chat state, keyed by session id.
final flitChatProvider =
    NotifierProvider.family<FlitChatNotifier, FlitChatState, String>(
      FlitChatNotifier.new,
    );

class FlitChatNotifier extends Notifier<FlitChatState> {
  FlitChatNotifier(this.sessionId);

  final String sessionId;

  FlitRepository? _repository;
  StreamSubscription<FlitEvent>? _subscription;
  Timer? _retry;
  int _attempt = 0;

  @override
  FlitChatState build() {
    _repository = ref.watch(flitRepositoryProvider);
    ref.onDispose(_stop);
    if (_repository == null) {
      return const FlitChatState(link: FlitLink.offline);
    }
    // Attach after build returns, so the first events fold into this state.
    Future<void>.microtask(_attach);
    return const FlitChatState();
  }

  void _stop() {
    _retry?.cancel();
    _retry = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _attach() {
    final repository = _repository;
    if (repository == null || !ref.mounted) {
      return;
    }
    _stop();
    _subscription = repository
        .attach(sessionId, fromSeq: state.fold.lastSeq + 1)
        .listen(
          _onEvent,
          onError: (Object error) => _dropped(
            error is GatewayException ? error.message : error.toString(),
          ),
          onDone: () => _dropped(null),
        );
    // Optimistic: the server sends nothing for an idle session, so there is
    // no event to wait for. A failed attach flips this to reconnecting.
    if (state.link != FlitLink.live) {
      state = state.copyWith(link: FlitLink.live);
    }
  }

  void _onEvent(FlitEvent event) {
    if (!ref.mounted) {
      return;
    }
    _attempt = 0;
    state = state.copyWith(
      fold: foldFlitEvent(state.fold, event),
      link: FlitLink.live,
    );
  }

  void _dropped(String? error) {
    if (!ref.mounted) {
      return;
    }
    _subscription = null;
    state = state.copyWith(link: FlitLink.reconnecting, linkError: error);
    final delay = ref.read(flitReconnectDelayProvider)(_attempt++);
    _retry?.cancel();
    _retry = Timer(delay, _attach);
  }

  /// Reattach right away (pull-to-refresh, app resumed).
  void reconnectNow() {
    _attempt = 0;
    _attach();
  }

  /// Sends a user message. Returns an error message, or null on success.
  /// The message appears when the server records it, like on every client.
  Future<String?> send(String text) {
    return _run((r) => r.send(sessionId, text));
  }

  /// Stops the running turn.
  Future<String?> interrupt() {
    return _run((r) => r.interrupt(sessionId));
  }

  /// Answers a prompt as this device. The prompt disappears from every
  /// client once the server records the answer.
  Future<String?> answer(
    String promptId, {
    required bool allow,
    bool forSession = false,
  }) {
    final client = ref.read(flitDeviceNameProvider);
    return _run(
      (r) => r.answerPrompt(
        sessionId,
        promptId,
        allow: allow,
        forSession: forSession,
        client: client,
      ),
    );
  }

  /// Marks the turn that produced [messageId] as good or bad.
  Future<String?> rateTurn(String messageId, {required bool good}) {
    return _run(
      (r) => r.rate(
        sessionId,
        target: FlitRatingTarget.turn,
        good: good,
        messageId: messageId,
      ),
    );
  }

  /// Marks the session's current model as a good or bad choice.
  Future<String?> rateModel({required bool good}) {
    return _run(
      (r) => r.rate(sessionId, target: FlitRatingTarget.model, good: good),
    );
  }

  Future<String?> _run(Future<Object?> Function(FlitRepository) call) async {
    final repository = _repository;
    if (repository == null) {
      return 'Not connected to a flit server.';
    }
    try {
      await call(repository);
      return null;
    } on GatewayException catch (error) {
      return error.message;
    } on Object catch (error) {
      return error.toString();
    }
  }
}
