import 'package:flit/application/skills/skills_providers.dart';
import 'package:flit/domain/models/skill_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Skills screen (ticket P5-09): renders the skill catalog grouped by category
/// with a reload action.
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(skillCatalogProvider);
    final reloadState = ref.watch(skillsReloadControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: <Widget>[
          IconButton(
            icon: reloadState.busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: reloadState.busy
                ? null
                : () => ref
                      .read(skillsReloadControllerProvider.notifier)
                      .reload(),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (reloadState.error != null)
            _SkillsErrorBanner(
              message: reloadState.error!,
              onDismiss: () => ref
                  .read(skillsReloadControllerProvider.notifier)
                  .clearError(),
            ),
          if (reloadState.lastResult != null)
            _SkillsReloadResultBanner(
              result: reloadState.lastResult!,
              onDismiss: () => ref
                  .read(skillsReloadControllerProvider.notifier)
                  .clearError(),
            ),
          Expanded(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _SkillsError(
                message: error.toString(),
                onRetry: () => ref.invalidate(skillCatalogProvider),
              ),
              data: (skillCatalog) {
                if (skillCatalog.groups.isEmpty) {
                  return const _SkillsEmpty();
                }
                return ListView.builder(
                  itemCount: skillCatalog.groups.length,
                  itemBuilder: (context, index) {
                    final group = skillCatalog.groups[index];
                    return ExpansionTile(
                      title: Text(group.category),
                      subtitle: Text('${group.names.length} skill(s)'),
                      children: group.names
                          .map(
                            (name) => ListTile(title: Text(name), dense: true),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsEmpty extends StatelessWidget {
  const _SkillsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No skills reported by the gateway.'));
  }
}

class _SkillsError extends StatelessWidget {
  const _SkillsError({required this.message, required this.onRetry});

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
            'Could not load skills',
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

class _SkillsErrorBanner extends StatelessWidget {
  const _SkillsErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
      ],
    );
  }
}

class _SkillsReloadResultBanner extends StatelessWidget {
  const _SkillsReloadResultBanner({
    required this.result,
    required this.onDismiss,
  });

  final SkillReloadResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(
        'Reloaded: ${result.total} skill(s), ${result.commands} command(s). '
        'Added: ${result.added.length}, Removed: ${result.removed.length}.',
      ),
      actions: <Widget>[
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
      ],
    );
  }
}
