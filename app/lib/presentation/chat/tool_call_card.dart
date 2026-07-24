/// Tool call card (ticket P1-07): a subtle outlined container
/// (docs/design/theming.md) with a single-line header (tool icon + name +
/// context + status icon) that expands to show the pretty-printed result,
/// the completion summary, and the monospace inline diff.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hermes/domain/models/tool_call.dart';

/// Renders one [ToolCall] attached to an assistant message (protocol §7:
/// display only — no client reply required).
class ToolCallCard extends StatefulWidget {
  const ToolCallCard({required this.tool, super.key});

  final ToolCall tool;

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  bool _expanded = false;

  /// Pretty-print a polymorphic tool result (protocol §7: parsed JSON
  /// dict/list OR a raw string).
  static String _prettyResult(Object result) {
    if (result is Map || result is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(result);
      } on Object {
        return result.toString();
      }
    }
    return result.toString();
  }

  static IconData _toolIcon(String name) {
    return switch (name) {
      'shell' || 'terminal' || 'bash' => Icons.terminal,
      'read_file' || 'write_file' => Icons.description_outlined,
      'edit_file' || 'apply_patch' => Icons.edit_note,
      'web_search' || 'search' || 'browser' => Icons.travel_explore,
      _ => Icons.build_outlined,
    };
  }

  Widget _statusIcon(ColorScheme scheme) {
    return switch (widget.tool.status) {
      ToolCallStatus.running => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      ToolCallStatus.done => Icon(
        Icons.check_circle,
        size: 16,
        color: scheme.primary,
      ),
      ToolCallStatus.error => Icon(
        Icons.error_outline,
        size: 16,
        color: scheme.error,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tool = widget.tool;
    final contextLine = tool.context;
    final hasDetails =
        tool.result != null || tool.summary != null || tool.inlineDiff != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: hasDetails
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  Icon(_toolIcon(tool.name), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: tool.name,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (contextLine != null && contextLine.isNotEmpty)
                            TextSpan(
                              text: '  $contextLine',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.outline,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusIcon(scheme),
                  if (hasDetails) ...<Widget>[
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: scheme.outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded && hasDetails) ...<Widget>[
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (tool.summary != null) ...<Widget>[
                    Text(tool.summary!, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                  ],
                  if (tool.durationS != null) ...<Widget>[
                    Text(
                      '${tool.durationS}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (tool.result != null) ...<Widget>[
                    Text('Result', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    _MonospaceBox(text: _prettyResult(tool.result as Object)),
                  ],
                  if (tool.inlineDiff != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text('Diff', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    _MonospaceBox(text: tool.inlineDiff!),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Monospace, selectable detail box — used for the pretty-printed result
/// and the inline diff (simpler than flutter_highlight and sufficient per
/// ticket notes).
class _MonospaceBox extends StatelessWidget {
  const _MonospaceBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
