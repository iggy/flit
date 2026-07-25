/// The composer (ticket P1-07): a multiline text field with a Send button.
/// While the active session is streaming/working the Send button becomes a
/// Stop button that calls `session.interrupt`. Disabled with a hint when
/// there is no active session.
///
/// Key handling: Enter submits (when the field is effectively used
/// single-line, the common chat case); Shift+Enter inserts a newline.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';

/// Key of the composer's text field (widget tests target it directly).
const Key composerFieldKey = Key('composer_field');

/// Key of the send button.
const Key composerSendKey = Key('composer_send');

/// Key of the stop button (shown while a turn is in flight).
const Key composerStopKey = Key('composer_stop');

class Composer extends ConsumerStatefulWidget {
  const Composer({super.key});

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Enter → submit; Shift+Enter → let the editable insert a newline.
  /// The handler lives on the focus NODE so it runs before the editable's
  /// own Enter handling (which would otherwise consume the event).
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final shiftHeld =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    if (shiftHeld) {
      return KeyEventResult.ignored;
    }
    _submit();
    return KeyEventResult.handled;
  }

  void _submit() {
    final liveId = ref.read(activeSessionProvider).liveId;
    if (liveId == null) {
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _controller.clear();
    // User messages are appended by the CALLER, never by the fold
    // (04-app-architecture.md).
    ref.read(messageListProvider(liveId).notifier).appendUserMessage(text);
    unawaited(_send(liveId, text));
  }

  Future<void> _send(String liveId, String text) async {
    try {
      await ref.read(chatRepositoryProvider)?.submitPrompt(liveId, text);
    } on Object catch (error) {
      _showError('Failed to send', error);
    }
  }

  Future<void> _stop(String liveId) async {
    try {
      await ref.read(sessionRepositoryProvider)?.interrupt(liveId);
    } on Object catch (error) {
      _showError('Failed to stop', error);
    }
  }

  void _showError(String prefix, Object error) {
    if (!mounted) {
      return;
    }
    final detail = error is GatewayException ? error.message : '$error';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$prefix: $detail')));
  }

  @override
  Widget build(BuildContext context) {
    final liveId = ref.watch(activeSessionProvider).liveId;
    final fold = liveId == null ? null : ref.watch(messageListProvider(liveId));
    // A turn is in flight while its assistant message is still streaming —
    // the fold flips `streaming` off on the terminal event (protocol §6).
    final working = fold?.messages.any((message) => message.streaming) ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              key: composerFieldKey,
              controller: _controller,
              focusNode: _focusNode,
              enabled: liveId != null,
              minLines: 1,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                isDense: true,
                hintText: liveId == null
                    ? 'No active session'
                    : 'Message Hermes…',
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (working && liveId != null)
            IconButton.filled(
              key: composerStopKey,
              tooltip: 'Stop',
              onPressed: () => unawaited(_stop(liveId)),
              icon: const Icon(Icons.stop),
            )
          else
            IconButton.filled(
              key: composerSendKey,
              tooltip: 'Send',
              onPressed: liveId == null ? null : _submit,
              icon: const Icon(Icons.send),
            ),
        ],
      ),
    );
  }
}
