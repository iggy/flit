//
//  Generated code. Do not modify.
//  source: flit/v1/cron.proto
//

import "package:connectrpc/connect.dart" as connect;
import "cron.pb.dart" as flitv1cron;

/// CronService lists and runs cron jobs. A cron job is a prompt flit runs
/// on a schedule, unattended, each run as a new session in the job's
/// project. Jobs are Markdown files with YAML frontmatter in the server's
/// crons directory (see docs/cron.md); edit them there or ask an agent (the
/// cron tool).
abstract final class CronService {
  /// Fully-qualified name of the CronService service.
  static const name = 'flit.v1.CronService';

  static const listCronJobs = connect.Spec(
    '/$name/ListCronJobs',
    connect.StreamType.unary,
    flitv1cron.ListCronJobsRequest.new,
    flitv1cron.ListCronJobsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  static const getCronJob = connect.Spec(
    '/$name/GetCronJob',
    connect.StreamType.unary,
    flitv1cron.GetCronJobRequest.new,
    flitv1cron.GetCronJobResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// RunCronJob starts a run now, whatever the schedule and even if the job
  /// is disabled. Fails with FAILED_PRECONDITION while a run of the job is
  /// going.
  static const runCronJob = connect.Spec(
    '/$name/RunCronJob',
    connect.StreamType.unary,
    flitv1cron.RunCronJobRequest.new,
    flitv1cron.RunCronJobResponse.new,
  );

  /// SetCronJobEnabled turns a job's schedule on or off (it rewrites
  /// enabled: in the job file).
  static const setCronJobEnabled = connect.Spec(
    '/$name/SetCronJobEnabled',
    connect.StreamType.unary,
    flitv1cron.SetCronJobEnabledRequest.new,
    flitv1cron.SetCronJobEnabledResponse.new,
  );

  /// ListCronRuns lists a job's runs, newest first.
  static const listCronRuns = connect.Spec(
    '/$name/ListCronRuns',
    connect.StreamType.unary,
    flitv1cron.ListCronRunsRequest.new,
    flitv1cron.ListCronRunsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );
}
