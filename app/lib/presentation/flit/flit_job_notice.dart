/// flit's notice to the agent that background jobs ended: a user message
/// in the log, shown as a notice rather than as something the person
/// wrote.
library;

import 'package:flutter/material.dart';

/// Key prefix of a notice (`${key}<message id>`).
const String flitJobNoticeKeyPrefix = 'flit_job_notice_';

class FlitJobNoticeView extends StatefulWidget {
  const FlitJobNoticeView({required this.text, super.key});

  /// The notice as the agent got it.
  final String text;

  @override
  State<FlitJobNoticeView> createState() => _FlitJobNoticeViewState();
}

class _FlitJobNoticeViewState extends State<FlitJobNoticeView> {
  bool _expanded = false;

  /// The one-line summaries ("- job_1 (cmd): exited ...") without the dash.
  List<String> get _summaries => <String>[
    for (final l in widget.text.split('\n'))
      if (l.startsWith('- ')) l.substring(2),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summaries = _summaries;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.notifications_none,
                    size: 16,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summaries.length == 1
                          ? 'Background job ended'
                          : 'Background jobs ended',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: scheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_expanded)
                SelectableText(
                  widget.text,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                )
              else
                for (final s in summaries)
                  Text(
                    s,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
