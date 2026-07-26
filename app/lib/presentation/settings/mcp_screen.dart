/// MCP & env reload (P4-05).
library;

import 'package:flit/application/tools/reload_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class McpScreen extends ConsumerWidget {
  const McpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadState = ref.watch(reloadControllerProvider);

    ref.listen(reloadControllerProvider, (previous, next) {
      if (next.confirmMessage != null) {
        _showConfirmDialog(context, ref, next.confirmMessage!);
      }
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('MCP & Environment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (reloadState.error != null)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  title: Text(
                    reloadState.error!,
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
                      ref.read(reloadControllerProvider.notifier).clearError();
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            const Text(
              'MCP Servers',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('Reload MCP servers to pick up configuration changes.'),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: reloadState.busy
                  ? null
                  : () {
                      ref.read(reloadControllerProvider.notifier).reloadMcp();
                    },
              icon: reloadState.busy
                  ? const SizedBox(
                      width: 16.0,
                      height: 16.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Reload MCP servers'),
            ),
            const SizedBox(height: 32.0),
            const Text(
              'Environment Variables',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('Reload environment variables from the current shell.'),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: reloadState.busy
                  ? null
                  : () {
                      ref.read(reloadControllerProvider.notifier).reloadEnv();
                    },
              icon: reloadState.busy
                  ? const SizedBox(
                      width: 16.0,
                      height: 16.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Reload environment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, WidgetRef ref, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reload'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(reloadControllerProvider.notifier).cancelConfirm();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(reloadControllerProvider.notifier).confirmReloadMcp();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
