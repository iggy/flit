import 'package:flit/domain/models/cron_job.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cron_dtos.g.dart';

/// Wire DTO for `cron.manage` result (action=list).
@JsonSerializable()
class CronManageResultDto {
  const CronManageResultDto({
    this.success,
    this.count,
    this.jobs = const <CronJobDto>[],
    this.error,
    this.message,
    this.jobId,
    this.removedJob,
    this.job,
  });

  factory CronManageResultDto.fromJson(Map<String, dynamic> json) =>
      _$CronManageResultDtoFromJson(json);

  @JsonKey(name: 'success')
  final bool? success;

  @JsonKey(name: 'count')
  final int? count;

  @JsonKey(name: 'jobs')
  final List<CronJobDto> jobs;

  @JsonKey(name: 'error')
  final String? error;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'job_id')
  final String? jobId;

  @JsonKey(name: 'removed_job')
  final CronJobDto? removedJob;

  @JsonKey(name: 'job')
  final CronJobDto? job;

  Map<String, dynamic> toJson() => _$CronManageResultDtoToJson(this);

  List<CronJob> toDomainList() {
    return jobs.map((dto) => dto.toDomain()).toList();
  }
}

/// One cron job entry from `cron.manage` results.
@JsonSerializable()
class CronJobDto {
  const CronJobDto({
    this.jobId,
    this.name,
    this.skills,
    this.promptPreview,
    this.model,
    this.provider,
    this.schedule,
    this.repeat,
    this.deliver,
    this.nextRunAt,
    this.lastRunAt,
    this.lastStatus,
    this.lastDeliveryError,
    this.enabled,
    this.state,
    this.pausedAt,
    this.pausedReason,
  });

  factory CronJobDto.fromJson(Map<String, dynamic> json) =>
      _$CronJobDtoFromJson(json);

  @JsonKey(name: 'job_id')
  final String? jobId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'skills')
  final List<String>? skills;

  @JsonKey(name: 'prompt_preview')
  final String? promptPreview;

  @JsonKey(name: 'model')
  final String? model;

  @JsonKey(name: 'provider')
  final String? provider;

  @JsonKey(name: 'schedule')
  final String? schedule;

  @JsonKey(name: 'repeat')
  final String? repeat;

  @JsonKey(name: 'deliver')
  final String? deliver;

  @JsonKey(name: 'next_run_at')
  final String? nextRunAt;

  @JsonKey(name: 'last_run_at')
  final String? lastRunAt;

  @JsonKey(name: 'last_status')
  final String? lastStatus;

  @JsonKey(name: 'last_delivery_error')
  final String? lastDeliveryError;

  @JsonKey(name: 'enabled')
  final bool? enabled;

  @JsonKey(name: 'state')
  final String? state;

  @JsonKey(name: 'paused_at')
  final String? pausedAt;

  @JsonKey(name: 'paused_reason')
  final String? pausedReason;

  Map<String, dynamic> toJson() => _$CronJobDtoToJson(this);

  CronJob toDomain() {
    return CronJob(
      id: jobId ?? '',
      name: name ?? '',
      skills: skills ?? const <String>[],
      promptPreview: promptPreview ?? '',
      model: model,
      provider: provider,
      schedule: schedule ?? '?',
      repeat: repeat ?? '',
      deliver: deliver ?? '',
      nextRunAt: nextRunAt,
      lastRunAt: lastRunAt,
      lastStatus: lastStatus,
      lastDeliveryError: lastDeliveryError,
      enabled: enabled ?? false,
      state: state ?? '',
      pausedAt: pausedAt,
      pausedReason: pausedReason,
    );
  }
}
