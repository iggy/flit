import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/presentation/plugins/kanban/kanban_column.dart';
import 'package:flit/presentation/plugins/kanban/kanban_filter_sheet.dart';
import 'package:flit/presentation/plugins/kanban/kanban_new_task_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kanban board (ticket P1-15): horizontally scrollable columns in the FIXED
/// order the server sends them (triage/todo/scheduled/ready/running/blocked/
/// review/done per 06-kanban-rest.md — rendered as received, never
/// re-ordered client-side).
///
/// MVP refresh is poll-on-focus: initial fetch on build + a refresh button.
/// The live `/api/plugins/kanban/events` WS feed is Phase 5.
class KanbanBoardScreen extends ConsumerWidget {
  const KanbanBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(kanbanBoardProvider);
    final filter = ref.watch(kanbanBoardFilterProvider);
    // No workflow-driven tasks (or a gateway too old to send the fields) means
    // the filter can only ever empty the board — so don't offer it.
    final hasWorkflows =
        !ref.watch(kanbanWorkflowOptionsProvider).isEmpty || filter.isActive;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban board'),
        actions: <Widget>[
          if (hasWorkflows)
            IconButton(
              tooltip: filter.isActive
                  ? 'Workflow filter (active)'
                  : 'Filter by workflow',
              icon: Icon(
                filter.isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
              onPressed: () => _showFilterSheet(context),
            ),
          IconButton(
            tooltip: 'New task',
            icon: const Icon(Icons.add),
            onPressed: () => _showNewTaskDialog(context),
          ),
          IconButton(
            tooltip: 'Refresh board',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(kanbanBoardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // A filtered board looks exactly like a board whose tasks vanished,
          // so say what is being hidden and offer the way out.
          if (filter.isActive)
            _FilterBanner(
              filter: filter,
              onClear: () =>
                  ref.read(kanbanBoardFilterProvider.notifier).clear(),
            ),
          Expanded(
            child: board.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _BoardError(
                message: error.toString(),
                onRetry: () => ref.invalidate(kanbanBoardProvider),
              ),
              data: (data) {
                if (data == null) {
                  return const Center(
                    child: Text('Not connected to a gateway.'),
                  );
                }
                if (data.columns.isEmpty) {
                  return const Center(
                    child: Text('This board has no columns.'),
                  );
                }
                return _BoardView(board: data);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewTaskDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const KanbanNewTaskDialog(),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const KanbanFilterSheet(),
    );
  }
}

/// Says which workflow predicates are narrowing the board, and clears them.
class _FilterBanner extends StatelessWidget {
  const _FilterBanner({required this.filter, required this.onClear});

  final KanbanBoardFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = filter.workflowTemplateId;
    final step = filter.currentStepKey;
    final parts = <String>[
      if (template != null) 'workflow $template',
      if (step != null) 'step $step',
    ];
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.filter_alt,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing ${parts.join(' · ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({required this.board});

  final KanbanBoard board;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final column in board.columns)
            KanbanColumnView(column: column, columnNames: board.columnNames),
        ],
      ),
    );
  }
}

class _BoardError extends StatelessWidget {
  const _BoardError({required this.message, required this.onRetry});

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
            'Could not load the board',
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
