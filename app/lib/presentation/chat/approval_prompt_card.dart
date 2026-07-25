/// Approval prompt card (ticket P1-08): renders an `approval.request`
/// (protocol §8.2 — correlated BY SESSION, no request id) with the command,
/// its description, and Approve / Deny buttons, plus "Always allow" when
/// `allow_permanent` is set.
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choice strings for `approval.respond` (wire §10).
///
/// DEVIATION / open question: the docs pin `approve` and `deny` but name
/// the permanent option only descriptively ("approve-and-remember when
/// allow_permanent") without pinning the exact wire literal. We send
/// `approve_and_remember` (snake_case, consistent with the wire's other
/// enum values). Flagged for the Hermes team in the style of
/// docs/roadmap.md "Open questions" — if the gateway expects a different
/// literal, only this constant changes.
abstract final class ApprovalChoice {
  static const String approve = 'approve';
  static const String deny = 'deny';
  static const String approveAndRemember = 'approve_and_remember';
}

/// A tonal alert surface (docs/design/theming.md) for a pending approval.
/// Answers go through the chat repository; the prompt is then dismissed
/// from the fold state.
class ApprovalPromptCard extends ConsumerWidget {
  const ApprovalPromptCard({
    required this.prompt,
    required this.liveId,
    super.key,
  });

  final ApprovalPrompt prompt;

  /// The live session id of the message list this card renders in — used
  /// for BOTH `approval.respond` (correlated by session, §8.2) and the
  /// fold-state dismissal.
  final String liveId;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String choice,
  ) async {
    try {
      await ref.read(chatRepositoryProvider)?.respondApproval(liveId, choice);
    } on Object catch (error) {
      if (context.mounted) {
        final detail = error is GatewayException ? error.message : '$error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to answer approval: $detail')),
        );
      }
      return; // keep the card — the answer did not reach the gateway.
    }
    ref.read(messageListProvider(liveId).notifier).dismissPrompt(prompt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    'Approval required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prompt.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
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
                prompt.command,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: <Widget>[
                if (prompt.allowPermanent)
                  TextButton(
                    onPressed: () => _respond(
                      context,
                      ref,
                      ApprovalChoice.approveAndRemember,
                    ),
                    child: const Text('Always allow'),
                  ),
                TextButton(
                  onPressed: () => _respond(context, ref, ApprovalChoice.deny),
                  child: const Text('Deny'),
                ),
                FilledButton(
                  onPressed: () =>
                      _respond(context, ref, ApprovalChoice.approve),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
