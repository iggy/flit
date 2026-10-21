//
//  Generated code. Do not modify.
//  source: flit/v1/cron.proto
//

import "package:connectrpc/connect.dart" as connect;
import "cron.pb.dart" as flitv1cron;
import "cron.connect.spec.dart" as specs;

/// CronService lists and runs cron jobs. A cron job is a prompt flit runs
/// on a schedule, unattended, each run as a new session in the job's
/// project. Jobs are Markdown files with YAML frontmatter in the server's
/// crons directory (see docs/cron.md); edit them there or ask an agent (the
/// cron tool).
extension type CronServiceClient (connect.Transport _transport) {
  Future<flitv1cron.ListCronJobsResponse> listCronJobs(
    flitv1cron.ListCronJobsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.CronService.listCronJobs,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<flitv1cron.GetCronJobResponse> getCronJob(
    flitv1cron.GetCronJobRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.CronService.getCronJob,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// RunCronJob starts a run now, whatever the schedule and even if the job
  /// is disabled. Fails with FAILED_PRECONDITION while a run of the job is
  /// going.
  Future<flitv1cron.RunCronJobResponse> runCronJob(
    flitv1cron.RunCronJobRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.CronService.runCronJob,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetCronJobEnabled turns a job's schedule on or off (it rewrites
  /// enabled: in the job file).
  Future<flitv1cron.SetCronJobEnabledResponse> setCronJobEnabled(
    flitv1cron.SetCronJobEnabledRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.CronService.setCronJobEnabled,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// ListCronRuns lists a job's runs, newest first.
  Future<flitv1cron.ListCronRunsResponse> listCronRuns(
    flitv1cron.ListCronRunsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.CronService.listCronRuns,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
