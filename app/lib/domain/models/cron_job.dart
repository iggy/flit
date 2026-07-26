/// Domain model for cron jobs (ticket P5-01).
///
/// Wire shapes from gateway protocol (cron.manage method).
library;

import 'package:flit/domain/models/deep_equals.dart';

/// One cron job entry from `cron.manage` action=list.
final class CronJob {
  const CronJob({
    required this.id,
    required this.name,
    required this.skills,
    required this.promptPreview,
    this.model,
    this.provider,
    required this.schedule,
    required this.repeat,
    required this.deliver,
    this.nextRunAt,
    this.lastRunAt,
    this.lastStatus,
    this.lastDeliveryError,
    required this.enabled,
    required this.state,
    this.pausedAt,
    this.pausedReason,
  });

  /// Wire `job_id` — THE job identifier (NOT `id`).
  final String id;

  /// Wire `name` — display name.
  final String name;

  /// Wire `skills` — list of skill names.
  final List<String> skills;

  /// Wire `prompt_preview` — already truncated prompt preview.
  final String promptPreview;

  /// Wire `model` — optional model name.
  final String? model;

  /// Wire `provider` — optional provider name.
  final String? provider;

  /// Wire `schedule` — human-readable schedule (fallback "?" if unknown).
  final String schedule;

  /// Wire `repeat` — repeat mode.
  final String repeat;

  /// Wire `deliver` — delivery mode.
  final String deliver;

  /// Wire `next_run_at` — optional next run timestamp.
  final String? nextRunAt;

  /// Wire `last_run_at` — optional last run timestamp.
  final String? lastRunAt;

  /// Wire `last_status` — optional last run status.
  final String? lastStatus;

  /// Wire `last_delivery_error` — optional last delivery error.
  final String? lastDeliveryError;

  /// Wire `enabled` — whether this job is enabled.
  final bool enabled;

  /// Wire `state` — job state (e.g. "scheduled"/"paused").
  final String state;

  /// Wire `paused_at` — optional paused timestamp.
  final String? pausedAt;

  /// Wire `paused_reason` — optional paused reason.
  final String? pausedReason;

  /// A job is paused when `state == "paused"` OR `enabled == false`.
  /// There is NO boolean `paused` field on the wire.
  bool get isPaused => state == 'paused' || !enabled;

  @override
  bool operator ==(Object other) {
    return other is CronJob &&
        other.id == id &&
        other.name == name &&
        deepListEquals(other.skills, skills) &&
        other.promptPreview == promptPreview &&
        other.model == model &&
        other.provider == provider &&
        other.schedule == schedule &&
        other.repeat == repeat &&
        other.deliver == deliver &&
        other.nextRunAt == nextRunAt &&
        other.lastRunAt == lastRunAt &&
        other.lastStatus == lastStatus &&
        other.lastDeliveryError == lastDeliveryError &&
        other.enabled == enabled &&
        other.state == state &&
        other.pausedAt == pausedAt &&
        other.pausedReason == pausedReason;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAll(skills),
    promptPreview,
    model,
    provider,
    schedule,
    repeat,
    deliver,
    nextRunAt,
    lastRunAt,
    lastStatus,
    lastDeliveryError,
    enabled,
    state,
    pausedAt,
    pausedReason,
  );

  @override
  String toString() {
    return 'CronJob(id: $id, name: $name, skills: $skills, '
        'promptPreview: $promptPreview, model: $model, provider: $provider, '
        'schedule: $schedule, repeat: $repeat, deliver: $deliver, '
        'nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, '
        'lastStatus: $lastStatus, lastDeliveryError: $lastDeliveryError, '
        'enabled: $enabled, state: $state, pausedAt: $pausedAt, '
        'pausedReason: $pausedReason)';
  }
}
