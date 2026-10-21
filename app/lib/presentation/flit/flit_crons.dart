/// Cron jobs: the side pane's Cron section (wide windows), the Crons screen
/// (phones, and the section's "all jobs"), and a job's runs. Each run opens
/// its ordinary session. Jobs are edited as files on the server or through
/// an agent's cron tool, not here.
library;

import 'package:flit/application/flit/flit_cron.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The badge on sessions that are cron runs.
const Key flitCronBadgeKey = Key('flit_cron_badge');

/// A small clock marking a session as a cron job's run.
class FlitCronBadge extends StatelessWidget {
  const FlitCronBadge({required this.job, super.key});

  final String job;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Cron run of $job',
      child: Icon(
        Icons.schedule,
        key: flitCronBadgeKey,
        size: 14,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

/// A run's state as an icon and label.
class FlitCronRunStateChip extends StatelessWidget {
  const FlitCronRunStateChip({
    required this.state,
    this.compact = false,
    super.key,
  });

  final FlitCronRunState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, color) = switch (state) {
      FlitCronRunState.running => ('Running', Icons.autorenew, scheme.primary),
      FlitCronRunState.ok => ('OK', Icons.check_circle_outline, scheme.outline),
      FlitCronRunState.needsAttention => (
        'Needs attention',
        Icons.warning_amber,
        scheme.tertiary,
      ),
      FlitCronRunState.failed => ('Failed', Icons.error_outline, scheme.error),
      FlitCronRunState.skipped => (
        'Skipped',
        Icons.skip_next_outlined,
        scheme.outline,
      ),
      FlitCronRunState.unknown => ('?', Icons.help_outline, scheme.outline),
    };
    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: 14, color: color),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// "today 08:30", "tomorrow 09:00", "Mon 21 Oct 10:00" in local time.
String flitCronTime(DateTime t, {DateTime? now}) {
  final local = t.toLocal();
  final today = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(local.hour)}:${two(local.minute)}';
  final day = DateTime(local.year, local.month, local.day);
  final diff = day.difference(DateTime(today.year, today.month, today.day));
  if (diff.inDays == 0) {
    return 'today $clock';
  }
  if (diff.inDays == 1) {
    return 'tomorrow $clock';
  }
  if (diff.inDays == -1) {
    return 'yesterday $clock';
  }
  const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${days[local.weekday - 1]} ${local.day} ${months[local.month - 1]} $clock';
}

/// The line under a job's name: its schedule and next run, or what's wrong.
String flitCronJobSubtitle(FlitCronJob j) {
  if (j.error.isNotEmpty) {
    return 'Error: ${j.error}';
  }
  final schedule = j.scheduleText.isEmpty ? j.schedule : j.scheduleText;
  if (!j.enabled) {
    return '$schedule · disabled';
  }
  if (j.isRunning) {
    return '$schedule · running now';
  }
  final next = j.nextRunAt;
  return next == null ? schedule : '$schedule · next ${flitCronTime(next)}';
}

Future<void> _runNow(BuildContext context, WidgetRef ref, String name) async {
  final repository = ref.read(flitRepositoryProvider);
  if (repository == null) {
    return;
  }
  try {
    final run = await repository.runCronJob(name);
    ref
      ..invalidate(flitCronJobsProvider)
      ..invalidate(flitCronRunsProvider(name))
      ..invalidate(flitAllSessionsProvider)
      ..invalidate(flitSessionsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started $name'),
          action: run.sessionId.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Open',
                  onPressed: () =>
                      context.push('/flit/session/${run.sessionId}'),
                ),
        ),
      );
    }
  } on GatewayException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not run $name: ${error.message}')),
      );
    }
  }
}

Future<void> _setEnabled(
  BuildContext context,
  WidgetRef ref,
  String name, {
  required bool enabled,
}) async {
  final repository = ref.read(flitRepositoryProvider);
  if (repository == null) {
    return;
  }
  try {
    await repository.setCronJobEnabled(name, enabled: enabled);
    ref.invalidate(flitCronJobsProvider);
  } on GatewayException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change $name: ${error.message}')),
      );
    }
  }
}

/// The side pane's Cron section: each job with its schedule and last run.
/// Hidden when the server has no jobs (or predates cron jobs).
class FlitCronSection extends ConsumerWidget {
  const FlitCronSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(flitCronJobsProvider).value ?? const <FlitCronJob>[];
    if (jobs.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      key: const PageStorageKey<String>('flit_nav_cron'),
      leading: const Icon(Icons.schedule),
      title: GestureDetector(
        onTap: () => context.go('/flit/crons'),
        child: const Text('Cron'),
      ),
      children: <Widget>[
        for (final j in jobs)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 32, right: 12),
            title: Text(j.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              flitCronJobSubtitle(j),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: j.error.isNotEmpty
                ? Icon(
                    Icons.error_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  )
                : j.lastRun == null
                ? null
                : FlitCronRunStateChip(state: j.lastRun!.state, compact: true),
            onTap: () =>
                context.go('/flit/crons/${Uri.encodeComponent(j.name)}'),
          ),
      ],
    );
  }
}

