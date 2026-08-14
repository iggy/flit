/// Live task tracking for the current turn's tool calls.
///
/// Extracts tasks from the current streaming message's tool calls
/// so the UI can show a sticky progress panel at the bottom.
library;

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live tasks from the current streaming turn, or empty when not streaming.
/// Flattens tasks from all tool calls in the current streaming message.
final liveTasksProvider = Provider<List<ToolTask>>((ref) {
  final liveId = ref.watch(activeSessionProvider).liveId;
  if (liveId == null) return const <ToolTask>[];

  final fold = ref.watch(messageListProvider(liveId));
  if (fold.messages.isEmpty) return const <ToolTask>[];

  final lastMessage = fold.messages.last;
  if (lastMessage.role != MessageRole.assistant || !lastMessage.streaming) {
    return const <ToolTask>[];
  }

  // Flatten all tasks from all tool calls
  final allTasks = <ToolTask>[];
  for (final tool in lastMessage.toolCalls) {
    allTasks.addAll(tool.tasks);
  }
  return allTasks;
});

/// Whether the agent is currently working (streaming a turn).
final isAgentWorkingProvider = Provider<bool>((ref) {
  final liveId = ref.watch(activeSessionProvider).liveId;
  if (liveId == null) return false;

  final fold = ref.watch(messageListProvider(liveId));
  if (fold.messages.isEmpty) return false;

  final lastMessage = fold.messages.last;
  return lastMessage.role == MessageRole.assistant && lastMessage.streaming;
});

/// Summary counts of tasks for quick status display.
class TaskCounts {
  const TaskCounts({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  final int total;
  final int completed;
  final int inProgress;
  final int pending;

  bool get isEmpty => total == 0;

  double get progress => total > 0 ? completed / total : 0;

  @override
  String toString() =>
      'TaskCounts(total: $total, completed: $completed, inProgress: $inProgress, pending: $pending)';
}

/// Counts of tasks by status.
final taskCountsProvider = Provider<TaskCounts>((ref) {
  final tasks = ref.watch(liveTasksProvider);
  var completed = 0;
  var inProgress = 0;
  var pending = 0;
  for (final task in tasks) {
    switch (task.status) {
      case ToolTaskStatus.completed:
        completed++;
      case ToolTaskStatus.inProgress:
        inProgress++;
      case ToolTaskStatus.pending:
        pending++;
      case ToolTaskStatus.cancelled:
        // Count cancelled as completed for progress purposes
        completed++;
    }
  }
  return TaskCounts(
    total: tasks.length,
    completed: completed,
    inProgress: inProgress,
    pending: pending,
  );
});
