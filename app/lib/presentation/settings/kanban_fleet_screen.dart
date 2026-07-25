/// Kanban fleet operations screen (P5-06).
library;

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KanbanFleetScreen extends ConsumerStatefulWidget {
  const KanbanFleetScreen({super.key});

  @override
  ConsumerState<KanbanFleetScreen> createState() => _KanbanFleetScreenState();
}

class _KanbanFleetScreenState extends ConsumerState<KanbanFleetScreen> {
  bool _dryRun = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(kanbanStatsProvider);
    final workersAsync = ref.watch(kanbanWorkersProvider);
    final diagnosticsAsync = ref.watch(kanbanDiagnosticsProvider);
    final actionState = ref.watch(kanbanFleetActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Fleet'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(kanbanStatsProvider);
              ref.invalidate(kanbanWorkersProvider);
              ref.invalidate(kanbanDiagnosticsProvider);
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          if (actionState.error != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  actionState.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  onPressed: ref.read(kanbanFleetActionControllerProvider.notifier).clearError,
                ),
              ),
            ),
          if (actionState.lastMessage != null)
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                title: Text(
                  actionState.lastMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          _buildStatsSection(context, statsAsync),
          const Divider(),
          _buildWorkersSection(context, workersAsync, actionState),
          const Divider(),
          _buildDiagnosticsSection(context, diagnosticsAsync),
          const Divider(),
          _buildDispatchSection(context, actionState),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AsyncValue<KanbanStats?> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        if (stats == null) {
          return const ListTile(title: Text('No stats available'));
        }
        return ExpansionTile(
          title: const Text('Fleet Stats'),
          initiallyExpanded: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'By Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...stats.byStatus.entries.map((MapEntry<String, int> entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(entry.key),
                        Text('${entry.value}'),
                      ],
                    ),
                  )),
                  if (stats.oldestReadyAgeSeconds != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Oldest ready task: ${_formatAge(stats.oldestReadyAgeSeconds!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const ListTile(
        title: Text('Fleet Stats'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ListTile(
        title: const Text('Fleet Stats'),
        subtitle: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildWorkersSection(
    BuildContext context,
    AsyncValue<List<KanbanWorker>> workersAsync,
    KanbanFleetActionState actionState,
  ) {
    return workersAsync.when(
      data: (workers) {
        return ExpansionTile(
          title: Text('Active Workers (${workers.length})'),
          initiallyExpanded: workers.isNotEmpty,
          children: workers.isEmpty
              ? <Widget>[const ListTile(title: Text('No active workers'))]
              : workers.map((worker) {
                  final uptime = DateTime.now().toUtc().difference(worker.startedAt);
                  return ListTile(
                    title: Text(worker.taskTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Task: ${worker.taskId}'),
                        Text('Profile: ${worker.profile ?? "none"}'),
                        Text('Uptime: ${_formatDuration(uptime)}'),
                        Text('PID: ${worker.workerPid}'),
                      ],
                    ),
                    trailing: actionState.busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.stop_circle_outlined),
                            onPressed: () => _confirmTerminate(context, worker),
                          ),
                  );
                }).toList(),
        );
      },
      loading: () => const ListTile(
        title: Text('Active Workers'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ListTile(
        title: const Text('Active Workers'),
        subtitle: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildDiagnosticsSection(
    BuildContext context,
    AsyncValue<List<KanbanDiagnosticGroup>> diagnosticsAsync,
  ) {
    return diagnosticsAsync.when(
      data: (groups) {
        final totalDiagnostics = groups.fold(
          0,
          (int sum, group) => sum + group.diagnostics.length,
        );
        return ExpansionTile(
          title: Text('Diagnostics ($totalDiagnostics)'),
          children: groups.isEmpty
              ? <Widget>[const ListTile(title: Text('No diagnostics'))]
              : groups.map((group) {
                  return ExpansionTile(
                    title: Text(group.taskTitle ?? group.taskId),
                    subtitle: Text('${group.diagnostics.length} issues'),
                    children: group.diagnostics.map((KanbanDiagnostic diag) {
                      final color = _severityColor(context, diag.severity);
                      return ListTile(
                        leading: Icon(
                          _severityIcon(diag.severity),
                          color: color,
                        ),
                        title: Text(diag.title),
                        subtitle: Text(diag.detail),
                        trailing: Text('x${diag.count}'),
                      );
                    }).toList(),
                  );
                }).toList(),
        );
      },
      loading: () => const ListTile(
        title: Text('Diagnostics'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ListTile(
        title: const Text('Diagnostics'),
        subtitle: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildDispatchSection(BuildContext context, KanbanFleetActionState actionState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Dispatcher',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Checkbox(
                value: _dryRun,
                onChanged: (value) {
                  setState(() {
                    _dryRun = value ?? false;
                  });
                },
              ),
              const Text('Dry run'),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(_dryRun ? 'Dry Run Dispatch' : 'Dispatch'),
            onPressed: actionState.busy
                ? null
                : () {
                    ref
                        .read(kanbanFleetActionControllerProvider.notifier)
                        .dispatch(dryRun: _dryRun);
                  },
          ),
        ],
      ),
    );
  }

  void _confirmTerminate(BuildContext context, KanbanWorker worker) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Worker'),
        content: Text('Terminate worker for task "${worker.taskTitle}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(kanbanFleetActionControllerProvider.notifier)
                  .terminateRun(worker.runId);
              Navigator.of(context).pop();
            },
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
  }

  String _formatAge(int seconds) {
    final duration = Duration(seconds: seconds);
    return _formatDuration(duration);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  IconData _severityIcon(String severity) {
    return switch (severity) {
      'critical' => Icons.error,
      'error' => Icons.warning,
      'warning' => Icons.info_outline,
      _ => Icons.circle,
    };
  }

  Color _severityColor(BuildContext context, String severity) {
    return switch (severity) {
      'critical' => Theme.of(context).colorScheme.error,
      'error' => Theme.of(context).colorScheme.error,
      'warning' => Theme.of(context).colorScheme.tertiary,
      _ => Theme.of(context).colorScheme.onSurface,
    };
  }
}
