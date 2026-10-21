/// Cron jobs on a flit server (flit.v1 `CronService`): prompts the server
/// runs on a schedule, unattended, each run as a new session.
library;

/// How a cron run ended (flit.v1 `CronRunState`).
enum FlitCronRunState {
  running,

  /// Finished; the summary is the report's first line.
  ok,

  /// Finished, but something it wanted to do was refused.
  needsAttention,

  /// Could not start, or its turn ended in an error.
  failed,

  /// Not run: the previous run was still going.
  skipped,

  unknown,
}

/// What started a run (flit.v1 `CronTrigger`).
enum FlitCronTrigger { schedule, catchUp, manual, unknown }

/// One run of a cron job.
final class FlitCronRun {
  const FlitCronRun({
    required this.id,
    required this.job,
    required this.state,
    this.sessionId = '',
    this.trigger = FlitCronTrigger.unknown,
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    this.summary = '',
    this.refusedCommands = const <String>[],
    this.quiet = false,
  });

  final String id;
  final String job;

  /// The run's session; empty for skipped runs and runs that never started.
  final String sessionId;
  final FlitCronRunState state;
  final FlitCronTrigger trigger;
  final DateTime? scheduledAt;
  final DateTime? startedAt;

  /// Null while running.
  final DateTime? finishedAt;

  /// The report's first line, or why it failed or was skipped.
  final String summary;

  /// Commands refused because nobody could approve them.
  final List<String> refusedCommands;

  /// The report was "nothing to report".
  final bool quiet;

  /// Whether this run is worth a notification: finished with a report,
  /// needs attention, or failed.
  bool get worthNotifying => switch (state) {
    FlitCronRunState.ok => !quiet,
    FlitCronRunState.needsAttention || FlitCronRunState.failed => true,
    _ => false,
  };
}

/// A cron job (one job file on the server).
final class FlitCronJob {
  const FlitCronJob({
    required this.name,
    required this.schedule,
    this.scheduleText = '',
    this.oneShot = false,
    this.enabled = true,
    this.projectId = '',
    this.projectName = '',
    this.dir = '',
    this.role = '',
    this.provider = '',
    this.model = '',
    this.askWait = false,
    this.yolo = false,
    this.timezone = '',
    this.prompt = '',
    this.path = '',
    this.nextRunAt,
    this.lastRun,
    this.error = '',
    this.runningSessionId = '',
  });

  /// The file name without .md.
  final String name;

  /// As written, e.g. "weekdays at 8:30".
  final String schedule;

  /// In words, e.g. "weekdays at 08:30".
  final String scheduleText;
  final bool oneShot;
  final bool enabled;
  final String projectId;
  final String projectName;
  final String dir;
  final String role;
  final String provider;
  final String model;

  /// Prompts nobody answers wait (true) or are refused at once (false).
  final bool askWait;
  final bool yolo;
  final String timezone;
  final String prompt;

  /// The job file on the server.
  final String path;

  /// Null when disabled, broken or done.
  final DateTime? nextRunAt;
  final FlitCronRun? lastRun;

  /// Why the file can't be used; such a job never runs.
  final String error;

  /// Set while a run is going.
  final String runningSessionId;

  bool get isRunning => runningSessionId.isNotEmpty;
}
