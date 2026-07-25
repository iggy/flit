/// Project detail screen (tickets P4-07, P4-08): manage folders for a project.
library;

import 'package:flit/application/projects/projects_providers.dart';
import 'package:flit/domain/models/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProjects = ref.watch(projectsListProvider);
    final controllerState = ref.watch(projectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Folders'),
      ),
      body: Column(
        children: <Widget>[
          if (controllerState.error != null)
            _ErrorBanner(
              message: controllerState.error!,
              onDismiss: () {
                ref.read(projectsControllerProvider.notifier).clearError();
              },
            ),
          if (controllerState.busy)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Expanded(
            child: asyncProjects.when(
              data: (projectsList) {
                final project = projectsList.projects
                    .where((p) => p.id == projectId)
                    .firstOrNull;

                if (project == null) {
                  return const Center(
                    child: Text('Project not found'),
                  );
                }

                return _ProjectFoldersList(project: project);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading project: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFolderDialog(context, ref),
        tooltip: 'Add folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, WidgetRef ref) {
    final pathController = TextEditingController();
    final labelController = TextEditingController();
    var isPrimary = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Folder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      labelText: 'Folder path',
                      hintText: '/path/to/folder',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label (optional)',
                      hintText: 'My Folder',
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Set as primary'),
                    value: isPrimary,
                    onChanged: (value) {
                      setState(() {
                        isPrimary = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
                    final path = pathController.text.trim();
                    if (path.isEmpty) {
                      return;
                    }
                    final label = labelController.text.trim();
                    ref.read(projectsControllerProvider.notifier).addFolder(
                          projectId,
                          path,
                          label: label.isEmpty ? null : label,
                          isPrimary: isPrimary,
                        );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProjectFoldersList extends ConsumerWidget {
  const _ProjectFoldersList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (project.folders.isEmpty) {
      return const Center(
        child: Text('No folders yet. Add one to get started.'),
      );
    }

    return ListView.builder(
      itemCount: project.folders.length,
      itemBuilder: (context, index) {
        final folder = project.folders[index];

        return ListTile(
          leading: Icon(
            folder.isPrimary ? Icons.star : Icons.folder_outlined,
            color: folder.isPrimary
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text(folder.label ?? folder.path),
          subtitle: folder.label != null ? Text(folder.path) : null,
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'primary':
                  ref
                      .read(projectsControllerProvider.notifier)
                      .setPrimary(project.id, folder.path);
                case 'remove':
                  _showRemoveDialog(context, ref, folder);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              if (!folder.isPrimary)
                const PopupMenuItem<String>(
                  value: 'primary',
                  child: Text('Set as primary'),
                ),
              const PopupMenuItem<String>(
                value: 'remove',
                child: Text('Remove'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectFolder folder,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Folder'),
          content: Text(
            'Are you sure you want to remove "${folder.label ?? folder.path}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(projectsControllerProvider.notifier)
                    .removeFolder(project.id, folder.path);
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
