/// Cron job list & manage screen (P5-01).
library;

import 'package:flit/application/cron/cron_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CronScreen extends ConsumerWidget {
  const CronScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(cronJobsProvider);
    final actionState = ref.watch(cronActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled tasks')),
      body: jobsAsync.when(
        data: (jobs) {
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
                            .read(cronActionControllerProvider.notifier)
                            .clearError();
                      },
                    ),
                  ),
                ),
              if (jobs.isEmpty)
                const Expanded(child: Center(child: Text('No scheduled tasks')))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return ListTile(
                        title: Text(job.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Schedule: ${job.schedule}'),
                            if (job.nextRunAt != null)
                              Text('Next run: ${job.nextRunAt}'),
                            if (job.lastStatus != null)
                              Text('Last status: ${job.lastStatus}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (job.isPaused)
                              const Chip(
                                label: Text('Paused'),
                                visualDensity: VisualDensity.compact,
                              ),
                            PopupMenuButton<String>(
                              enabled: !actionState.busy,
                              onSelected: (action) {
                                switch (action) {
                                  case 'pause':
                                    ref
                                        .read(
                                          cronActionControllerProvider.notifier,
                                        )
                                        .pause(job.id);
                                  case 'resume':
                                    ref
                                        .read(
                                          cronActionControllerProvider.notifier,
                                        )
                                        .resume(job.id);
                                  case 'delete':
                                    _confirmDelete(
                                      context,
                                      ref,
                                      job.id,
                                      job.name,
                                    );
                                }
                              },
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<String>>[
                                    if (!job.isPaused)
                                      const PopupMenuItem<String>(
                                        value: 'pause',
                                        child: Text('Pause'),
                                      ),
                                    if (job.isPaused)
                                      const PopupMenuItem<String>(
                                        value: 'resume',
                                        child: Text('Resume'),
                                      ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
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
                  'Failed to load scheduled tasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: actionState.busy
            ? null
            : () {
                _showAddDialog(context, ref);
              },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final promptController = TextEditingController();
    final scheduleController = TextEditingController();
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add scheduled task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'Daily report',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: scheduleController,
              decoration: const InputDecoration(
                labelText: 'Schedule',
                hintText: 'every day at 9am',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Generate status report',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final prompt = promptController.text.trim();
              final schedule = scheduleController.text.trim();
              final name = nameController.text.trim();
              if (prompt.isEmpty || schedule.isEmpty) {
                return;
              }
              ref
                  .read(cronActionControllerProvider.notifier)
                  .add(
                    prompt: prompt,
                    schedule: schedule,
                    name: name.isEmpty ? null : name,
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String jobName,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scheduled task'),
        content: Text('Delete "$jobName"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cronActionControllerProvider.notifier).remove(jobId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
