/// Terminal read prompt card (P3-08): renders a `terminal.read.request`
/// (correlated BY request_id). Since a Flutter gateway client has no terminal
/// buffer, this card explains the request and provides a way to either send
/// empty text to unblock the agent, or paste text to send.
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key of the terminal text field.
const Key terminalReadFieldKey = Key('terminal_read_field');

/// Key of the submit button.
const Key terminalReadSubmitKey = Key('terminal_read_submit');

/// A pending terminal read request. Since a Flutter client has no terminal
/// buffer, the user can either send empty text or paste text to send.
class TerminalReadPromptCard extends ConsumerStatefulWidget {
  const TerminalReadPromptCard({
    required this.prompt,
    required this.liveId,
    super.key,
  });

  final TerminalReadPrompt prompt;

  /// The live session id of the message list this card renders in — used
  /// for the fold-state dismissal (the respond call itself is keyed by
  /// request id, §8.1).
  final String liveId;

  @override
  ConsumerState<TerminalReadPromptCard> createState() =>
      _TerminalReadPromptCardState();
}

class _TerminalReadPromptCardState
    extends ConsumerState<TerminalReadPromptCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _answer(String text) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          ?.respondTerminalRead(widget.prompt.requestId, text);
    } on Object catch (error) {
      if (mounted) {
        final detail = error is GatewayException ? error.message : '$error';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to answer: $detail')));
      }
      return; // keep the card — the answer did not reach the gateway.
    }
    ref
        .read(messageListProvider(widget.liveId).notifier)
        .dismissPrompt(widget.prompt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = widget.prompt.start;
    final count = widget.prompt.count;
    final rangeText = start != null || count != null
        ? ' (start: $start, count: $count)'
        : '';
    return Card(
      color: scheme.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.terminal,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terminal read requested',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The agent has requested terminal buffer contents$rangeText. This Flutter client has no terminal buffer.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => _answer(''),
                  child: const Text('Send empty'),
                ),
                const SizedBox(width: 8),
                const Text('or paste text below:'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: terminalReadFieldKey,
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Paste terminal contents here (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                key: terminalReadSubmitKey,
                tooltip: 'Send text',
                onPressed: () => _answer(_controller.text),
                icon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
