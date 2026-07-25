import 'package:flit/application/rollback/rollback_providers.dart';
import 'package:flit/domain/models/rollback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Checkpoints screen (tickets P6-05, P6-06): renders the checkpoint list for
/// the active session with view-diff and restore actions.
class CheckpointsScreen extends ConsumerWidget {
  const CheckpointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(checkpointListProvider);
    final controllerState = ref.watch(rollbackControllerProvider);

    // Show success feedback after a full restore.
    ref.listen(rollbackControllerProvider, (previous, next) {
      if (next.lastResult != null) {
        final result = next.lastResult!;
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restored to ${result.restoredTo ?? 'checkpoint'}'
                '${result.historyRemoved != null ? ' · ${result.historyRemoved} turn(s) removed' : ''}',
              ),
            ),
          );
          ref.read(rollbackControllerProvider.notifier).clearResult();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Restore failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          ref.read(rollbackControllerProvider.notifier).clearResult();
        }
      }
    });

    // Show error feedback.
    if (controllerState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controllerState.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(rollbackControllerProvider.notifier).clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoints'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(checkpointListProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CheckpointsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(checkpointListProvider),
        ),
        data: (checkpointList) {
          if (!checkpointList.enabled) {
            return const _CheckpointsDisabled();
          }
          if (checkpointList.checkpoints.isEmpty) {
            return const _CheckpointsEmpty();
          }
          return ListView.builder(
            itemCount: checkpointList.checkpoints.length,
            itemBuilder: (context, index) {
              final checkpoint = checkpointList.checkpoints[index];
              return _CheckpointTile(
                checkpoint: checkpoint,
                busy: controllerState.busy,
              );
            },
          );
        },
      ),
    );
  }
}

class _CheckpointsDisabled extends StatelessWidget {
  const _CheckpointsDisabled();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Checkpointing is disabled for this session.'),
    );
  }
}

class _CheckpointsEmpty extends StatelessWidget {
  const _CheckpointsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No checkpoints yet.'));
  }
}

class _CheckpointsError extends StatelessWidget {
  const _CheckpointsError({required this.message, required this.onRetry});

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
            'Could not load checkpoints',
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

class _CheckpointTile extends ConsumerWidget {
  const _CheckpointTile({
    required this.checkpoint,
    required this.busy,
  });

  final Checkpoint checkpoint;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortHash = checkpoint.hash.length > 8
        ? checkpoint.hash.substring(0, 8)
        : checkpoint.hash;
    final title = checkpoint.message.isNotEmpty
        ? checkpoint.message
        : 'checkpoint';

    return ListTile(
      title: Text(title),
      subtitle: Text('${checkpoint.timestamp} · $shortHash'),
      trailing: PopupMenuButton<String>(
        enabled: !busy,
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'diff',
            child: Text('View diff'),
          ),
          const PopupMenuItem<String>(
            value: 'restore',
            child: Text('Restore to this checkpoint'),
          ),
        ],
        onSelected: (value) {
          if (value == 'diff') {
            _showDiffBottomSheet(context, ref, checkpoint.hash);
          } else if (value == 'restore') {
            _showRestoreConfirmDialog(context, ref, checkpoint.hash);
          }
        },
      ),
    );
  }

  void _showDiffBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String hash,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _DiffView(
          hash: hash,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showRestoreConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String hash,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore repository?'),
        content: const Text(
          'This will rewrite the git working tree to this checkpoint '
          'AND drop chat history since this checkpoint. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(rollbackControllerProvider.notifier).restore(hash);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

class _DiffView extends ConsumerWidget {
  const _DiffView({
    required this.hash,
    required this.scrollController,
  });

  final String hash;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<CheckpointDiff?>(
      future: ref.read(rollbackControllerProvider.notifier).loadDiff(hash),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final diff = snapshot.data;
        if (diff == null) {
          final error = ref.read(rollbackControllerProvider).error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error ?? 'Could not load diff',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (diff.stat.isEmpty && diff.diff.isEmpty) {
          return const Center(child: Text('No changes'));
        }
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (diff.stat.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SelectableText(
                  diff.stat,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            if (diff.diff.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  diff.diff,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
          ],
        );
      },
    );
  }
}
