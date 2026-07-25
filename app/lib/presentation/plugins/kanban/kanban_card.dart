import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One task card (ticket P1-15): title, assignee, a 1–2 line
/// `latest_summary` preview, comment-count / progress badges when present,
/// and a "move to" popup menu listing the OTHER columns.
class KanbanCard extends ConsumerWidget {
  const KanbanCard({super.key, required this.task, required this.columnNames});

  final KanbanTask task;

  /// All column names on the board, in server order.
  final List<String> columnNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(task.title, style: theme.textTheme.titleSmall),
                  ),
                  _MoveMenu(
                    columnNames: columnNames,
                    currentColumn: task.status,
                    onSelected: (column) => _move(context, ref, column),
                  ),
                ],
              ),
              if (task.assignee != null) ...<Widget>[
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.assignee!,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (task.latestSummary != null &&
                  task.latestSummary!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  task.latestSummary!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task.commentCount != null || task.progress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: <Widget>[
                      if (task.commentCount != null) ...<Widget>[
                        Icon(
                          Icons.comment_outlined,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${task.commentCount}',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (task.progress != null)
                        Text(
                          '${task.progress!.done}/${task.progress!.total}',
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _move(BuildContext context, WidgetRef ref, String toColumn) {
    ref
        .read(kanbanBoardProvider.notifier)
        .moveTask(task.id, toColumn)
        .catchError((Object error) {
          // The optimistic move was rolled back by the notifier; tell the
          // user why the card snapped back.
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Move failed: $error')));
          }
        });
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => KanbanTaskDetailSheet(taskId: task.id),
    );
  }
}

class _MoveMenu extends StatelessWidget {
  const _MoveMenu({
    required this.columnNames,
    required this.currentColumn,
    required this.onSelected,
  });

  final List<String> columnNames;
  final String? currentColumn;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // The OTHER columns only — moving to the current column is a no-op.
    final targets = columnNames
        .where((name) => name != currentColumn)
        .toList(growable: false);
    return PopupMenuButton<String>(
      tooltip: 'Move task',
      iconSize: 18,
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        for (final name in targets)
          PopupMenuItem<String>(value: name, child: Text('Move to $name')),
      ],
    );
  }
}

/// Modal detail drawer (ticket P1-15): full body, comments list,
/// latest summary, and link counts. Fetches
/// `GET /api/plugins/kanban/tasks/{id}` via [kanbanTaskDetailProvider].
class KanbanTaskDetailSheet extends ConsumerWidget {
  const KanbanTaskDetailSheet({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(kanbanTaskDetailProvider(taskId));
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline),
                const SizedBox(height: 8),
                Text('Could not load the task: $error'),
              ],
            ),
          ),
          data: (data) {
            if (data == null) {
              return const Center(child: Text('Not connected to a gateway.'));
            }
            return _DetailBody(detail: data, theme: theme);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.theme});

  final KanbanTaskDetail detail;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final task = detail.task;
    final linkCounts = task.linkCounts;
    return ListView(
      children: <Widget>[
        Text(task.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: <Widget>[
            if (task.status != null) Text('Status: ${task.status}'),
            if (task.assignee != null) Text('Assignee: ${task.assignee}'),
            if (task.priority != null) Text('Priority: ${task.priority}'),
            if (linkCounts != null)
              Text(
                'Links: ${linkCounts.parents} parents, '
                '${linkCounts.children} children',
              ),
          ],
        ),
        if (task.latestSummary != null &&
            task.latestSummary!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text('Latest activity', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(task.latestSummary!, style: theme.textTheme.bodySmall),
        ],
        if (task.body != null && task.body!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text('Body', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(task.body!),
        ],
        const SizedBox(height: 12),
        Text(
          'Comments (${detail.comments.length})',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        if (detail.comments.isEmpty)
          Text('No comments yet.', style: theme.textTheme.bodySmall)
        else
          // Comment fields are NOT pinned by the docs (kept raw-ish in the
          // model) — render `author`/`body` tolerantly when present.
          for (final comment in detail.comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (comment['author'] != null)
                    Text(
                      '${comment['author']}',
                      style: theme.textTheme.labelMedium,
                    ),
                  Text(
                    comment['body']?.toString() ?? comment.toString(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
