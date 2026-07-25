import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Plugins list (ticket P1-14, P5-08): every plugin from
/// `plugins.manage {action:'list'}` with name, version, description,
/// source, and an enabled-state Switch. The kanban plugin gets an
/// "Open board" affordance when present AND enabled.
class PluginsScreen extends ConsumerWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginDetailsProvider);
    final toggleState = ref.watch(pluginToggleControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: Column(
        children: <Widget>[
          if (toggleState.error != null)
            _PluginsErrorBanner(
              message: toggleState.error!,
              onDismiss: () => ref
                  .read(pluginToggleControllerProvider.notifier)
                  .clearError(),
            ),
          Expanded(
            child: plugins.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _PluginsError(
                message: error.toString(),
                onRetry: () => ref.invalidate(pluginDetailsProvider),
              ),
              data: (list) => list.isEmpty
                  ? const _PluginsEmpty()
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) => _PluginTile(
                        list[index],
                        busy: toggleState.busy,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PluginTile extends ConsumerWidget {
  const _PluginTile(this.plugin, {required this.busy});

  final PluginDetail plugin;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Kanban is the reference plugin surface (06-kanban-rest.md): only a
    // present AND enabled kanban gets the board affordance.
    final openBoard = plugin.name == 'kanban' && plugin.isEnabled;
    return ListTile(
      leading: Chip(
        label: Text(
          plugin.source,
          style: theme.textTheme.labelSmall,
        ),
      ),
      title: Text(plugin.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (plugin.description.isNotEmpty) Text(plugin.description),
          const SizedBox(height: 2),
          Text(
            'Version ${plugin.version}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (openBoard)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: () => context.push('/plugins/kanban'),
                child: const Text('Open board'),
              ),
            ),
          Switch(
            value: plugin.isEnabled,
            onChanged: busy
                ? null
                : (value) => ref
                    .read(pluginToggleControllerProvider.notifier)
                    .toggle(plugin.name, value),
          ),
        ],
      ),
      isThreeLine: plugin.description.isNotEmpty,
    );
  }
}

class _PluginsEmpty extends StatelessWidget {
  const _PluginsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No plugins reported by the gateway.'));
  }
}

class _PluginsError extends StatelessWidget {
  const _PluginsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline),
          const SizedBox(height: 8),
          Text(
            'Could not load plugins',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PluginsErrorBanner extends StatelessWidget {
  const _PluginsErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
