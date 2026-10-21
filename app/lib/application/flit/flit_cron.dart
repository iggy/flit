/// Cron jobs on the flit server: the job and run lists, and local
/// notifications when a run finishes with something to say.
library;

import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/application/notifications/notification_format.dart';
import 'package:flit/application/notifications/notification_providers.dart';
import 'package:flit/domain/models/flit_cron.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server's cron jobs, by name. Empty when not connected to flit.
final flitCronJobsProvider = FutureProvider<List<FlitCronJob>>((ref) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitCronJob>[];
  }
  return repository.listCronJobs();
});

/// One job's runs, newest first.
final flitCronRunsProvider = FutureProvider.family<List<FlitCronRun>, String>((
  ref,
  name,
) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitCronRun>[];
  }
  return repository.listCronRuns(name: name);
});

/// How often the app checks for finished cron runs while connected.
final flitCronPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 1),
);

/// The runs in [runs] to notify about now: finished since the app last
/// looked (not in [seen]) with a report, needing attention, or failed.
List<FlitCronRun> cronRunsToNotify(List<FlitCronRun> runs, Set<String> seen) {
  return <FlitCronRun>[
    for (final r in runs)
      if (!seen.contains(r.id) && r.finishedAt != null && r.worthNotifying) r,
  ];
}

/// The title of a run's notification.
String cronRunNotificationTitle(FlitCronRun run) => switch (run.state) {
  FlitCronRunState.needsAttention => '${run.job} needs attention',
  FlitCronRunState.failed => '${run.job} failed',
  _ => run.job,
};

/// The body of a run's notification.
String cronRunNotificationBody(FlitCronRun run) {
  final refused = run.refusedCommands.isEmpty
      ? ''
      : ' Refused: ${run.refusedCommands.join('; ')}';
  return notificationBody('${run.summary}$refused');
}

/// Polls the server's cron runs while notifications are on and posts a
/// local notification for each run that finishes with a report, needs
/// attention, or fails. Runs that finished before the first look are taken
/// as already seen. State: how many notifications it posted.
final flitCronNotifierProvider = NotifierProvider<FlitCronNotifier, int>(
  FlitCronNotifier.new,
);

class FlitCronNotifier extends Notifier<int> {
  Timer? _timer;
  Set<String>? _seen;

  @override
  int build() {
    final enabled = ref.watch(notificationsEnabledProvider);
    final repository = ref.watch(flitRepositoryProvider);
    _stop();
    ref.onDispose(_stop);
    if (!enabled || repository == null) {
      return 0;
    }
    _timer = Timer.periodic(ref.watch(flitCronPollIntervalProvider), (_) {
      unawaited(check());
    });
    unawaited(check());
    return 0;
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _seen = null;
  }

  /// Looks once. Errors (server down, old server) are ignored until the next
  /// look.
  Future<void> check() async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    final List<FlitCronRun> runs;
    try {
      runs = await repository.listCronRuns(limit: 50);
    } on Object {
      return;
    }
    if (!ref.mounted) {
      return;
    }
    final seen = _seen;
    if (seen == null) {
      _seen = <String>{
        for (final r in runs)
          if (r.finishedAt != null) r.id,
      };
      return;
    }
    final notify = cronRunsToNotify(runs, seen);
    final fresh = <String>[
      for (final r in runs)
        if (r.finishedAt != null && !seen.contains(r.id)) r.id,
    ];
    if (fresh.isEmpty) {
      return;
    }
    seen.addAll(fresh);
    // New results: the job list's last runs are stale.
    ref.invalidate(flitCronJobsProvider);
    final service = ref.read(notificationServiceProvider);
    for (final run in notify) {
      await service.show(
        id: notificationIdFor('cron:${run.id}'),
        title: cronRunNotificationTitle(run),
        body: cronRunNotificationBody(run),
      );
      state++;
    }
  }
}
