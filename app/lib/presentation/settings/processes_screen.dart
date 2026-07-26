/// Processes browser & control (P5-03).
library;

import 'package:flit/application/processes/process_providers.dart';
import 'package:flit/domain/models/background_process.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProcessesScreen extends ConsumerWidget {
  const ProcessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processesAsync = ref.watch(processListProvider);
    final actionState = ref.watch(processActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processes'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop all',
            onPressed: actionState.busy
                ? null
                : () {
                    ref
                        .read(processActionControllerProvider.notifier)
                        .stopAll();
                  },
          ),
        ],
      ),
      body: processesAsync.when(
        data: (processes) {
          return Column(
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
                      onPressed: () {
                        ref
                            .read(processActionControllerProvider.notifier)
                            .clearError();
                      },
                    ),
                  ),
                ),
              if (processes.isEmpty)
                const Expanded(
                  child: Center(child: Text('No background processes')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: processes.length,
                    itemBuilder: (context, index) {
                      final process = processes[index];
                      return _ProcessTile(
                        process: process,
                        onKill: actionState.busy
                            ? null
                            : () {
                                ref
                                    .read(
                                      processActionControllerProvider.notifier,
                                    )
                                    .kill(process.processId);
                              },
                      );
                    },
                  ),
                ),
              const Divider(height: 1.0),
              _ShellExecConsole(
                execResult: actionState.lastExecResult,
                busy: actionState.busy,
                onExec: (command) {
                  ref
                      .read(processActionControllerProvider.notifier)
                      .exec(command);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48.0),
                const SizedBox(height: 16.0),
                Text(
                  'Failed to load processes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessTile extends StatefulWidget {
  const _ProcessTile({required this.process, this.onKill});

  final BackgroundProcess process;
  final VoidCallback? onKill;

  @override
  State<_ProcessTile> createState() => _ProcessTileState();
}

class _ProcessTileState extends State<_ProcessTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.process.status ?? 'unknown';

    return ExpansionTile(
      key: ValueKey(widget.process.processId),
      title: Text(
        widget.process.command ?? 'Unknown command',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: <Widget>[
          _StatusChip(status: status),
          if (widget.process.pid != null) ...<Widget>[
            const SizedBox(width: 8.0),
            Text('PID: ${widget.process.pid}'),
          ],
          if (widget.process.uptimeSeconds != null) ...<Widget>[
            const SizedBox(width: 8.0),
            Text(_formatUptime(widget.process.uptimeSeconds!)),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Kill',
        onPressed: widget.onKill,
      ),
      children: <Widget>[
        if (widget.process.outputTail != null &&
            widget.process.outputTail!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.process.outputTail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const <String>[
                    'Courier New',
                    'Courier',
                    'monospace',
                  ],
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('No output'),
          ),
      ],
    );
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      return '${seconds ~/ 60}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = status == 'running';
    final backgroundColor = isRunning
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foregroundColor = isRunning
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(color: foregroundColor),
      ),
    );
  }
}

class _ShellExecConsole extends StatefulWidget {
  const _ShellExecConsole({
    required this.execResult,
    required this.busy,
    required this.onExec,
  });

  final ShellExecResult? execResult;
  final bool busy;
  final void Function(String command) onExec;

  @override
  State<_ShellExecConsole> createState() => _ShellExecConsoleState();
}

class _ShellExecConsoleState extends State<_ShellExecConsole> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Shell Execute', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8.0),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter command',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: widget.busy
                      ? null
                      : (value) {
                          if (value.isNotEmpty) {
                            widget.onExec(value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 8.0),
              FilledButton(
                onPressed: widget.busy
                    ? null
                    : () {
                        final command = _controller.text.trim();
                        if (command.isNotEmpty) {
                          widget.onExec(command);
                        }
                      },
                child: const Text('Run'),
              ),
            ],
          ),
          if (widget.execResult != null) ...<Widget>[
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Exit code: ${widget.execResult!.code}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.execResult!.stdout.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8.0),
                    Text('stdout:', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4.0),
                    SelectableText(
                      widget.execResult!.stdout,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const <String>[
                          'Courier New',
                          'Courier',
                          'monospace',
                        ],
                      ),
                    ),
                  ],
                  if (widget.execResult!.stderr.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8.0),
                    Text(
                      'stderr:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    SelectableText(
                      widget.execResult!.stderr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const <String>[
                          'Courier New',
                          'Courier',
                          'monospace',
                        ],
                        color: theme.colorScheme.error,
                      ),
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
}
