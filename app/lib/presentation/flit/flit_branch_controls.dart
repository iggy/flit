/// Branch controls on chat messages: "retry from here" and "edit and
/// resend" on user messages, and the "‹ 2 / 3 ›" switch on the first
/// message after a fork.
library;

import 'package:flit/application/flit/flit_branches.dart';
import 'package:flutter/material.dart';

const Key flitBranchPrevKey = Key('flit_branch_prev');
const Key flitBranchNextKey = Key('flit_branch_next');
const Key flitRetryFromKey = Key('flit_retry_from');
const Key flitEditMessageKey = Key('flit_edit_message');
const Key flitEditSendKey = Key('flit_edit_send');

/// "‹ 2 / 3 ›": which alternative at a fork is shown, with arrows to the
/// others. [onSwitch] is null while switching isn't possible (a turn is
/// running).
class FlitBranchSwitcher extends StatelessWidget {
  const FlitBranchSwitcher({
    required this.choice,
    required this.onSwitch,
    super.key,
  });

  final FlitBranchChoice choice;
  final ValueChanged<String>? onSwitch;

  @override
  Widget build(BuildContext context) {
    final i = choice.index;
    final go = onSwitch;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: flitBranchPrevKey,
          tooltip: 'Previous version',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: go == null || i == 0
              ? null
              : () => go(choice.targets[i - 1]),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${i + 1} / ${choice.count}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        IconButton(
          key: flitBranchNextKey,
          tooltip: 'Next version',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: go == null || i >= choice.count - 1
              ? null
              : () => go(choice.targets[i + 1]),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Retry and edit buttons for a user message. Each starts a new branch;
/// the current one stays reachable through the switch.
class FlitUserMessageActions extends StatelessWidget {
  const FlitUserMessageActions({
    required this.onRetry,
    required this.onEdit,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: flitRetryFromKey,
          tooltip: "Retry from here (files aren't rewound)",
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: color,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          key: flitEditMessageKey,
          tooltip: 'Edit and resend',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: color,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}

/// Asks for a message's new text; null if cancelled or unchanged.
Future<String?> showFlitEditMessageDialog(
  BuildContext context,
  String text,
) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _EditMessageDialog(text: text),
  );
  if (result == null || result.trim().isEmpty || result.trim() == text.trim()) {
    return null;
  }
  return result;
}

class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.text});

  final String text;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit and resend'),
      content: SizedBox(
        width: 560,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 1,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            helperText:
                'Starts a new branch from here. The original stays '
                "one arrow away. Files the agent changed aren't rewound.",
            helperMaxLines: 2,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: flitEditSendKey,
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
