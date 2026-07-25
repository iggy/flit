import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// New task dialog (P5-05): title (required) + body + assignee + priority
/// + triage toggle → createTask.
class KanbanNewTaskDialog extends ConsumerStatefulWidget {
  const KanbanNewTaskDialog({super.key});

  @override
  ConsumerState<KanbanNewTaskDialog> createState() =>
      _KanbanNewTaskDialogState();
}

class _KanbanNewTaskDialogState extends ConsumerState<KanbanNewTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _assigneeController = TextEditingController();
  int? _priority;
  bool _triage = false;

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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('New task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Task title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  hintText: 'Task description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _assigneeController,
                decoration: const InputDecoration(
                  labelText: 'Assignee',
                  hintText: 'Profile name',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
                items: <DropdownMenuItem<int>>[
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('None'),
                  ),
                  for (final p in <int>[0, 1, 2, 3])
                    DropdownMenuItem<int>(
                      value: p,
                      child: Text('$p'),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _priority = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Triage'),
                value: _triage,
                onChanged: (value) {
                  setState(() {
                    _triage = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: state.busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.busy ? null : _submit,
          child: state.busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final assignee = _assigneeController.text.trim();

    await ref.read(kanbanTaskActionControllerProvider.notifier).createTask(
          title: title,
          body: body.isEmpty ? null : body,
          assignee: assignee.isEmpty ? null : assignee,
          priority: _priority,
          triage: _triage,
        );

    final state = ref.read(kanbanTaskActionControllerProvider);
    if (mounted && state.error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.lastMessage ?? 'Task created')),
      );
    }
  }
}