/// Every cron job, with Run now and an enable switch.
class FlitCronsScreen extends ConsumerWidget {
  const FlitCronsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(flitCronJobsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cron jobs'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(flitCronJobsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(flitCronJobsProvider.future),
        child: jobs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load cron jobs: '
                  '${error is GatewayException ? error.message : error}',
                ),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No cron jobs yet. Ask an agent to schedule one '
                        '("every weekday at 8:30, check CI"), or add a .md '
                        "file to the server's crons directory.",
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _JobTile(job: list[i]),
                ),
        ),
      ),
    );
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.job});

  final FlitCronJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = job.lastRun;
    return ListTile(
      title: Text(job.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(flitCronJobSubtitle(job)),
          if (last != null)
            Row(
              children: <Widget>[
                FlitCronRunStateChip(state: last.state, compact: true),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    last.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
      isThreeLine: last != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: 'Run now',
            onPressed: job.error.isNotEmpty || job.isRunning
                ? null
                : () => _runNow(context, ref, job.name),
            icon: const Icon(Icons.play_arrow),
          ),
          Switch(
            value: job.enabled,
            onChanged: job.error.isNotEmpty
                ? null
                : (on) => _setEnabled(context, ref, job.name, enabled: on),
          ),
        ],
      ),
      onTap: () => context.push('/flit/crons/${Uri.encodeComponent(job.name)}'),
    );
  }
}

/// One job: what it does, and its runs, newest first.
class FlitCronJobScreen extends ConsumerWidget {
  const FlitCronJobScreen({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlitCronJob? job;
    for (final j
        in ref.watch(flitCronJobsProvider).value ?? const <FlitCronJob>[]) {
      if (j.name == name) {
        job = j;
      }
    }
    final runs = ref.watch(flitCronRunsProvider(name));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Run now',
            onPressed: job == null || job.error.isNotEmpty || job.isRunning
                ? null
                : () => _runNow(context, ref, name),
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref
              ..invalidate(flitCronJobsProvider)
              ..invalidate(flitCronRunsProvider(name)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(flitCronJobsProvider);
          return ref.refresh(flitCronRunsProvider(name).future);
        },
        child: ListView(
          children: <Widget>[
            if (job != null) ...<Widget>[
              SwitchListTile(
                title: Text(flitCronJobSubtitle(job)),
                subtitle: Text(
                  <String>[
                    'Project: ${job.projectName.isEmpty ? '?' : job.projectName}',
                    if (job.dir.isNotEmpty) job.dir,
                    if (job.role.isNotEmpty) 'Role: ${job.role}',
                    if (job.model.isNotEmpty) '${job.provider} / ${job.model}',
                    if (job.askWait) 'Prompts wait' else 'Prompts refused',
                    if (job.yolo) 'Yolo',
                  ].join(' · '),
                ),
                value: job.enabled,
                onChanged: job.error.isNotEmpty
                    ? null
                    : (on) => _setEnabled(context, ref, name, enabled: on),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  job.prompt,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const Divider(height: 1),
            ],
            ...runs.when(
              loading: () => const <Widget>[
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => <Widget>[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load runs: '
                    '${error is GatewayException ? error.message : error}',
                  ),
                ),
              ],
              data: (list) => list.isEmpty
                  ? const <Widget>[
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No runs yet.'),
                      ),
                    ]
                  : <Widget>[for (final r in list) _RunTile(run: r)],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({required this.run});

  final FlitCronRun run;

  @override
  Widget build(BuildContext context) {
    final started = run.startedAt;
    final trigger = switch (run.trigger) {
      FlitCronTrigger.catchUp => ' · caught up',
      FlitCronTrigger.manual => ' · run by hand',
      _ => '',
    };
    return ListTile(
      leading: FlitCronRunStateChip(state: run.state, compact: true),
      title: Text(
        run.summary.isEmpty ? '(no report yet)' : run.summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        <String>[
          '${started == null ? '' : flitCronTime(started)}$trigger',
          if (run.refusedCommands.isNotEmpty)
            'Refused: ${run.refusedCommands.join('; ')}',
        ].join('\n'),
      ),
      enabled: run.sessionId.isNotEmpty,
      onTap: run.sessionId.isEmpty
          ? null
          : () => context.push('/flit/session/${run.sessionId}'),
    );
  }
}
