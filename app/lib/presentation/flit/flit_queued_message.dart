/// A message waiting in the session's queue: sent while the agent was
/// working, delivered at its next step. Every device sees it and can edit
/// or cancel it until then.
library;

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flutter/material.dart';

Key flitQueuedEditKey(String queueId) => Key('flit_queued_edit_$queueId');
Key flitQueuedCancelKey(String queueId) => Key('flit_queued_cancel_$queueId');

class FlitQueuedBubble extends StatelessWidget {
  const FlitQueuedBubble({
    required this.message,
    required this.turnRunning,
    required this.onEdit,
    required this.onCancel,
    super.key,
  });

  final FlitQueuedMessage message;

  /// Whether a turn is running (it will pick the message up); otherwise it
  /// waits for the next Send.
  final bool turnRunning;
  final ValueChanged<String> onEdit;
  final VoidCallback onCancel;

  Future<void> _edit(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(text: message.text),
    );
    if (text != null && text.trim().isNotEmpty && text != message.text) {
      onEdit(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = turnRunning
        ? 'Queued · sends at the agent\'s next step'
        : 'Queued · sends with your next message';
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 4),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(message.text),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.schedule, size: 14, color: scheme.outline),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      message.client.isEmpty
                          ? note
                          : '$note · ${message.client}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ),
                  IconButton(
                    key: flitQueuedEditKey(message.queueId),
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    key: flitQueuedCancelKey(message.queueId),
                    tooltip: "Don't send",
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns its controller, so it lives as long as the dialog (closing
/// animation included).
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.text});

  final String text;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
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
      title: const Text('Edit queued message'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 8,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
