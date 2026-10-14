/// A pending flit prompt (e.g. "Run shell command"), answerable from any
/// attached client. Once any client answers, the server logs it and the card
/// disappears everywhere.
library;

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flutter/material.dart';

class FlitPromptCard extends StatefulWidget {
  const FlitPromptCard({
    required this.prompt,
    required this.onAnswer,
    super.key,
  });

  final FlitPendingPrompt prompt;

  /// Answers the prompt; returns an error message or null.
  final Future<String?> Function({required bool allow}) onAnswer;

  @override
  State<FlitPromptCard> createState() => _FlitPromptCardState();
}

class _FlitPromptCardState extends State<FlitPromptCard> {
  bool _busy = false;

  Future<void> _answer({required bool allow}) async {
    setState(() => _busy = true);
    final error = await widget.onAnswer(allow: allow);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not answer: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.gpp_maybe_outlined,
                  size: 18,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.prompt.title.isEmpty
                        ? 'Approval required'
                        : widget.prompt.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.prompt.detail,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: <Widget>[
                TextButton(
                  onPressed: _busy ? null : () => _answer(allow: false),
                  child: const Text('Deny'),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _answer(allow: true),
                  child: const Text('Allow'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
