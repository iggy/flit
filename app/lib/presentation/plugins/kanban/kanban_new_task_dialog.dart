import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// New task dialog (P5-05): title (required) + body + assignee + priority
/// + triage toggle → createTask.
///
/// The per-task worker overrides (model / provider / thinking depth / goal
/// loop) live behind an "Execution" expander — none of them are sent unless
/// set, so an unopened expander creates exactly the task it used to.
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
  final _modelController = TextEditingController();
  final _providerController = TextEditingController();
  final _goalMaxTurnsController = TextEditingController();
  int? _priority;
  bool _triage = false;

  /// `VALID_REASONING_EFFORTS` plus `"none"` (thinking off, not "inherit").
  static const _effortLevels = <String>[
    'none',
    'minimal',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
    'ultra',
  ];

  String? _reasoningEffort;
  bool _goalMode = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _assigneeController.dispose();
    _modelController.dispose();
    _providerController.dispose();
    _goalMaxTurnsController.dispose();
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
              ExpansionTile(
                title: const Text('Execution'),
                subtitle: const Text('Worker model, thinking depth, goal loop'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: <Widget>[
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model override',
                      helperText: 'Empty inherits the profile model',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _providerController,
                    decoration: const InputDecoration(
                      labelText: 'Provider override',
                      helperText: 'Provider the model above belongs to',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _reasoningEffort,
                    decoration: const InputDecoration(
                      labelText: 'Thinking depth',
                    ),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Inherit profile'),
                      ),
                      for (final level in _effortLevels)
                        DropdownMenuItem<String>(
                          value: level,
                          child: Text(level == 'none' ? 'none (off)' : level),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _reasoningEffort = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Goal loop'),
                    subtitle: const Text(
                      'Keep working until a judge agrees it is done',
                    ),
                    value: _goalMode,
                    onChanged: (value) {
                      setState(() {
                        _goalMode = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_goalMode)
                    TextFormField(
                      controller: _goalMaxTurnsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Goal turn budget',
                        helperText: 'Empty uses the gateway default',
                      ),
                    ),
                ],
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
    final model = _modelController.text.trim();
    final provider = _providerController.text.trim();
    final goalMaxTurns = int.tryParse(_goalMaxTurnsController.text.trim());

    await ref
        .read(kanbanTaskActionControllerProvider.notifier)
        .createTask(
          title: title,
          body: body.isEmpty ? null : body,
          assignee: assignee.isEmpty ? null : assignee,
          priority: _priority,
          triage: _triage,
          modelOverride: model.isEmpty ? null : model,
          providerOverride: provider.isEmpty ? null : provider,
          reasoningEffort: _reasoningEffort,
          // The create body defaults goal_mode to false server-side, so
          // only bother sending it when it's on.
          goalMode: _goalMode ? true : null,
          goalMaxTurns: _goalMode ? goalMaxTurns : null,
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
