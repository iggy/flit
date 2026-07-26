/// Browser & preview control screen (P9-05).
library;

import 'package:flit/application/browser/browser_providers.dart';
import 'package:flit/domain/models/browser_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final _urlController = TextEditingController();
  final _previewUrlController = TextEditingController();
  final _previewCwdController = TextEditingController();
  final _previewContextController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _previewUrlController.dispose();
    _previewCwdController.dispose();
    _previewContextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(browserStatusProvider);
    final actionState = ref.watch(browserActionControllerProvider);
    final previewState = ref.watch(previewRestartControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browser & preview'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: () {
              ref.read(browserStatusProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          if (actionState.error != null) _buildErrorBanner(actionState.error!),
          if (previewState.error != null)
            _buildErrorBanner(
              previewState.error!,
              onDismiss: () {
                ref
                    .read(previewRestartControllerProvider.notifier)
                    .clearError();
              },
            ),
          _buildStatusSection(context, statusAsync, actionState),
          const SizedBox(height: 24.0),
          const Divider(),
          const SizedBox(height: 24.0),
          _buildPreviewSection(context, previewState),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error, {VoidCallback? onDismiss}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
        child: ListTile(
          leading: Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          title: Text(
            error,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          trailing: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onErrorContainer),
            onPressed:
                onDismiss ??
                () {
                  ref
                      .read(browserActionControllerProvider.notifier)
                      .clearError();
                },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    AsyncValue<BrowserStatus> statusAsync,
    BrowserActionState actionState,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Browser Connection', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16.0),
        statusAsync.when(
          data: (status) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _StatusChip(connected: status.connected),
                    const SizedBox(width: 16.0),
                    if (status.url != null)
                      Expanded(
                        child: Text(
                          status.url!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const <String>[
                              'Courier New',
                              'Courier',
                              'monospace',
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: 'CDP URL (optional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        enabled: !actionState.busy,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FilledButton(
                      onPressed: actionState.busy
                          ? null
                          : () {
                              final url = _urlController.text.trim();
                              ref
                                  .read(
                                    browserActionControllerProvider.notifier,
                                  )
                                  .connect(url: url.isEmpty ? null : url);
                            },
                      child: const Text('Connect'),
                    ),
                    const SizedBox(width: 8.0),
                    FilledButton(
                      onPressed: actionState.busy
                          ? null
                          : () {
                              ref
                                  .read(
                                    browserActionControllerProvider.notifier,
                                  )
                                  .disconnect();
                            },
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
                if (actionState.progressLines.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16.0),
                  Text('Progress', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8.0),
                  _buildProgressLog(context, actionState.progressLines),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Failed to load status: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLog(
    BuildContext context,
    List<BrowserProgressLine> lines,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      constraints: const BoxConstraints(maxHeight: 200.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            final isError = line.level == 'error';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                line.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const <String>[
                    'Courier New',
                    'Courier',
                    'monospace',
                  ],
                  color: isError ? theme.colorScheme.error : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    PreviewRestartState previewState,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Preview Restart', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16.0),
        TextField(
          controller: _previewUrlController,
          decoration: const InputDecoration(
            labelText: 'URL (required)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _previewCwdController,
          decoration: const InputDecoration(
            labelText: 'Working directory (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _previewContextController,
          decoration: const InputDecoration(
            labelText: 'Context (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16.0),
        Row(
          children: <Widget>[
            FilledButton(
              onPressed: () {
                final url = _previewUrlController.text.trim();
                if (url.isEmpty) {
                  return;
                }
                final cwd = _previewCwdController.text.trim();
                final context = _previewContextController.text.trim();
                ref
                    .read(previewRestartControllerProvider.notifier)
                    .restart(
                      url: url,
                      cwd: cwd.isEmpty ? null : cwd,
                      context: context.isEmpty ? null : context,
                    );
              },
              child: const Text('Restart'),
            ),
            const SizedBox(width: 8.0),
            FilledButton(
              onPressed: previewState.tasks.isEmpty
                  ? null
                  : () {
                      ref
                          .read(previewRestartControllerProvider.notifier)
                          .clearTasks();
                    },
              child: const Text('Clear tasks'),
            ),
          ],
        ),
        if (previewState.tasks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24.0),
          Text('Tasks', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8.0),
          ...previewState.tasks.map((task) => _buildTaskCard(context, task)),
        ],
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, PreviewRestartTask task) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  task.taskId,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const <String>[
                      'Courier New',
                      'Courier',
                      'monospace',
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                if (task.done)
                  Icon(
                    Icons.check_circle,
                    size: 16.0,
                    color: theme.colorScheme.primary,
                  )
                else
                  SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              task.url,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.lines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                constraints: const BoxConstraints(maxHeight: 150.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: task.lines.map((line) {
                      final isError = line.level == 'error';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: Text(
                          line.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const <String>[
                              'Courier New',
                              'Courier',
                              'monospace',
                            ],
                            color: isError ? theme.colorScheme.error : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            if (task.done && task.result != null) ...<Widget>[
              const SizedBox(height: 8.0),
              Text(
                'Result:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(task.result!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = connected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foregroundColor = connected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        connected ? 'Connected' : 'Disconnected',
        style: theme.textTheme.labelMedium?.copyWith(color: foregroundColor),
      ),
    );
  }
}
