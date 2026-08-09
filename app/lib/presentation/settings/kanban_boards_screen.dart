/// Kanban boards management screen (P5-06).
library;

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KanbanBoardsScreen extends ConsumerWidget {
  const KanbanBoardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(kanbanBoardsProvider);
    final actionState = ref.watch(kanbanFleetActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Boards'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: boardsAsync.when(
        data: (boardList) {
          if (boardList == null || boardList.boards.isEmpty) {
            return const Center(child: Text('No boards available'));
          }
          return Column(
            children: <Widget>[
              if (actionState.error != null)
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    title: Text(
                      actionState.error!,
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
                            .read(kanbanFleetActionControllerProvider.notifier)
                            .clearError();
                      },
                    ),
                  ),
                ),
              if (actionState.lastMessage != null)
                Material(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    title: Text(
                      actionState.lastMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Current board: ${boardList.current}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: boardList.boards.length,
                  itemBuilder: (context, index) {
                    final board = boardList.boards[index];
                    return ListTile(
                      leading: board.isCurrent
                          ? const Icon(Icons.check_circle)
                          : const Icon(Icons.circle_outlined),
                      title: Text(
                        board.name.isNotEmpty ? board.name : board.slug,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (board.description.isNotEmpty)
                            Text(board.description),
                          if (board.projectName != null)
                            Text('Project: ${board.projectName}')
                          else if (board.projectId != null)
                            Text('Project: ${board.projectId}'),
                          Text('Total tasks: ${board.total}'),
                          if (board.archived)
                            const Text(
                              '(Archived)',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      trailing: actionState.busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'switch') {
                                  ref
                                      .read(
                                        kanbanFleetActionControllerProvider
                                            .notifier,
                                      )
                                      .switchBoard(board.slug);
                                } else if (value == 'archive') {
                                  ref
                                      .read(
                                        kanbanFleetActionControllerProvider
                                            .notifier,
                                      )
                                      .deleteBoard(board.slug);
                                }
                              },
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<String>>[
                                    if (!board.isCurrent)
                                      const PopupMenuItem<String>(
                                        value: 'switch',
                                        child: Text('Switch to this board'),
                                      ),
                                    if (!board.archived)
                                      const PopupMenuItem<String>(
                                        value: 'archive',
                                        child: Text('Archive board'),
                                      ),
                                  ],
                            ),
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
                  'Failed to load boards',
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

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final slugController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final projectController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: slugController,
              decoration: const InputDecoration(
                labelText: 'Slug',
                hintText: 'my-board',
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            TextField(
              controller: projectController,
              decoration: const InputDecoration(
                labelText: 'Project (optional)',
                // A scoped board takes the project's primary repo as its
                // default workdir and hands the project to every new task.
                helperText: 'Project id or slug to scope this board to',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (slugController.text.isNotEmpty) {
                ref
                    .read(kanbanFleetActionControllerProvider.notifier)
                    .createBoard(
                      slug: slugController.text,
                      name: nameController.text.isNotEmpty
                          ? nameController.text
                          : null,
                      description: descriptionController.text.isNotEmpty
                          ? descriptionController.text
                          : null,
                      projectId: projectController.text.isNotEmpty
                          ? projectController.text
                          : null,
                    );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
