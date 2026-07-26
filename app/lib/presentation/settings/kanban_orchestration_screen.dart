/// Kanban orchestration & assignees screen (P5-07).
library;

import 'package:flit/application/plugins/kanban_fleet_providers.dart';
import 'package:flit/domain/models/kanban_fleet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KanbanOrchestrationScreen extends ConsumerWidget {
  const KanbanOrchestrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigneesAsync = ref.watch(kanbanAssigneesProvider);
    final profilesAsync = ref.watch(kanbanProfilesProvider);
    final orchestrationAsync = ref.watch(kanbanOrchestrationProvider);
    final actionState = ref.watch(kanbanFleetActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kanban Orchestration')),
      body: ListView(
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
                  onPressed: ref
                      .read(kanbanFleetActionControllerProvider.notifier)
                      .clearError,
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
          _buildAssigneesSection(context, assigneesAsync),
          const Divider(),
          _buildProfilesSection(context, ref, profilesAsync, actionState),
          const Divider(),
          _buildOrchestrationSection(
            context,
            ref,
            orchestrationAsync,
            profilesAsync,
            assigneesAsync,
            actionState,
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneesSection(
    BuildContext context,
    AsyncValue<List<KanbanAssignee>> assigneesAsync,
  ) {
    return assigneesAsync.when(
      data: (assignees) {
        return ExpansionTile(
          title: Text('Assignees (${assignees.length})'),
          initiallyExpanded: false,
          children: assignees.isEmpty
              ? <Widget>[const ListTile(title: Text('No assignees'))]
              : assignees.map((assignee) {
                  return ListTile(
                    leading: Icon(
                      assignee.onDisk ? Icons.check_circle : Icons.cloud,
                    ),
                    title: Text(assignee.name),
                    subtitle: assignee.counts.isNotEmpty
                        ? Text(
                            assignee.counts.entries
                                .map(
                                  (MapEntry<String, int> e) =>
                                      '${e.key}: ${e.value}',
                                )
                                .join(', '),
                          )
                        : null,
                    trailing: assignee.onDisk
                        ? const Text('On disk')
                        : const Text('Remote'),
                  );
                }).toList(),
        );
      },
      loading: () => const ListTile(
        title: Text('Assignees'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ListTile(
        title: const Text('Assignees'),
        subtitle: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildProfilesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<KanbanProfile>> profilesAsync,
    KanbanFleetActionState actionState,
  ) {
    return profilesAsync.when(
      data: (profiles) {
        return ExpansionTile(
          title: Text('Profiles (${profiles.length})'),
          initiallyExpanded: false,
          children: profiles.isEmpty
              ? <Widget>[const ListTile(title: Text('No profiles'))]
              : profiles.map((profile) {
                  return ListTile(
                    leading: profile.isDefault
                        ? const Icon(Icons.star)
                        : const Icon(Icons.person),
                    title: Text(profile.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${profile.provider} / ${profile.model}'),
                        if (profile.description.isNotEmpty)
                          Text(
                            profile.description,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        Text('Skills: ${profile.skillCount}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: actionState.busy
                          ? null
                          : () => _showEditDescriptionDialog(
                              context,
                              ref,
                              profile.name,
                              profile.description,
                            ),
                    ),
                  );
                }).toList(),
        );
      },
      loading: () => const ListTile(
        title: Text('Profiles'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ListTile(
        title: const Text('Profiles'),
        subtitle: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildOrchestrationSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<KanbanOrchestration?> orchestrationAsync,
    AsyncValue<List<KanbanProfile>> profilesAsync,
    AsyncValue<List<KanbanAssignee>> assigneesAsync,
    KanbanFleetActionState actionState,
  ) {
    return orchestrationAsync.when(
      data: (orchestration) {
        if (orchestration == null) {
          return const ListTile(title: Text('No orchestration settings'));
        }
        return ExpansionTile(
          title: const Text('Orchestration Settings'),
          initiallyExpanded: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildProfileDropdown(
                    context,
                    ref,
                    'Orchestrator Profile',
                    orchestration.orchestratorProfile,
                    profilesAsync,
                    actionState,
                    (value) {
                      ref
                          .read(kanbanFleetActionControllerProvider.notifier)
                          .setOrchestration(orchestratorProfile: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildAssigneeDropdown(
                    context,
                    ref,
                    'Default Assignee',
                    orchestration.defaultAssignee,
                    assigneesAsync,
                    actionState,
                    (value) {
                      ref
                          .read(kanbanFleetActionControllerProvider.notifier)
                          .setOrchestration(defaultAssignee: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto Decompose'),
                    value: orchestration.autoDecompose,
                    onChanged: actionState.busy
                        ? null
                        : (value) {
                            ref
                                .read(
                                  kanbanFleetActionControllerProvider.notifier,
                                )
                                .setOrchestration(autoDecompose: value);
                          },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Promote Children'),
                    value: orchestration.autoPromoteChildren,
                    onChanged: actionState.busy
                        ? null
                        : (value) {
                            ref
                                .read(
                                  kanbanFleetActionControllerProvider.notifier,
                                )
                                .setOrchestration(autoPromoteChildren: value);
                          },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resolved:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Orchestrator: ${orchestration.resolvedOrchestratorProfile}',
                  ),
                  Text(
                    'Default assignee: ${orchestration.resolvedDefaultAssignee}',
                  ),
                  Text('Active profile: ${orchestration.activeProfile}'),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const ListTile(
        title: Text('Orchestration Settings'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => ListTile(
        title: const Text('Orchestration Settings'),
        subtitle: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Widget _buildProfileDropdown(
    BuildContext context,
    WidgetRef ref,
    String label,
    String currentValue,
    AsyncValue<List<KanbanProfile>> profilesAsync,
    KanbanFleetActionState actionState,
    void Function(String) onChanged,
  ) {
    return profilesAsync.when(
      data: (profiles) {
        return DropdownButtonFormField<String>(
          initialValue: currentValue.isEmpty ? null : currentValue,
          decoration: InputDecoration(labelText: label),
          items: profiles
              .map(
                (profile) => DropdownMenuItem<String>(
                  value: profile.name,
                  child: Text(profile.name),
                ),
              )
              .toList(),
          onChanged: actionState.busy
              ? null
              : (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          errorText: 'Failed to load profiles',
        ),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
      ),
    );
  }

  Widget _buildAssigneeDropdown(
    BuildContext context,
    WidgetRef ref,
    String label,
    String currentValue,
    AsyncValue<List<KanbanAssignee>> assigneesAsync,
    KanbanFleetActionState actionState,
    void Function(String) onChanged,
  ) {
    return assigneesAsync.when(
      data: (assignees) {
        return DropdownButtonFormField<String>(
          initialValue: currentValue.isEmpty ? null : currentValue,
          decoration: InputDecoration(labelText: label),
          items: assignees
              .map(
                (assignee) => DropdownMenuItem<String>(
                  value: assignee.name,
                  child: Text(assignee.name),
                ),
              )
              .toList(),
          onChanged: actionState.busy
              ? null
              : (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          errorText: 'Failed to load assignees',
        ),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
      ),
    );
  }

  void _showEditDescriptionDialog(
    BuildContext context,
    WidgetRef ref,
    String profileName,
    String currentDescription,
  ) {
    final controller = TextEditingController(text: currentDescription);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $profileName Description'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter profile description',
          ),
          maxLines: 3,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(kanbanFleetActionControllerProvider.notifier)
                  .setProfileDescription(profileName, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
