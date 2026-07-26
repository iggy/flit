import 'package:flit/application/learning/learning_providers.dart';
import 'package:flit/domain/models/learning_journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Journey screen (tickets P6-01, P6-02): renders the learning journey
/// timeline with buckets, nodes, and mutation actions (edit/delete).
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(learningJourneyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning journey'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(learningJourneyProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: journey.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _JourneyError(
          message: error.toString(),
          onRetry: () => ref.invalidate(learningJourneyProvider),
        ),
        data: (learningJourney) {
          if (learningJourney.buckets.isEmpty) {
            return const _JourneyEmpty();
          }
          return _JourneyContent(journey: learningJourney);
        },
      ),
    );
  }
}

class _JourneyEmpty extends StatelessWidget {
  const _JourneyEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No learning yet'));
  }
}

class _JourneyError extends StatelessWidget {
  const _JourneyError({required this.message, required this.onRetry});

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
            'Could not load journey',
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

class _JourneyContent extends StatelessWidget {
  const _JourneyContent({required this.journey});

  final LearningJourney journey;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        _JourneyHeader(journey: journey),
        ...journey.buckets.map(
          (bucket) => _BucketExpansionTile(bucket: bucket),
        ),
      ],
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({required this.journey});

  final LearningJourney journey;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...journey.summary.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
            ),
            if (journey.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: journey.categories.map((category) {
                  final color = _parseColor(category.color);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String hex) {
    if (hex.isEmpty) {
      return null;
    }
    // Parse #RRGGBB format.
    final hexValue = hex.replaceFirst('#', '');
    if (hexValue.length == 6) {
      return Color(int.parse('FF$hexValue', radix: 16));
    }
    return null;
  }
}

class _BucketExpansionTile extends StatelessWidget {
  const _BucketExpansionTile({required this.bucket});

  final LearningBucket bucket;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(bucket.label),
      subtitle: Text(
        '${bucket.date} · ${bucket.skills} skill(s) · ${bucket.memories} memory(ies)',
      ),
      children: bucket.nodes.map((node) => _NodeListTile(node: node)).toList(),
    );
  }
}

class _NodeListTile extends ConsumerWidget {
  const _NodeListTile({required this.node});

  final LearningNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Text(node.glyph),
      title: Text(node.fullLabel),
      subtitle: Text(node.meta),
      onTap: () => _showNodeDetail(context, ref, node),
    );
  }

  void _showNodeDetail(BuildContext context, WidgetRef ref, LearningNode node) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NodeDetailSheet(node: node),
    );
  }
}

class _NodeDetailSheet extends ConsumerStatefulWidget {
  const _NodeDetailSheet({required this.node});

  final LearningNode node;

  @override
  ConsumerState<_NodeDetailSheet> createState() => _NodeDetailSheetState();
}

class _NodeDetailSheetState extends ConsumerState<_NodeDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(learningControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: <Widget>[
            _NodeDetailHeader(node: widget.node),
            if (controllerState.error != null)
              _NodeDetailErrorBanner(
                message: controllerState.error!,
                onDismiss: () =>
                    ref.read(learningControllerProvider.notifier).clearError(),
              ),
            Expanded(
              child: _NodeDetailBody(
                node: widget.node,
                scrollController: scrollController,
              ),
            ),
            _NodeDetailActions(node: widget.node),
          ],
        );
      },
    );
  }
}

class _NodeDetailHeader extends StatelessWidget {
  const _NodeDetailHeader({required this.node});

  final LearningNode node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Text(node.glyph, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  node.fullLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(node.meta, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _NodeDetailErrorBanner extends StatelessWidget {
  const _NodeDetailErrorBanner({
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
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
      ],
    );
  }
}

class _NodeDetailBody extends ConsumerWidget {
  const _NodeDetailBody({required this.node, required this.scrollController});

  final LearningNode node;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(learningRepositoryProvider);

    if (repository == null) {
      return const Center(child: Text('Not connected'));
    }

    return FutureBuilder<LearningNodeDetail>(
      future: repository.detail(node.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final detail = snapshot.data;
        if (detail == null || !detail.ok) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(detail?.message ?? 'Could not load detail'),
            ),
          );
        }

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            detail.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

class _NodeDetailActions extends ConsumerWidget {
  const _NodeDetailActions({required this.node});

  final LearningNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(learningControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FilledButton.icon(
            onPressed: controllerState.busy
                ? null
                : () => _showEditDialog(context, ref, node),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: controllerState.busy
                ? null
                : () => _showDeleteConfirmDialog(context, ref, node),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    LearningNode node,
  ) async {
    final repository = ref.read(learningRepositoryProvider);
    if (repository == null) {
      return;
    }

    // Fetch the current content.
    LearningNodeDetail? detail;
    try {
      detail = await repository.detail(node.id);
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load content for editing')),
        );
      }
      return;
    }

    if (!detail.ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail.message ?? 'Failed to load content')),
        );
      }
      return;
    }

    final controller = TextEditingController(text: detail.content);

    if (!context.mounted) {
      return;
    }

    final newContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit content'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter new content',
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newContent == null || newContent == detail.content) {
      return;
    }

    await ref
        .read(learningControllerProvider.notifier)
        .edit(node.id, newContent);

    if (context.mounted) {
      final error = ref.read(learningControllerProvider).error;
      if (error == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content updated')));
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    LearningNode node,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete node'),
        content: Text('Delete "${node.fullLabel}"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(learningControllerProvider.notifier).delete(node.id);

    if (context.mounted) {
      final error = ref.read(learningControllerProvider).error;
      if (error == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Node deleted')));
      }
    }
  }
}
