/// Clarify prompt card (ticket P1-08): renders a `clarify.request`
/// (protocol §8.1 — correlated BY request_id, do NOT cross with approval's
/// by-session model). With `choices` it shows choice chips; `choices: null`
/// means free text (a field + submit).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/chat/message_list_notifier.dart';
import 'package:hermes/application/providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/domain/models/interactive_prompt.dart';

/// Key of the free-text answer field (choices == null).
const Key clarifyFieldKey = Key('clarify_field');

/// Key of the free-text submit button.
const Key clarifySubmitKey = Key('clarify_submit');

/// A pending clarification question. Answers go through the chat
/// repository keyed by [ClarifyPrompt.requestId]; the prompt is then
/// dismissed from the fold state.
class ClarifyPromptCard extends ConsumerStatefulWidget {
  const ClarifyPromptCard({
    required this.prompt,
    required this.liveId,
    super.key,
  });

  final ClarifyPrompt prompt;

  /// The live session id of the message list this card renders in — used
  /// for the fold-state dismissal (the respond call itself is keyed by
  /// request id, §8.1).
  final String liveId;

  @override
  ConsumerState<ClarifyPromptCard> createState() => _ClarifyPromptCardState();
}

class _ClarifyPromptCardState extends ConsumerState<ClarifyPromptCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _answer(String answer) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await ref
          .read(chatRepositoryProvider)
          ?.respondClarify(widget.prompt.requestId, trimmed);
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
    final choices = widget.prompt.choices;
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
                  Icons.help_outline,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The agent is asking',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.prompt.question,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            if (choices != null)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final choice in choices)
                    ActionChip(
                      label: Text(choice),
                      onPressed: () => _answer(choice),
                    ),
                ],
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: clarifyFieldKey,
                      controller: _controller,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Type your answer',
                      ),
                      onSubmitted: _answer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: clarifySubmitKey,
                    tooltip: 'Answer',
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
