/// Sudo prompt card (P3-08): renders a `sudo.request` (protocol §8.1 —
/// correlated BY request_id). A password field for the user to provide
/// their sudo password to the agent.
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key of the password field.
const Key sudoFieldKey = Key('sudo_field');

/// Key of the submit button.
const Key sudoSubmitKey = Key('sudo_submit');

/// A pending sudo password request. The password goes through the chat
/// repository keyed by [SudoPrompt.requestId]; the prompt is then dismissed
/// from the fold state.
class SudoPromptCard extends ConsumerStatefulWidget {
  const SudoPromptCard({required this.prompt, required this.liveId, super.key});

  final SudoPrompt prompt;

  /// The live session id of the message list this card renders in — used
  /// for the fold-state dismissal (the respond call itself is keyed by
  /// request id, §8.1).
  final String liveId;

  @override
  ConsumerState<SudoPromptCard> createState() => _SudoPromptCardState();
}

class _SudoPromptCardState extends ConsumerState<SudoPromptCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _answer(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await ref
          .read(chatRepositoryProvider)
          ?.respondSudo(widget.prompt.requestId, trimmed);
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
                  Icons.password,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Password required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The agent needs your sudo password to continue.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: sudoFieldKey,
                    controller: _controller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Enter password',
                    ),
                    onSubmitted: _answer,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: sudoSubmitKey,
                  tooltip: 'Submit',
                  onPressed: () => _answer(_controller.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
