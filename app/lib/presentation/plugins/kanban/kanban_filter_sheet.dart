import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The board's workflow filter sheet — the `workflow_template_id` /
/// `current_step_key` predicates `GET /board` accepts (06-kanban-rest.md).
///
/// Both are pickers rather than text fields: template ids are opaque strings
/// and a typo would silently return an empty board. The choices are the values
/// present on the (unfiltered) board, so a filter can never select nothing.
///
/// The two predicates are independent server-side — a step key with no
/// template matches that step across every workflow — so both are offered
/// separately. Picking a template does narrow the step list to that
/// template's own steps, and drops a step that isn't one of them.
class KanbanFilterSheet extends ConsumerStatefulWidget {
  const KanbanFilterSheet({super.key});

  @override
  ConsumerState<KanbanFilterSheet> createState() => _KanbanFilterSheetState();
}

class _KanbanFilterSheetState extends ConsumerState<KanbanFilterSheet> {
  String? _templateId;
  String? _stepKey;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(kanbanBoardFilterProvider);
    _templateId = filter.workflowTemplateId;
    _stepKey = filter.currentStepKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ref.watch(kanbanWorkflowOptionsProvider);
    // The board currently on screen may already be filtered, so the option
    // lists are kept from the last unfiltered load — but the value in the
    // filter must stay selectable either way.
    final templateIds = _withSelected(options.templateIds, _templateId);
    final stepKeys = _withSelected(options.stepKeysFor(_templateId), _stepKey);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Filter by workflow', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'The gateway filters the board itself, so only matching tasks '
            'are fetched.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _templateId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Workflow template',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any template'),
              ),
              for (final id in templateIds)
                DropdownMenuItem<String>(
                  value: id,
                  child: Text(id, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              setState(() {
                _templateId = value;
                // A step that doesn't exist under the new template would
                // fetch an empty board; drop it instead.
                if (_stepKey != null &&
                    !options.stepKeysFor(value).contains(_stepKey)) {
                  _stepKey = null;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _stepKey,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Current step',
              border: const OutlineInputBorder(),
              helperText: _templateId == null
                  ? 'Matches this step in any workflow'
                  : null,
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any step'),
              ),
              for (final key in stepKeys)
                DropdownMenuItem<String>(
                  value: key,
                  child: Text(key, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              setState(() {
                _stepKey = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  ref.read(kanbanBoardFilterProvider.notifier).clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  ref
                      .read(kanbanBoardFilterProvider.notifier)
                      .apply(
                        workflowTemplateId: _templateId,
                        currentStepKey: _stepKey,
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A dropdown throws when its value isn't among the items, and the harvested
  /// options can lag the active filter (board still loading, or the last task
  /// using that template just moved off the board), so the current selection
  /// is always offered.
  static List<String> _withSelected(List<String> values, String? selected) {
    if (selected == null || values.contains(selected)) {
      return values;
    }
    return <String>[selected, ...values];
  }
}
