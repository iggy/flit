// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cron_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CronManageResultDto _$CronManageResultDtoFromJson(Map<String, dynamic> json) =>
    CronManageResultDto(
      success: json['success'] as bool?,
      count: (json['count'] as num?)?.toInt(),
      jobs:
          (json['jobs'] as List<dynamic>?)
              ?.map((e) => CronJobDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CronJobDto>[],
      error: json['error'] as String?,
      message: json['message'] as String?,
      jobId: json['job_id'] as String?,
      removedJob: json['removed_job'] == null
          ? null
          : CronJobDto.fromJson(json['removed_job'] as Map<String, dynamic>),
      job: json['job'] == null
          ? null
          : CronJobDto.fromJson(json['job'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CronManageResultDtoToJson(
  CronManageResultDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'count': instance.count,
  'jobs': instance.jobs,
  'error': instance.error,
  'message': instance.message,
  'job_id': instance.jobId,
  'removed_job': instance.removedJob,
  'job': instance.job,
};

CronJobDto _$CronJobDtoFromJson(Map<String, dynamic> json) => CronJobDto(
  jobId: json['job_id'] as String?,
  name: json['name'] as String?,
  skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
  promptPreview: json['prompt_preview'] as String?,
  model: json['model'] as String?,
  provider: json['provider'] as String?,
  schedule: json['schedule'] as String?,
  repeat: json['repeat'] as String?,
  deliver: json['deliver'] as String?,
  nextRunAt: json['next_run_at'] as String?,
  lastRunAt: json['last_run_at'] as String?,
  lastStatus: json['last_status'] as String?,
  lastDeliveryError: json['last_delivery_error'] as String?,
  enabled: json['enabled'] as bool?,
  state: json['state'] as String?,
  pausedAt: json['paused_at'] as String?,
  pausedReason: json['paused_reason'] as String?,
);

Map<String, dynamic> _$CronJobDtoToJson(CronJobDto instance) =>
    <String, dynamic>{
      'job_id': instance.jobId,
      'name': instance.name,
      'skills': instance.skills,
      'prompt_preview': instance.promptPreview,
      'model': instance.model,
      'provider': instance.provider,
      'schedule': instance.schedule,
      'repeat': instance.repeat,
      'deliver': instance.deliver,
      'next_run_at': instance.nextRunAt,
      'last_run_at': instance.lastRunAt,
      'last_status': instance.lastStatus,
      'last_delivery_error': instance.lastDeliveryError,
      'enabled': instance.enabled,
      'state': instance.state,
      'paused_at': instance.pausedAt,
      'paused_reason': instance.pausedReason,
    };
