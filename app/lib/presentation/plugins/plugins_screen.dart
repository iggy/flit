import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/plugin_info.dart';

/// Plugins list (ticket P1-14): every plugin from `plugins.list` (wire §13)
/// with name, version, and an enabled-state ICON (enable/disable toggling is
/// Phase 5 — the icon only shows state). The kanban plugin gets an
/// "Open board" affordance when present AND enabled.
class PluginsScreen extends ConsumerWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: plugins.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PluginsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(pluginsProvider),
        ),
        data: (list) => list.isEmpty
            ? const _PluginsEmpty()
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) => _PluginTile(list[index]),
              ),
      ),
    );
  }
}

class _PluginTile extends StatelessWidget {
  const _PluginTile(this.plugin);

  final PluginInfo plugin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Kanban is the reference plugin surface (06-kanban-rest.md): only a
    // present AND enabled kanban gets the board affordance.
    final openBoard = plugin.name == 'kanban' && plugin.enabled;
    return ListTile(
      leading: Icon(
        // State icon only — toggling is Phase 5.
        plugin.enabled ? Icons.toggle_on : Icons.toggle_off_outlined,
        color: plugin.enabled ? theme.colorScheme.primary : theme.disabledColor,
      ),
      title: Text(plugin.name),
      subtitle: Text('Version ${plugin.version}'),
      trailing: openBoard
          ? FilledButton.tonal(
              onPressed: () => context.push('/plugins/kanban'),
              child: const Text('Open board'),
            )
          : null,
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
