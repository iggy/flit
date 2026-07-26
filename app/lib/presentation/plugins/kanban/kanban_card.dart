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

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.detail, required this.theme});

  final KanbanTaskDetail detail;
  final ThemeData theme;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.detail.task;
    final linkCounts = task.linkCounts;
    final actionState = ref.watch(kanbanTaskActionControllerProvider);

    return ListView(
      children: <Widget>[
        Text(task.title, style: widget.theme.textTheme.titleLarge),
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
        if (actionState.error != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: widget.theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    actionState.error!,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => ref
                      .read(kanbanTaskActionControllerProvider.notifier)
                      .clearError(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: actionState.busy ? null : _showEditDialog,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
            FilledButton.tonalIcon(
              onPressed: actionState.busy ? null : () => _specify(task.id),
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Specify'),
            ),
            FilledButton.tonalIcon(
              onPressed: actionState.busy ? null : () => _decompose(task.id),
              icon: const Icon(Icons.call_split, size: 16),
              label: const Text('Decompose'),
            ),
            FilledButton.tonalIcon(
              onPressed: actionState.busy ? null : _showReassignDialog,
              icon: const Icon(Icons.person_outline, size: 16),
              label: const Text('Reassign'),
            ),
            FilledButton.tonalIcon(
              onPressed: actionState.busy ? null : () => _reclaim(task.id),
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Reclaim'),
            ),
            FilledButton.tonalIcon(
              onPressed: actionState.busy
                  ? null
                  : () => _confirmDelete(task.id),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
            ),
          ],
        ),
        if (task.latestSummary != null &&
            task.latestSummary!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text('Latest activity', style: widget.theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(task.latestSummary!, style: widget.theme.textTheme.bodySmall),
        ],
        if (task.body != null && task.body!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text('Body', style: widget.theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(task.body!),
        ],
        const SizedBox(height: 12),
        Text(
          'Comments (${widget.detail.comments.length})',
          style: widget.theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        if (widget.detail.comments.isEmpty)
          Text('No comments yet.', style: widget.theme.textTheme.bodySmall)
        else
          // Comment fields are NOT pinned by the docs (kept raw-ish in the
          // model) — render `author`/`body` tolerantly when present.
          for (final comment in widget.detail.comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (comment['author'] != null)
                    Text(
                      '${comment['author']}',
                      style: widget.theme.textTheme.labelMedium,
                    ),
                  Text(
                    comment['body']?.toString() ?? comment.toString(),
                    style: widget.theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Add comment',
            hintText: 'Type your comment',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: actionState.busy ? null : _addComment,
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send'),
          ),
        ),
      ],
    );
  }

  Future<void> _addComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) {
      return;
    }

    await ref
        .read(kanbanTaskActionControllerProvider.notifier)
        .addComment(widget.detail.task.id, body: body);

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (state.error == null) {
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.lastMessage ?? 'Comment added')),
        );
      }
    }
  }

  Future<void> _specify(String id) async {
    await ref.read(kanbanTaskActionControllerProvider.notifier).specify(id);

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (mounted && state.lastMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.lastMessage!)));
    }
  }

  Future<void> _decompose(String id) async {
    await ref.read(kanbanTaskActionControllerProvider.notifier).decompose(id);

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (mounted && state.lastMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.lastMessage!)));
    }
  }

  Future<void> _reclaim(String id) async {
    await ref.read(kanbanTaskActionControllerProvider.notifier).reclaim(id);

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (mounted && state.lastMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.lastMessage!)));
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(kanbanTaskActionControllerProvider.notifier)
          .deleteTask(id);

      final state = ref.read(kanbanTaskActionControllerProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.lastMessage ?? 'Task deleted')),
        );
      }
    }
  }

  void _showEditDialog() {
    final task = widget.detail.task;
    showDialog<void>(
      context: context,
      builder: (context) => _EditTaskDialog(task: task),
    );
  }

  void _showReassignDialog() {
    final task = widget.detail.task;
    showDialog<void>(
      context: context,
      builder: (context) => _ReassignDialog(taskId: task.id),
    );
  }
}

/// Edit task dialog (P5-05).
class _EditTaskDialog extends ConsumerStatefulWidget {
  const _EditTaskDialog({required this.task});

  final KanbanTask task;

  @override
  ConsumerState<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _assigneeController;
  late int? _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _bodyController = TextEditingController(text: widget.task.body);
    _assigneeController = TextEditingController(text: widget.task.assignee);
    _priority = widget.task.priority != null
        ? int.tryParse(widget.task.priority!)
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kanbanTaskActionControllerProvider);
    return AlertDialog(
      title: const Text('Edit task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assigneeController,
              decoration: const InputDecoration(labelText: 'Assignee'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: <DropdownMenuItem<int>>[
                const DropdownMenuItem<int>(value: null, child: Text('None')),
                for (final p in <int>[0, 1, 2, 3])
                  DropdownMenuItem<int>(value: p, child: Text('$p')),
              ],
              onChanged: (value) {
                setState(() {
                  _priority = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: state.busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.busy ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final assignee = _assigneeController.text.trim();

    await ref
        .read(kanbanTaskActionControllerProvider.notifier)
        .editTask(
          widget.task.id,
          title: title.isEmpty ? null : title,
          body: body.isEmpty ? null : body,
          assignee: assignee.isEmpty ? null : assignee,
          priority: _priority,
        );

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (mounted && state.error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.lastMessage ?? 'Task updated')),
      );
    }
  }
}

/// Reassign task dialog (P5-05).
class _ReassignDialog extends ConsumerStatefulWidget {
  const _ReassignDialog({required this.taskId});

  final String taskId;

  @override
  ConsumerState<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends ConsumerState<_ReassignDialog> {
  final _profileController = TextEditingController();
  bool _reclaimFirst = false;

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kanbanTaskActionControllerProvider);
    return AlertDialog(
      title: const Text('Reassign task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _profileController,
            decoration: const InputDecoration(
              labelText: 'Profile',
              hintText: 'Profile name',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Reclaim first'),
            subtitle: const Text('Release claim before reassigning'),
            value: _reclaimFirst,
            onChanged: (value) {
              setState(() {
                _reclaimFirst = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: state.busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.busy ? null : _submit,
          child: const Text('Reassign'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final profile = _profileController.text.trim();

    await ref
        .read(kanbanTaskActionControllerProvider.notifier)
        .reassign(
          widget.taskId,
          profile: profile.isEmpty ? null : profile,
          reclaimFirst: _reclaimFirst,
        );

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (mounted && state.error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.lastMessage ?? 'Task reassigned')),
      );
    }
  }
}
