import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';

/// A small chip showing what a session's agent is doing.
class FlitTaskStateChip extends StatelessWidget {
  const FlitTaskStateChip({required this.state, super.key});

  final FlitTaskState state;

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

/// "provider / model", or a placeholder.
String flitModelLabel(String provider, String model) {
  if (model.isEmpty) {
    return provider.isEmpty ? 'no model' : '$provider / (no model)';
  }
  return provider.isEmpty ? model : '$provider / $model';
}
