/// Secret prompt card (P3-08): renders a `secret.request` (protocol §8.1 —
/// correlated BY request_id). A secure text field for the user to provide
/// a secret value (e.g. an API key).
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key of the secret value field.
const Key secretFieldKey = Key('secret_field');

/// Key of the submit button.
const Key secretSubmitKey = Key('secret_submit');

/// A pending secret value request. The secret value goes through the chat
/// repository keyed by [SecretPrompt.requestId]; the prompt is then dismissed
/// from the fold state.
class SecretPromptCard extends ConsumerStatefulWidget {
  const SecretPromptCard({
    required this.prompt,
    required this.liveId,
    super.key,
  });

  final SecretPrompt prompt;

  /// The live session id of the message list this card renders in — used
  /// for the fold-state dismissal (the respond call itself is keyed by
  /// request id, §8.1).
  final String liveId;

  @override
  ConsumerState<SecretPromptCard> createState() => _SecretPromptCardState();
}

class _SecretPromptCardState extends ConsumerState<SecretPromptCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _answer(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await ref
          .read(chatRepositoryProvider)
          ?.respondSecret(widget.prompt.requestId, trimmed);
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
                Icon(Icons.key, size: 18, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secret required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.prompt.prompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.prompt.envVar,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: secretFieldKey,
                    controller: _controller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Enter secret value',
                    ),
                    onSubmitted: _answer,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: secretSubmitKey,
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
