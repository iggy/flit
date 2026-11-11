/// The background job a shell call became: its status, its output and a
/// cancel button, shown under the call's card header.
library;

import 'package:flit/domain/models/background_job.dart';
import 'package:flutter/material.dart';

/// Key prefix of a job's cancel button (`${key}job_1`).
const String backgroundJobCancelKeyPrefix = 'background_job_cancel_';

/// Gives [BackgroundJobPanel]s below it a way to cancel jobs. Without one,
/// panels show no cancel button.
class BackgroundJobActions extends InheritedWidget {
  const BackgroundJobActions({
    required this.onCancel,
    required super.child,
    super.key,
  });

  /// Cancels job [jobId].
  final Future<void> Function(String jobId) onCancel;

  static BackgroundJobActions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackgroundJobActions>();

  @override
  bool updateShouldNotify(BackgroundJobActions oldWidget) =>
      onCancel != oldWidget.onCancel;
}

/// One line about [job], e.g. "job_1 · exited with code 1 after 3m 12s".
String backgroundJobStatusText(BackgroundJob job) {
  final took = job.duration == null ? '' : ' after ${_duration(job.duration!)}';
  final what = switch (job.status) {
    BackgroundJobStatus.running =>
      job.detached
          ? 'ran long, still running in the background'
          : 'running in the background',
    BackgroundJobStatus.exited => 'exited with code ${job.exitCode}$took',
    BackgroundJobStatus.failed =>
      job.error.isEmpty ? 'failed' : 'failed: ${job.error}',
    BackgroundJobStatus.timedOut => 'timed out$took',
    BackgroundJobStatus.cancelled =>
      job.cancelledBy.isEmpty
          ? 'cancelled by the agent$took'
          : 'cancelled by ${job.cancelledBy}$took',
    BackgroundJobStatus.lost => 'killed: flit stopped while it ran',
  };
  return '${job.id} · $what';
}

String _duration(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  if (d.inMinutes > 0) {
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
  return '${d.inSeconds}s';
}

class BackgroundJobPanel extends StatefulWidget {
  const BackgroundJobPanel({required this.job, super.key});

  final BackgroundJob job;

  @override
  State<BackgroundJobPanel> createState() => _BackgroundJobPanelState();
}

class _BackgroundJobPanelState extends State<BackgroundJobPanel> {
  bool _expanded = false;
  bool _cancelling = false;

  Future<void> _cancel(BackgroundJobActions actions) async {
    setState(() => _cancelling = true);
    try {
      await actions.onCancel(widget.job.id);
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final job = widget.job;
    final actions = BackgroundJobActions.maybeOf(context);
    final output = job.output.trimRight();
    final icon = job.running
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            job.failed ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: job.failed ? scheme.error : scheme.primary,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(height: 1, color: scheme.outlineVariant),
        InkWell(
          onTap: output.isEmpty
              ? null
              : () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            child: Row(
              children: <Widget>[
                Icon(Icons.timelapse, size: 16, color: scheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    backgroundJobStatusText(job),
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                icon,
                if (job.running && actions != null)
                  TextButton(
                    key: Key('$backgroundJobCancelKeyPrefix${job.id}'),
                    onPressed: _cancelling ? null : () => _cancel(actions),
                    child: const Text('Cancel'),
                  )
                else
                  const SizedBox(width: 8),
                if (output.isNotEmpty)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: scheme.outline,
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && output.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                output,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
