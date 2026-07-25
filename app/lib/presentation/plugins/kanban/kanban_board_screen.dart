import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flit/presentation/plugins/kanban/kanban_column.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban board'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh board',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(kanbanBoardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BoardError(
          message: error.toString(),
          onRetry: () => ref.invalidate(kanbanBoardProvider),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Not connected to a gateway.'));
          }
          if (data.columns.isEmpty) {
            return const Center(child: Text('This board has no columns.'));
          }
          return _BoardView(board: data);
        },
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
