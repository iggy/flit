/// Projects screen (tickets P4-07, P4-08): list, create, switch active,
/// archive, delete, and navigate to detail.
library;

import 'package:flit/application/projects/projects_providers.dart';
import 'package:flit/domain/models/project.dart';
import 'package:flit/presentation/settings/project_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncProjects = ref.watch(projectsListProvider);
    final controllerState = ref.watch(projectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
            tooltip: 'Create project',
          ),
        ],
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
                final projects = projectsList.projects;
                final activeId = projectsList.activeId;

                if (projects.isEmpty) {
                  return const Center(
                    child: Text('No projects yet. Create one to get started.'),
                  );
                }

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final isActive = project.id == activeId;

                    return ListTile(
                      leading: project.icon != null
                          ? Text(
                              project.icon!,
                              style: const TextStyle(fontSize: 24),
                            )
                          : const Icon(Icons.folder_outlined),
                      title: Row(
                        children: <Widget>[
                          Flexible(child: Text(project.name)),
                          if (isActive) ...<Widget>[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Active'),
                              labelStyle: const TextStyle(fontSize: 11),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${project.folders.length} folder${project.folders.length == 1 ? '' : 's'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditDialog(context, project);
                            case 'archive':
                              _archive(project.id, restore: project.archived);
                            case 'delete':
                              _showDeleteDialog(context, project);
                            case 'folders':
                              _navigateToDetail(context, project.id);
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'folders',
                            child: Text('Manage folders'),
                          ),
                          PopupMenuItem<String>(
                            value: 'archive',
                            child: Text(
                              project.archived ? 'Restore' : 'Archive',
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                      onTap: isActive
                          ? null
                          : () {
                              ref
                                  .read(projectsControllerProvider.notifier)
                                  .setActive(project.id);
                            },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading projects: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String projectId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ProjectDetailScreen(projectId: projectId),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final folderController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Project name',
                  hintText: 'My Project',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: folderController,
                decoration: const InputDecoration(
                  labelText: 'First folder path (optional)',
                  hintText: '/path/to/folder',
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                final folder = folderController.text.trim();
                ref.read(projectsControllerProvider.notifier).create(
                      name: name,
                      folders: folder.isEmpty ? null : <String>[folder],
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Project project) {
    final nameController = TextEditingController(text: project.name);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Project'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Project name',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                ref
                    .read(projectsControllerProvider.notifier)
                    .update(project.id, name: name);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Project project) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text(
            'Are you sure you want to delete "${project.name}"? This cannot be undone.',
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
                    .delete(project.id);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _archive(String id, {required bool restore}) {
    ref.read(projectsControllerProvider.notifier).archive(id, restore: restore);
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
