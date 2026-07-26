/// Tools browser & configure (P4-03/P4-04).
library;

import 'package:flit/application/tools/tools_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(toolsListProvider);
    final configureState = ref.watch(toolsConfigureControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: toolsAsync.when(
        data: (toolsets) {
          if (toolsets.isEmpty) {
            return const Center(child: Text('No toolsets available'));
          }
          return Column(
            children: <Widget>[
              if (configureState.error != null)
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    title: Text(
                      configureState.error!,
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
                            .read(toolsConfigureControllerProvider.notifier)
                            .clearError();
                      },
                    ),
                  ),
                ),
              if (configureState.lastResult != null &&
                  configureState.lastResult!.missingServers.isNotEmpty)
                Material(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    title: Text(
                      'Some servers are not running: ${configureState.lastResult!.missingServers.join(", ")}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: toolsets.length,
                  itemBuilder: (context, index) {
                    final toolset = toolsets[index];
                    return ExpansionTile(
                      title: Text(toolset.name),
                      subtitle: Text(toolset.description),
                      leading: Switch(
                        value: toolset.enabled,
                        onChanged: configureState.busy
                            ? null
                            : (enabled) {
                                ref
                                    .read(
                                      toolsConfigureControllerProvider.notifier,
                                    )
                                    .setEnabled(toolset.name, enabled);
                              },
                      ),
                      trailing: Text('${toolset.toolCount} tools'),
                      children: toolset.tools.isEmpty
                          ? <Widget>[
                              const ListTile(
                                title: Text('No tool details available'),
                              ),
                            ]
                          : toolset.tools
                                .map(
                                  (tool) =>
                                      ListTile(title: Text(tool), dense: true),
                                )
                                .toList(),
                    );
                  },
                ),
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
                  'Failed to load tools',
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
