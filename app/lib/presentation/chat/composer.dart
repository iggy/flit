/// The composer (ticket P1-07): a multiline text field with a Send button.
/// While the active session is streaming/working, submitting non-empty text
/// steers the running turn (P3-07) instead of starting a new turn. The Stop
/// button calls `session.interrupt`. Disabled with a hint when there is no
/// active session.
///
/// P3-02: inline slash autocomplete — when text starts with `/` (no space yet),
/// show completions above the field; tapping a suggestion replaces the text.
///
/// P3-03: slash dispatch — text starting with `/` is routed to command.dispatch
/// instead of submitPrompt; dispatch results fan out to prefill/send/exec/skill.
///
/// Key handling: Enter submits (when the field is effectively used
/// single-line, the common chat case); Shift+Enter inserts a newline.
library;

import 'dart:async';

import 'package:flit/application/chat/composer_prefill.dart';
import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/slash/slash_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/slash_completion.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key of the composer's text field (widget tests target it directly).
const Key composerFieldKey = Key('composer_field');

/// Key of the send button.
const Key composerSendKey = Key('composer_send');

/// Key of the stop button (shown while a turn is in flight).
const Key composerStopKey = Key('composer_stop');

/// Key of the steer button (shown while a turn is in flight).
const Key composerSteerKey = Key('composer_steer');

class Composer extends ConsumerStatefulWidget {
  const Composer({super.key});

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);

  /// P3-02: slash suggestions (null when none; empty list triggers no overlay).
  List<CompletionItem>? _suggestions;

  /// Request generation counter to ignore stale async completeSlash results.
  int _completionRequestGen = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// P3-02: trigger autocomplete on text change.
  void _onTextChanged() {
    final text = _controller.text;
    // Trigger only when text starts with `/` and has no space yet.
    if (text.startsWith('/') && !text.contains(' ')) {
      _fetchCompletions(text);
    } else {
      setState(() {
        _suggestions = null;
      });
    }
  }

  /// P3-02: fetch completions from the repository, guarding against overlapping requests.
  Future<void> _fetchCompletions(String text) async {
    final repo = ref.read(slashRepositoryProvider);
    if (repo == null) {
      return;
    }
    _completionRequestGen++;
    final thisGen = _completionRequestGen;
    try {
      final result = await repo.completeSlash(text);
      if (thisGen == _completionRequestGen && mounted) {
        setState(() {
          _suggestions = result.items;
        });
      }
    } on Object {
      // Silently ignore completion failures (e.g., disconnected mid-request).
      if (thisGen == _completionRequestGen && mounted) {
        setState(() {
          _suggestions = null;
        });
      }
    }
  }

  /// P3-02: replace field text with the selected completion item.
  void _applySuggestion(CompletionItem item) {
    _controller.text = item.text;
    _controller.selection = TextSelection.collapsed(offset: item.text.length);
    setState(() {
      _suggestions = null;
    });
    _focusNode.requestFocus();
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
    // P3-03: route slash commands to dispatch.
    if (text.startsWith('/')) {
      _controller.clear();
      setState(() {
        _suggestions = null;
      });
      unawaited(_dispatchSlash(liveId, text));
      return;
    }
    final working = ref.read(messageListProvider(liveId)).messages
        .any((message) => message.streaming);
    _controller.clear();
    setState(() {
      _suggestions = null;
    });
    if (working) {
      unawaited(_steer(liveId, text));
      return;
    }
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

  Future<void> _steer(String liveId, String text) async {
    try {
      final outcome = await ref.read(sessionRepositoryProvider)?.steer(liveId, text);
      if (outcome == SteerOutcome.rejected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Steer rejected by the agent')),
        );
      }
    } on Object catch (error) {
      _showError('Failed to steer', error);
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

  /// P3-03: dispatch a slash command and handle the discriminated result.
  Future<void> _dispatchSlash(String liveId, String raw, [int depth = 0]) async {
    if (depth > 3) {
      _showSnackBar('Command alias loop detected');
      return;
    }
    final repo = ref.read(slashRepositoryProvider);
    if (repo == null) {
      return;
    }
    // Split name and arg: first whitespace-delimited token vs. remainder.
    final parts = raw.trim().split(RegExp(r'\s+'));
    final name = parts.first;
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      final result = await repo.dispatch(
        name: name,
        arg: arg,
        sessionId: liveId,
      );
      if (!mounted) {
        return;
      }

      switch (result) {
        case DispatchPrefill():
          // Populate the composer field.
          _controller.text = result.message;
          _controller.selection =
              TextSelection.collapsed(offset: result.message.length);
          _focusNode.requestFocus();
          _showSnackBar(result.notice);
        case DispatchSend():
          // Submit message as a user turn.
          if (result.notice != null) {
            _showSnackBar(result.notice!);
          }
          ref
              .read(messageListProvider(liveId).notifier)
              .appendUserMessage(result.message);
          unawaited(_send(liveId, result.message));
        case DispatchExec():
          // Show rendered output.
          _showSnackBar(result.output);
        case DispatchSkill():
          // Show skill message.
          _showSnackBar('${result.name}: ${result.message}');
        case DispatchAlias():
          // Resolve alias one hop (recursively).
          final targetWithArg = arg.isEmpty
              ? result.target
              : '${result.target} $arg';
          unawaited(_dispatchSlash(liveId, targetWithArg, depth + 1));
        case DispatchUnknown():
          _showSnackBar('Unknown command result: ${result.rawType}');
      }
    } on Object catch (error) {
      _showError('Command failed', error);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveId = ref.watch(activeSessionProvider).liveId;
    final fold = liveId == null ? null : ref.watch(messageListProvider(liveId));
    // A turn is in flight while its assistant message is still streaming —
    // the fold flips `streaming` off on the terminal event (protocol §6).
    final working = fold?.messages.any((message) => message.streaming) ?? false;

    // P3-03: consume prefill once (from slash launcher selection).
    ref.listen(composerPrefillProvider, (previous, next) {
      if (next != null) {
        _controller.text = next;
        _controller.selection = TextSelection.collapsed(offset: next.length);
        _focusNode.requestFocus();
        ref.read(composerPrefillProvider.notifier).clear();
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // P3-02: suggestion overlay (shown above the field when non-empty).
          if (_suggestions != null && _suggestions!.isNotEmpty)
            _buildSuggestionOverlay(),
          Row(
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
              if (working && liveId != null) ...<Widget>[
                IconButton.filled(
                  key: composerSteerKey,
                  tooltip: 'Steer',
                  onPressed: _submit,
                  icon: const Icon(Icons.alt_route),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: composerStopKey,
                  tooltip: 'Stop',
                  onPressed: () => unawaited(_stop(liveId)),
                  icon: const Icon(Icons.stop),
                ),
              ] else
                IconButton.filled(
                  key: composerSendKey,
                  tooltip: 'Send',
                  onPressed: liveId == null ? null : _submit,
                  icon: const Icon(Icons.send),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// P3-02: build the suggestion list overlay above the field.
  Widget _buildSuggestionOverlay() {
    final suggestions = _suggestions!;
    return Container(
      key: const Key('slash_suggestions'),
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final item = suggestions[index];
            return ListTile(
              key: ValueKey('slash_suggestion_${item.display}'),
              dense: true,
              title: Text(
                item.display,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: item.meta.isNotEmpty ? Text(item.meta) : null,
              onTap: () => _applySuggestion(item),
            );
          },
        ),
      ),
    );
  }
}
