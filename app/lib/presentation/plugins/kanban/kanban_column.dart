import 'package:flutter/material.dart';
import 'package:hermes/domain/models/kanban.dart';
import 'package:hermes/presentation/plugins/kanban/kanban_card.dart';

/// One board column: name header + task count + the scrollable list of
/// [KanbanCard]s. Columns arrive in fixed server order; this widget renders
/// whatever order it is given.
class KanbanColumnView extends StatelessWidget {
  const KanbanColumnView({
    super.key,
    required this.column,
    required this.columnNames,
  });

  final KanbanColumn column;

  /// Every column name on the board — the "move to" menu lists the OTHER
  /// columns for each card.
  final List<String> columnNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    column.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${column.tasks.length}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: column.tasks.isEmpty
                // Empty-state hint (P1-16): a taskless column should not
                // render as a mysterious blank box.
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No tasks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: column.tasks.length,
                    itemBuilder: (context, index) => KanbanCard(
                      task: column.tasks[index],
                      columnNames: columnNames,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
