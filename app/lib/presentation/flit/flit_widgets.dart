import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/common/middle_ellipsis_text.dart';
import 'package:flutter/material.dart';

/// A small chip showing what a session's agent is doing.
class FlitTaskStateChip extends StatelessWidget {
  const FlitTaskStateChip({
    required this.state,
    this.compact = false,
    super.key,
  });

  final FlitTaskState state;

  /// Just the icon, with the label as a tooltip.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (state) {
      FlitTaskState.idle => ('Idle', Icons.circle_outlined, scheme.outline),
      FlitTaskState.working => ('Working', Icons.autorenew, scheme.primary),
      FlitTaskState.waiting => (
        'Needs you',
        Icons.front_hand_outlined,
        scheme.tertiary,
      ),
      FlitTaskState.stuck => ('Stuck', Icons.error_outline, scheme.error),
      FlitTaskState.done => (
        'Done',
        Icons.check_circle_outline,
        scheme.outline,
      ),
      FlitTaskState.unknown => ('?', Icons.help_outline, scheme.outline),
    };
    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: 14, color: color),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// The status strip's cache hits.
const Key flitCachedKey = Key('flit_cached');

/// "provider / model", or a placeholder.
String flitModelLabel(String provider, String model) {
  if (model.isEmpty) {
    return provider.isEmpty ? 'no model' : '$provider / (no model)';
  }
  return provider.isEmpty ? model : '$provider / $model';
}

/// 262144 → "262k", 1500000 → "1.5M".
String formatTokens(int n) {
  if (n >= 1000000) {
    final m = n / 1000000;
    return '${m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).round()}k';
  }
  return '$n';
}

/// The always-visible session status: model and effort (tap to change),
/// context use, speed of the last call, and what the agent is doing.
class FlitStatusStrip extends StatelessWidget {
  const FlitStatusStrip({
    required this.provider,
    required this.model,
    required this.effort,
    required this.contextTokens,
    required this.contextLength,
    required this.state,
    required this.onModelTap,
    this.generationTokensPerSecond,
    this.timeToFirstTokenMs,
    this.inputTokens = 0,
    this.cachedTokens = 0,
    this.role = '',
    this.onRoleTap,
    this.roleButtonKey,
    super.key,
  });

  /// The session's role ('' = none), shown when [onRoleTap] is set.
  final String role;
  final VoidCallback? onRoleTap;
  final Key? roleButtonKey;

  /// The last call's prompt and how much llama.cpp had cached.
  final int inputTokens;
  final int cachedTokens;

  final String provider;
  final String model;
  final String effort;
  final int contextTokens;
  final int contextLength;
  final FlitTaskState state;
  final VoidCallback onModelTap;
  final double? generationTokensPerSecond;
  final int? timeToFirstTokenMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.labelSmall;
    final fraction = contextLength > 0
        ? (contextTokens / contextLength).clamp(0.0, 1.0)
        : null;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: onModelTap,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.memory, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: MiddleEllipsisText(
                            flitModelLabel(provider, model),
                            style: small,
                          ),
                        ),
                        if (effort.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 6),
                          Text('effort $effort', style: small),
                        ],
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
                if (onRoleTap != null) ...<Widget>[
                  InkWell(
                    key: roleButtonKey,
                    onTap: onRoleTap,
                    child: Tooltip(
                      message: 'Change role',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.badge_outlined, size: 14),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              role.isEmpty ? 'no role' : role,
                              style: small,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                FlitTaskStateChip(state: state),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Tooltip(
                    message: 'Context used by the last model call',
                    child: LinearProgressIndicator(
                      value: fraction ?? 0,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                      color: (fraction ?? 0) > 0.85
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  contextLength > 0
                      ? '${formatTokens(contextTokens)} / ${formatTokens(contextLength)}'
                      : '${formatTokens(contextTokens)} tokens',
                  style: small,
                ),
                if (cachedTokens > 0) ...<Widget>[
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Prompt tokens llama.cpp reused from its cache on the '
                        'last call, of the prompt\'s ${formatTokens(inputTokens)}',
                    child: Text(
                      '${formatTokens(cachedTokens)}/${formatTokens(inputTokens)} cached',
                      key: flitCachedKey,
                      style: small,
                    ),
                  ),
                ],
                if (generationTokensPerSecond != null &&
                    generationTokensPerSecond! > 0) ...<Widget>[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: timeToFirstTokenMs == null
                        ? 'Generation speed'
                        : 'Generation speed; first token after '
                              '${timeToFirstTokenMs}ms',
                    child: Text(
                      '${generationTokensPerSecond!.toStringAsFixed(1)} tok/s',
                      style: small,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The agent's task list.
class FlitTodoPanel extends StatelessWidget {
  const FlitTodoPanel({required this.todos, super.key});

  final List<FlitTodo> todos;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const SizedBox.shrink();
    }
    final done = todos
        .where((t) => t.status == FlitTodoStatus.completed)
        .length;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: ExpansionTile(
        dense: true,
        initiallyExpanded: true,
        leading: const Icon(Icons.checklist, size: 18),
        title: Text('Tasks ($done/${todos.length})'),
        children: <Widget>[
          for (final t in todos)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(switch (t.status) {
                FlitTodoStatus.completed => Icons.check_box,
                FlitTodoStatus.inProgress => Icons.indeterminate_check_box,
                FlitTodoStatus.pending => Icons.check_box_outline_blank,
              }, size: 18),
              title: Text(
                t.content,
                style: t.status == FlitTodoStatus.completed
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
