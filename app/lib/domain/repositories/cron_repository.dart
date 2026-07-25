import 'package:flit/domain/models/cron_job.dart';

/// Cron job management operations (ticket P5-01).
///
/// Methods follow the wire protocol exactly: `cron.manage` with different
/// action parameters ("list", "add", "remove", "pause", "resume").
abstract interface class CronRepository {
  /// `cron.manage` with action=list — list all cron jobs.
  ///
  /// Throws [GatewayRpcException] when the result has `success: false`.
  Future<List<CronJob>> list();

  /// `cron.manage` with action=add — create a new cron job.
  ///
  /// The [name] is an optional display name for the job.
  /// Throws [GatewayRpcException] when the result has `success: false`.
  Future<void> add({
    required String prompt,
    required String schedule,
    String? name,
  });

  /// `cron.manage` with action=remove — remove a cron job by id.
  ///
  /// Throws [GatewayRpcException] when the result has `success: false`.
  Future<void> remove(String jobId);

  /// `cron.manage` with action=pause — pause a cron job by id.
  ///
  /// Throws [GatewayRpcException] when the result has `success: false`.
  Future<void> pause(String jobId);

  /// `cron.manage` with action=resume — resume a paused cron job by id.
  ///
  /// Throws [GatewayRpcException] when the result has `success: false`.
  Future<void> resume(String jobId);
}
