/// The card of an agent tool call: the subagent's kind, model and status
/// on one line, expanding to its task, its own tool calls and replies, and
/// its final report. Same frame as [ToolCallCard].
library;

import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/subagent.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/presentation/chat/collapse_footer.dart';
import 'package:flit/presentation/chat/tool_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Key of a subagent card's header (tap to expand).
const Key subagentHeaderKey = Key('subagent_header');

class SubagentCard extends StatefulWidget {
  const SubagentCard({required this.tool, required this.subagent, super.key});

  final ToolCall tool;
  final Subagent subagent;

  @override
  State<SubagentCard> createState() => _SubagentCardState();
}

class _SubagentCardState extends State<SubagentCard> {
  bool _expanded = false;

  static String statusLabel(Subagent a) => switch (a.status) {
    SubagentStatus.running => 'working',
    SubagentStatus.done => a.steps == 1 ? '1 step' : '${a.steps} steps',
    SubagentStatus.stepLimit => 'stopped at ${a.maxSteps} steps',
    SubagentStatus.cancelled => 'stopped',
    SubagentStatus.error => 'failed',
  };

  Widget _statusIcon(ColorScheme scheme) {
    return switch (widget.subagent.status) {
      SubagentStatus.running => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SubagentStatus.done => Icon(
        Icons.check_circle,
        size: 16,
        color: scheme.primary,
      ),
      SubagentStatus.stepLimit || SubagentStatus.cancelled => Icon(
        Icons.stop_circle_outlined,
        size: 16,
        color: scheme.outline,
      ),
      SubagentStatus.error => Icon(
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
    final a = widget.subagent;
    final kind = a.kind == SubagentKind.unknown ? 'subagent' : a.kind.name;
    final subtle = theme.textTheme.bodySmall?.copyWith(color: scheme.outline);
    // The first message is the task, shown on its own.
    final transcript = a.transcript.skip(1).toList();
    final report = a.report.isNotEmpty ? a.report : null;

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
            key: subagentHeaderKey,
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    a.kind == SubagentKind.build
                        ? Icons.handyman_outlined
                        : Icons.manage_search,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$kind subagent',
                            style: theme.textTheme.titleSmall,
                          ),
                          TextSpan(
                            text: [
                              if (a.model.isNotEmpty) a.model,
                              statusLabel(a),
                              if (a.task.isNotEmpty) a.task,
                            ].map((p) => '  $p').join(' ·'),
                            style: subtle,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusIcon(scheme),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: scheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...<Widget>[
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Task', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  SelectableText(a.task, style: theme.textTheme.bodySmall),
                  if (a.provider.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text('${a.provider}/${a.model}', style: subtle),
                  ],
                  for (final m in transcript) ..._entry(context, m, report),
                  if (a.error.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      a.error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ],
                  if (report != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text('Report', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    MarkdownBody(data: report, selectable: true),
                  ],
                  if (needsCollapseFooter(report ?? '') ||
                      transcript.length > 4) ...<Widget>[
                    const SizedBox(height: 4),
                    CollapseFooter(
                      onCollapse: () => setState(() => _expanded = false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One message of the subagent's conversation: what it said along the
  /// way (not the report, shown below) and its tool calls; notes it was
  /// sent (the step limit) in italics.
  List<Widget> _entry(BuildContext context, ChatMessage m, String? report) {
    final theme = Theme.of(context);
    final text = m.text.trim();
    return <Widget>[
      if (text.isNotEmpty && !(report != null && text == report.trim()))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            text,
            style: m.role == MessageRole.user
                ? theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  )
                : theme.textTheme.bodySmall,
          ),
        ),
      for (final t in m.toolCalls) ToolCallCard(tool: t),
    ];
  }
}
