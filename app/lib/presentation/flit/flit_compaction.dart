/// Compaction in the chat: a marker where the conversation was summarized
/// (the summary expands from it; the older messages above are greyed out),
/// and a "compacting…" row while it runs.
library;

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';

/// The marker, the button that expands its summary, and the in-progress
/// row.
const String flitCompactionMarkerKeyPrefix = 'flit_compaction_';
const Key flitCompactingKey = Key('flit_compacting');

/// How older messages look once only the summary reaches the model.
const double flitSummarizedOpacity = 0.45;

/// The composer command, offered in the slash menu with the skills.
const String flitCompactCommand = 'compact';
const FlitSkill flitCompactSkill = FlitSkill(
  name: flitCompactCommand,
  description:
      'Summarize the older messages to free up context '
      '(optionally: /compact what to keep)',
  source: 'flit',
);

/// The instructions of a "/compact ..." message, or null when [text] isn't
/// one.
String? flitCompactInstructions(String text) {
  final m = RegExp(r'^/compact(?:\s+([\s\S]*))?$').firstMatch(text.trim());
  if (m == null) {
    return null;
  }
  return (m.group(1) ?? '').trim();
}

/// "12.3k" style token counts.
String flitTokens(int n) {
  if (n >= 1000) {
    final k = n / 1000;
    return '${k >= 100 ? k.round() : k.toStringAsFixed(1)}k';
  }
  return '$n';
}

class FlitCompactionMarkerView extends StatefulWidget {
  const FlitCompactionMarkerView({required this.marker, super.key});

  final FlitCompactionMarker marker;

  @override
  State<FlitCompactionMarkerView> createState() =>
      _FlitCompactionMarkerViewState();
}

class _FlitCompactionMarkerViewState extends State<FlitCompactionMarkerView> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.marker;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final approx = m.tokensExact ? '' : '~';
    final tokens = m.tokensBefore > 0
        ? ' · $approx${flitTokens(m.tokensBefore)} → '
              '$approx${flitTokens(m.tokensAfter)} tokens'
        : '';
    final title =
        '${m.auto ? 'Compacted automatically' : 'Conversation compacted'}'
        '$tokens';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Divider(color: scheme.primary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.compress, size: 18, color: scheme.primary),
              ),
              Expanded(child: Divider(color: scheme.primary)),
            ],
          ),
          Material(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: Key('$flitCompactionMarkerKeyPrefix${m.compactionId}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(title, style: theme.textTheme.titleSmall),
                        ),
                        Icon(_open ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                    Text(
                      'Messages above are now only in this summary'
                      '${m.model.isEmpty ? '' : ' (written by ${m.model})'}.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (_open) ...<Widget>[
                      const SizedBox(height: 8),
                      SelectableText(
                        m.summary,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while a compaction runs.
class FlitCompactingRow extends StatelessWidget {
  const FlitCompactingRow({required this.compacting, super.key});

  final FlitCompacting compacting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = compacting;
    final use = c.contextLength > 0
        ? ' (${flitTokens(c.tokens)} of ${flitTokens(c.contextLength)} tokens used)'
        : '';
    return Padding(
      key: flitCompactingKey,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            c.auto
                ? 'The conversation is nearly filling the context$use: '
                      'compacting it…'
                : 'Compacting the conversation…',
            style: theme.textTheme.titleSmall,
          ),
          Text(
            'Summarizing the older messages'
            '${c.model.isEmpty ? '' : ' with ${c.model}'}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
