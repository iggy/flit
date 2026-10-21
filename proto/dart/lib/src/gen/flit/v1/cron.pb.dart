// This is a generated file - do not edit.
//
// Generated from flit/v1/cron.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'cron.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'cron.pbenum.dart';

class CronJob extends $pb.GeneratedMessage {
  factory CronJob({
    $core.String? name,
    $core.String? schedule,
    $core.String? scheduleText,
    $core.bool? oneShot,
    $core.bool? enabled,
    $core.String? projectId,
    $core.String? projectName,
    $core.String? dir,
    $core.String? role,
    $core.String? provider,
    $core.String? model,
    $core.String? effort,
    CronAsk? ask,
    $fixnum.Int64? askTimeoutSeconds,
    $core.bool? yolo,
    $core.String? timezone,
    $core.String? prompt,
    $core.String? path,
    $0.Timestamp? nextRunTime,
    CronRun? lastRun,
    $core.String? error,
    $core.String? runningSessionId,
  }) {
    final result = CronJob._();
    if (name != null) result.name = name;
    if (schedule != null) result.schedule = schedule;
    if (scheduleText != null) result.scheduleText = scheduleText;
    if (oneShot != null) result.oneShot = oneShot;
    if (enabled != null) result.enabled = enabled;
    if (projectId != null) result.projectId = projectId;
    if (projectName != null) result.projectName = projectName;
    if (dir != null) result.dir = dir;
    if (role != null) result.role = role;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (effort != null) result.effort = effort;
    if (ask != null) result.ask = ask;
    if (askTimeoutSeconds != null) result.askTimeoutSeconds = askTimeoutSeconds;
    if (yolo != null) result.yolo = yolo;
    if (timezone != null) result.timezone = timezone;
    if (prompt != null) result.prompt = prompt;
    if (path != null) result.path = path;
    if (nextRunTime != null) result.nextRunTime = nextRunTime;
    if (lastRun != null) result.lastRun = lastRun;
    if (error != null) result.error = error;
    if (runningSessionId != null) result.runningSessionId = runningSessionId;
    return result;
  }

  CronJob._();

  factory CronJob.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CronJob()..mergeFromBuffer(data, registry);
  factory CronJob.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CronJob()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CronJob',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CronJob.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'schedule')
    ..aOS(3, _omitFieldNames ? '' : 'scheduleText')
    ..aOB(4, _omitFieldNames ? '' : 'oneShot')
    ..aOB(5, _omitFieldNames ? '' : 'enabled')
    ..aOS(6, _omitFieldNames ? '' : 'projectId')
    ..aOS(7, _omitFieldNames ? '' : 'projectName')
    ..aOS(8, _omitFieldNames ? '' : 'dir')
    ..aOS(9, _omitFieldNames ? '' : 'role')
    ..aOS(10, _omitFieldNames ? '' : 'provider')
    ..aOS(11, _omitFieldNames ? '' : 'model')
    ..aOS(12, _omitFieldNames ? '' : 'effort')
    ..aE<CronAsk>(13, _omitFieldNames ? '' : 'ask', enumValues: CronAsk.values)
    ..aInt64(14, _omitFieldNames ? '' : 'askTimeoutSeconds')
    ..aOB(15, _omitFieldNames ? '' : 'yolo')
    ..aOS(16, _omitFieldNames ? '' : 'timezone')
    ..aOS(17, _omitFieldNames ? '' : 'prompt')
    ..aOS(18, _omitFieldNames ? '' : 'path')
    ..aOM<$0.Timestamp>(19, _omitFieldNames ? '' : 'nextRunTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<CronRun>(20, _omitFieldNames ? '' : 'lastRun',
        subBuilder: CronRun.$_createMessage)
    ..aOS(21, _omitFieldNames ? '' : 'error')
    ..aOS(22, _omitFieldNames ? '' : 'runningSessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CronJob clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CronJob copyWith(void Function(CronJob) updates) =>
      super.copyWith((message) => updates(message as CronJob)) as CronJob;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CronJob() / CronJob.new instead')
  static CronJob create() => CronJob._();
  static $pb.GeneratedMessage $_createMessage() => CronJob._();
  @$core.override
  CronJob createEmptyInstance() => CronJob._();
  @$core.pragma('dart2js:noInline')
  static CronJob getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CronJob>(CronJob.$_createMessage);
  static CronJob? _defaultInstance;

  /// The job file's name without .md.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// The schedule as written, e.g. "weekdays at 8:30" or "0 8 * * 1-5".
  @$pb.TagNumber(2)
  $core.String get schedule => $_getSZ(1);
  @$pb.TagNumber(2)
  set schedule($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchedule() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchedule() => $_clearField(2);

  /// The schedule in words, e.g. "weekdays at 08:30".
  @$pb.TagNumber(3)
  $core.String get scheduleText => $_getSZ(2);
  @$pb.TagNumber(3)
  set scheduleText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasScheduleText() => $_has(2);
  @$pb.TagNumber(3)
  void clearScheduleText() => $_clearField(3);

  /// Whether it runs once (in ..., at ...).
  @$pb.TagNumber(4)
  $core.bool get oneShot => $_getBF(3);
  @$pb.TagNumber(4)
  set oneShot($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOneShot() => $_has(3);
  @$pb.TagNumber(4)
  void clearOneShot() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enabled => $_getBF(4);
  @$pb.TagNumber(5)
  set enabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnabled() => $_clearField(5);

  /// The project runs go to, as resolved; empty if it can't be.
  @$pb.TagNumber(6)
  $core.String get projectId => $_getSZ(5);
  @$pb.TagNumber(6)
  set projectId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProjectId() => $_has(5);
  @$pb.TagNumber(6)
  void clearProjectId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get projectName => $_getSZ(6);
  @$pb.TagNumber(7)
  set projectName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProjectName() => $_has(6);
  @$pb.TagNumber(7)
  void clearProjectName() => $_clearField(7);

  /// The working directory runs use; empty means the project's.
  @$pb.TagNumber(8)
  $core.String get dir => $_getSZ(7);
  @$pb.TagNumber(8)
  set dir($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDir() => $_has(7);
  @$pb.TagNumber(8)
  void clearDir() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get role => $_getSZ(8);
  @$pb.TagNumber(9)
  set role($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRole() => $_has(8);
  @$pb.TagNumber(9)
  void clearRole() => $_clearField(9);

  /// The job's own model; empty means the role's, agent.tasks.cron or the
  /// chat default.
  @$pb.TagNumber(10)
  $core.String get provider => $_getSZ(9);
  @$pb.TagNumber(10)
  set provider($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasProvider() => $_has(9);
  @$pb.TagNumber(10)
  void clearProvider() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get model => $_getSZ(10);
  @$pb.TagNumber(11)
  set model($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModel() => $_has(10);
  @$pb.TagNumber(11)
  void clearModel() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get effort => $_getSZ(11);
  @$pb.TagNumber(12)
  set effort($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasEffort() => $_has(11);
  @$pb.TagNumber(12)
  void clearEffort() => $_clearField(12);

  @$pb.TagNumber(13)
  CronAsk get ask => $_getN(12);
  @$pb.TagNumber(13)
  set ask(CronAsk value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasAsk() => $_has(12);
  @$pb.TagNumber(13)
  void clearAsk() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get askTimeoutSeconds => $_getI64(13);
  @$pb.TagNumber(14)
  set askTimeoutSeconds($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasAskTimeoutSeconds() => $_has(13);
  @$pb.TagNumber(14)
  void clearAskTimeoutSeconds() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get yolo => $_getBF(14);
  @$pb.TagNumber(15)
  set yolo($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasYolo() => $_has(14);
  @$pb.TagNumber(15)
  void clearYolo() => $_clearField(15);

  /// IANA zone the schedule is read in.
  @$pb.TagNumber(16)
  $core.String get timezone => $_getSZ(15);
  @$pb.TagNumber(16)
  set timezone($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasTimezone() => $_has(15);
  @$pb.TagNumber(16)
  void clearTimezone() => $_clearField(16);

  /// The prompt (the file's body).
  @$pb.TagNumber(17)
  $core.String get prompt => $_getSZ(16);
  @$pb.TagNumber(17)
  set prompt($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasPrompt() => $_has(16);
  @$pb.TagNumber(17)
  void clearPrompt() => $_clearField(17);

  /// The job file on the server.
  @$pb.TagNumber(18)
  $core.String get path => $_getSZ(17);
  @$pb.TagNumber(18)
  set path($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasPath() => $_has(17);
  @$pb.TagNumber(18)
  void clearPath() => $_clearField(18);

  /// When it runs next; unset when disabled, broken or done.
  @$pb.TagNumber(19)
  $0.Timestamp get nextRunTime => $_getN(18);
  @$pb.TagNumber(19)
  set nextRunTime($0.Timestamp value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasNextRunTime() => $_has(18);
  @$pb.TagNumber(19)
  void clearNextRunTime() => $_clearField(19);
  @$pb.TagNumber(19)
  $0.Timestamp ensureNextRunTime() => $_ensure(18);

  /// The latest run, if any.
  @$pb.TagNumber(20)
  CronRun get lastRun => $_getN(19);
  @$pb.TagNumber(20)
  set lastRun(CronRun value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasLastRun() => $_has(19);
  @$pb.TagNumber(20)
  void clearLastRun() => $_clearField(20);
  @$pb.TagNumber(20)
  CronRun ensureLastRun() => $_ensure(19);

  /// Why the file can't be used, if it can't; such a job never runs.
  @$pb.TagNumber(21)
  $core.String get error => $_getSZ(20);
  @$pb.TagNumber(21)
  set error($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasError() => $_has(20);
  @$pb.TagNumber(21)
  void clearError() => $_clearField(21);

  /// Set while a run is going: its session.
  @$pb.TagNumber(22)
  $core.String get runningSessionId => $_getSZ(21);
  @$pb.TagNumber(22)
  set runningSessionId($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasRunningSessionId() => $_has(21);
  @$pb.TagNumber(22)
  void clearRunningSessionId() => $_clearField(22);
}

class CronRun extends $pb.GeneratedMessage {
  factory CronRun({
    $core.String? id,
    $core.String? job,
    $core.String? sessionId,
    CronRunState? state,
    CronTrigger? trigger,
    $0.Timestamp? scheduledTime,
    $0.Timestamp? startTime,
    $0.Timestamp? finishTime,
    $core.String? summary,
    $core.Iterable<$core.String>? refusedCommands,
    $core.bool? quiet,
  }) {
    final result = CronRun._();
    if (id != null) result.id = id;
    if (job != null) result.job = job;
    if (sessionId != null) result.sessionId = sessionId;
    if (state != null) result.state = state;
    if (trigger != null) result.trigger = trigger;
    if (scheduledTime != null) result.scheduledTime = scheduledTime;
    if (startTime != null) result.startTime = startTime;
    if (finishTime != null) result.finishTime = finishTime;
    if (summary != null) result.summary = summary;
    if (refusedCommands != null) result.refusedCommands.addAll(refusedCommands);
    if (quiet != null) result.quiet = quiet;
    return result;
  }

  CronRun._();

  factory CronRun.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CronRun()..mergeFromBuffer(data, registry);
  factory CronRun.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CronRun()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CronRun',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CronRun.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'job')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aE<CronRunState>(4, _omitFieldNames ? '' : 'state',
        enumValues: CronRunState.values)
    ..aE<CronTrigger>(5, _omitFieldNames ? '' : 'trigger',
        enumValues: CronTrigger.values)
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'scheduledTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'startTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(8, _omitFieldNames ? '' : 'finishTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(9, _omitFieldNames ? '' : 'summary')
    ..pPS(10, _omitFieldNames ? '' : 'refusedCommands')
    ..aOB(11, _omitFieldNames ? '' : 'quiet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CronRun clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CronRun copyWith(void Function(CronRun) updates) =>
      super.copyWith((message) => updates(message as CronRun)) as CronRun;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CronRun() / CronRun.new instead')
  static CronRun create() => CronRun._();
  static $pb.GeneratedMessage $_createMessage() => CronRun._();
  @$core.override
  CronRun createEmptyInstance() => CronRun._();
  @$core.pragma('dart2js:noInline')
  static CronRun getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CronRun>(CronRun.$_createMessage);
  static CronRun? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get job => $_getSZ(1);
  @$pb.TagNumber(2)
  set job($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasJob() => $_has(1);
  @$pb.TagNumber(2)
  void clearJob() => $_clearField(2);

  /// The run's session; empty for skipped runs and runs that failed to
  /// start.
  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  CronRunState get state => $_getN(3);
  @$pb.TagNumber(4)
  set state(CronRunState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  @$pb.TagNumber(5)
  CronTrigger get trigger => $_getN(4);
  @$pb.TagNumber(5)
  set trigger(CronTrigger value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTrigger() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrigger() => $_clearField(5);

  /// The slot it ran for (the request time for manual runs).
  @$pb.TagNumber(6)
  $0.Timestamp get scheduledTime => $_getN(5);
  @$pb.TagNumber(6)
  set scheduledTime($0.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasScheduledTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearScheduledTime() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureScheduledTime() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.Timestamp get startTime => $_getN(6);
  @$pb.TagNumber(7)
  set startTime($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasStartTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearStartTime() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureStartTime() => $_ensure(6);

  /// Unset while running.
  @$pb.TagNumber(8)
  $0.Timestamp get finishTime => $_getN(7);
  @$pb.TagNumber(8)
  set finishTime($0.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFinishTime() => $_has(7);
  @$pb.TagNumber(8)
  void clearFinishTime() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Timestamp ensureFinishTime() => $_ensure(7);

  /// The first line of the final reply, or why it failed or was skipped.
  @$pb.TagNumber(9)
  $core.String get summary => $_getSZ(8);
  @$pb.TagNumber(9)
  set summary($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSummary() => $_has(8);
  @$pb.TagNumber(9)
  void clearSummary() => $_clearField(9);

  /// Commands that were refused because nobody could approve them.
  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get refusedCommands => $_getList(9);

  /// Whether the report was "nothing to report".
  @$pb.TagNumber(11)
  $core.bool get quiet => $_getBF(10);
  @$pb.TagNumber(11)
  set quiet($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasQuiet() => $_has(10);
  @$pb.TagNumber(11)
  void clearQuiet() => $_clearField(11);
}

class ListCronJobsRequest extends $pb.GeneratedMessage {
  factory ListCronJobsRequest() => ListCronJobsRequest._();

  ListCronJobsRequest._();

  factory ListCronJobsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronJobsRequest()..mergeFromBuffer(data, registry);
  factory ListCronJobsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronJobsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListCronJobsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListCronJobsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronJobsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronJobsRequest copyWith(void Function(ListCronJobsRequest) updates) =>
      super.copyWith((message) => updates(message as ListCronJobsRequest))
          as ListCronJobsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListCronJobsRequest() / ListCronJobsRequest.new instead')
  static ListCronJobsRequest create() => ListCronJobsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListCronJobsRequest._();
  @$core.override
  ListCronJobsRequest createEmptyInstance() => ListCronJobsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListCronJobsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCronJobsRequest>(
          ListCronJobsRequest.$_createMessage);
  static ListCronJobsRequest? _defaultInstance;
}

class ListCronJobsResponse extends $pb.GeneratedMessage {
  factory ListCronJobsResponse({
    $core.Iterable<CronJob>? jobs,
    $core.String? dir,
  }) {
    final result = ListCronJobsResponse._();
    if (jobs != null) result.jobs.addAll(jobs);
    if (dir != null) result.dir = dir;
    return result;
  }

  ListCronJobsResponse._();

  factory ListCronJobsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronJobsResponse()..mergeFromBuffer(data, registry);
  factory ListCronJobsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronJobsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListCronJobsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListCronJobsResponse.$_createMessage)
    ..pPM<CronJob>(1, _omitFieldNames ? '' : 'jobs',
        subBuilder: CronJob.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'dir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronJobsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronJobsResponse copyWith(void Function(ListCronJobsResponse) updates) =>
      super.copyWith((message) => updates(message as ListCronJobsResponse))
          as ListCronJobsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListCronJobsResponse() / ListCronJobsResponse.new instead')
  static ListCronJobsResponse create() => ListCronJobsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListCronJobsResponse._();
  @$core.override
  ListCronJobsResponse createEmptyInstance() => ListCronJobsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListCronJobsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCronJobsResponse>(
          ListCronJobsResponse.$_createMessage);
  static ListCronJobsResponse? _defaultInstance;

  /// By name.
  @$pb.TagNumber(1)
  $pb.PbList<CronJob> get jobs => $_getList(0);

  /// The crons directory on the server.
  @$pb.TagNumber(2)
  $core.String get dir => $_getSZ(1);
  @$pb.TagNumber(2)
  set dir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);
}

class GetCronJobRequest extends $pb.GeneratedMessage {
  factory GetCronJobRequest({
    $core.String? name,
  }) {
    final result = GetCronJobRequest._();
    if (name != null) result.name = name;
    return result;
  }

  GetCronJobRequest._();

  factory GetCronJobRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCronJobRequest()..mergeFromBuffer(data, registry);
  factory GetCronJobRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCronJobRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCronJobRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GetCronJobRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCronJobRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCronJobRequest copyWith(void Function(GetCronJobRequest) updates) =>
      super.copyWith((message) => updates(message as GetCronJobRequest))
          as GetCronJobRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetCronJobRequest() / GetCronJobRequest.new instead')
  static GetCronJobRequest create() => GetCronJobRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetCronJobRequest._();
  @$core.override
  GetCronJobRequest createEmptyInstance() => GetCronJobRequest._();
  @$core.pragma('dart2js:noInline')
  static GetCronJobRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetCronJobRequest>(
          GetCronJobRequest.$_createMessage);
  static GetCronJobRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class GetCronJobResponse extends $pb.GeneratedMessage {
  factory GetCronJobResponse({
    CronJob? job,
  }) {
    final result = GetCronJobResponse._();
    if (job != null) result.job = job;
    return result;
  }

  GetCronJobResponse._();

  factory GetCronJobResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCronJobResponse()..mergeFromBuffer(data, registry);
  factory GetCronJobResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCronJobResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCronJobResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GetCronJobResponse.$_createMessage)
    ..aOM<CronJob>(1, _omitFieldNames ? '' : 'job',
        subBuilder: CronJob.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCronJobResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCronJobResponse copyWith(void Function(GetCronJobResponse) updates) =>
      super.copyWith((message) => updates(message as GetCronJobResponse))
          as GetCronJobResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetCronJobResponse() / GetCronJobResponse.new instead')
  static GetCronJobResponse create() => GetCronJobResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetCronJobResponse._();
  @$core.override
  GetCronJobResponse createEmptyInstance() => GetCronJobResponse._();
  @$core.pragma('dart2js:noInline')
  static GetCronJobResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCronJobResponse>(
          GetCronJobResponse.$_createMessage);
  static GetCronJobResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CronJob get job => $_getN(0);
  @$pb.TagNumber(1)
  set job(CronJob value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasJob() => $_has(0);
  @$pb.TagNumber(1)
  void clearJob() => $_clearField(1);
  @$pb.TagNumber(1)
  CronJob ensureJob() => $_ensure(0);
}

class RunCronJobRequest extends $pb.GeneratedMessage {
  factory RunCronJobRequest({
    $core.String? name,
  }) {
    final result = RunCronJobRequest._();
    if (name != null) result.name = name;
    return result;
  }

  RunCronJobRequest._();

  factory RunCronJobRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunCronJobRequest()..mergeFromBuffer(data, registry);
  factory RunCronJobRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunCronJobRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunCronJobRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RunCronJobRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunCronJobRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunCronJobRequest copyWith(void Function(RunCronJobRequest) updates) =>
      super.copyWith((message) => updates(message as RunCronJobRequest))
          as RunCronJobRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunCronJobRequest() / RunCronJobRequest.new instead')
  static RunCronJobRequest create() => RunCronJobRequest._();
  static $pb.GeneratedMessage $_createMessage() => RunCronJobRequest._();
  @$core.override
  RunCronJobRequest createEmptyInstance() => RunCronJobRequest._();
  @$core.pragma('dart2js:noInline')
  static RunCronJobRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RunCronJobRequest>(
          RunCronJobRequest.$_createMessage);
  static RunCronJobRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class RunCronJobResponse extends $pb.GeneratedMessage {
  factory RunCronJobResponse({
    CronRun? run,
  }) {
    final result = RunCronJobResponse._();
    if (run != null) result.run = run;
    return result;
  }

  RunCronJobResponse._();

  factory RunCronJobResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunCronJobResponse()..mergeFromBuffer(data, registry);
  factory RunCronJobResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunCronJobResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunCronJobResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RunCronJobResponse.$_createMessage)
    ..aOM<CronRun>(1, _omitFieldNames ? '' : 'run',
        subBuilder: CronRun.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunCronJobResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunCronJobResponse copyWith(void Function(RunCronJobResponse) updates) =>
      super.copyWith((message) => updates(message as RunCronJobResponse))
          as RunCronJobResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunCronJobResponse() / RunCronJobResponse.new instead')
  static RunCronJobResponse create() => RunCronJobResponse._();
  static $pb.GeneratedMessage $_createMessage() => RunCronJobResponse._();
  @$core.override
  RunCronJobResponse createEmptyInstance() => RunCronJobResponse._();
  @$core.pragma('dart2js:noInline')
  static RunCronJobResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunCronJobResponse>(
          RunCronJobResponse.$_createMessage);
  static RunCronJobResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CronRun get run => $_getN(0);
  @$pb.TagNumber(1)
  set run(CronRun value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRun() => $_has(0);
  @$pb.TagNumber(1)
  void clearRun() => $_clearField(1);
  @$pb.TagNumber(1)
  CronRun ensureRun() => $_ensure(0);
}

class SetCronJobEnabledRequest extends $pb.GeneratedMessage {
  factory SetCronJobEnabledRequest({
    $core.String? name,
    $core.bool? enabled,
  }) {
    final result = SetCronJobEnabledRequest._();
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetCronJobEnabledRequest._();

  factory SetCronJobEnabledRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetCronJobEnabledRequest()..mergeFromBuffer(data, registry);
  factory SetCronJobEnabledRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetCronJobEnabledRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetCronJobEnabledRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetCronJobEnabledRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetCronJobEnabledRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetCronJobEnabledRequest copyWith(
          void Function(SetCronJobEnabledRequest) updates) =>
      super.copyWith((message) => updates(message as SetCronJobEnabledRequest))
          as SetCronJobEnabledRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetCronJobEnabledRequest() / SetCronJobEnabledRequest.new instead')
  static SetCronJobEnabledRequest create() => SetCronJobEnabledRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetCronJobEnabledRequest._();
  @$core.override
  SetCronJobEnabledRequest createEmptyInstance() =>
      SetCronJobEnabledRequest._();
  @$core.pragma('dart2js:noInline')
  static SetCronJobEnabledRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetCronJobEnabledRequest>(
          SetCronJobEnabledRequest.$_createMessage);
  static SetCronJobEnabledRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class SetCronJobEnabledResponse extends $pb.GeneratedMessage {
  factory SetCronJobEnabledResponse({
    CronJob? job,
  }) {
    final result = SetCronJobEnabledResponse._();
    if (job != null) result.job = job;
    return result;
  }

  SetCronJobEnabledResponse._();

  factory SetCronJobEnabledResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetCronJobEnabledResponse()..mergeFromBuffer(data, registry);
  factory SetCronJobEnabledResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetCronJobEnabledResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetCronJobEnabledResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetCronJobEnabledResponse.$_createMessage)
    ..aOM<CronJob>(1, _omitFieldNames ? '' : 'job',
        subBuilder: CronJob.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetCronJobEnabledResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetCronJobEnabledResponse copyWith(
          void Function(SetCronJobEnabledResponse) updates) =>
      super.copyWith((message) => updates(message as SetCronJobEnabledResponse))
          as SetCronJobEnabledResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetCronJobEnabledResponse() / SetCronJobEnabledResponse.new instead')
  static SetCronJobEnabledResponse create() => SetCronJobEnabledResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetCronJobEnabledResponse._();
  @$core.override
  SetCronJobEnabledResponse createEmptyInstance() =>
      SetCronJobEnabledResponse._();
  @$core.pragma('dart2js:noInline')
  static SetCronJobEnabledResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetCronJobEnabledResponse>(
          SetCronJobEnabledResponse.$_createMessage);
  static SetCronJobEnabledResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CronJob get job => $_getN(0);
  @$pb.TagNumber(1)
  set job(CronJob value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasJob() => $_has(0);
  @$pb.TagNumber(1)
  void clearJob() => $_clearField(1);
  @$pb.TagNumber(1)
  CronJob ensureJob() => $_ensure(0);
}

class ListCronRunsRequest extends $pb.GeneratedMessage {
  factory ListCronRunsRequest({
    $core.String? name,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = ListCronRunsRequest._();
    if (name != null) result.name = name;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListCronRunsRequest._();

  factory ListCronRunsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronRunsRequest()..mergeFromBuffer(data, registry);
  factory ListCronRunsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronRunsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListCronRunsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListCronRunsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'pageSize')
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronRunsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronRunsRequest copyWith(void Function(ListCronRunsRequest) updates) =>
      super.copyWith((message) => updates(message as ListCronRunsRequest))
          as ListCronRunsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListCronRunsRequest() / ListCronRunsRequest.new instead')
  static ListCronRunsRequest create() => ListCronRunsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListCronRunsRequest._();
  @$core.override
  ListCronRunsRequest createEmptyInstance() => ListCronRunsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListCronRunsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCronRunsRequest>(
          ListCronRunsRequest.$_createMessage);
  static ListCronRunsRequest? _defaultInstance;

  /// Empty lists every job's runs.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Default 50, at most 200.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  /// From a previous response's next_page_token.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

class ListCronRunsResponse extends $pb.GeneratedMessage {
  factory ListCronRunsResponse({
    $core.Iterable<CronRun>? runs,
    $core.String? nextPageToken,
  }) {
    final result = ListCronRunsResponse._();
    if (runs != null) result.runs.addAll(runs);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListCronRunsResponse._();

  factory ListCronRunsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronRunsResponse()..mergeFromBuffer(data, registry);
  factory ListCronRunsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCronRunsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListCronRunsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListCronRunsResponse.$_createMessage)
    ..pPM<CronRun>(1, _omitFieldNames ? '' : 'runs',
        subBuilder: CronRun.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronRunsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCronRunsResponse copyWith(void Function(ListCronRunsResponse) updates) =>
      super.copyWith((message) => updates(message as ListCronRunsResponse))
          as ListCronRunsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListCronRunsResponse() / ListCronRunsResponse.new instead')
  static ListCronRunsResponse create() => ListCronRunsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListCronRunsResponse._();
  @$core.override
  ListCronRunsResponse createEmptyInstance() => ListCronRunsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListCronRunsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCronRunsResponse>(
          ListCronRunsResponse.$_createMessage);
  static ListCronRunsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CronRun> get runs => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// CronService lists and runs cron jobs. A cron job is a prompt flit runs
/// on a schedule, unattended, each run as a new session in the job's
/// project. Jobs are Markdown files with YAML frontmatter in the server's
/// crons directory (see docs/cron.md); edit them there or ask an agent (the
/// cron tool).
class CronServiceApi {
  final $pb.RpcClient _client;

  CronServiceApi(this._client);

  $async.Future<ListCronJobsResponse> listCronJobs(
          $pb.ClientContext? ctx, ListCronJobsRequest request) =>
      _client.invoke<ListCronJobsResponse>(
          ctx, 'CronService', 'ListCronJobs', request, ListCronJobsResponse());
  $async.Future<GetCronJobResponse> getCronJob(
          $pb.ClientContext? ctx, GetCronJobRequest request) =>
      _client.invoke<GetCronJobResponse>(
          ctx, 'CronService', 'GetCronJob', request, GetCronJobResponse());

  /// RunCronJob starts a run now, whatever the schedule and even if the job
  /// is disabled. Fails with FAILED_PRECONDITION while a run of the job is
  /// going.
  $async.Future<RunCronJobResponse> runCronJob(
          $pb.ClientContext? ctx, RunCronJobRequest request) =>
      _client.invoke<RunCronJobResponse>(
          ctx, 'CronService', 'RunCronJob', request, RunCronJobResponse());

  /// SetCronJobEnabled turns a job's schedule on or off (it rewrites
  /// enabled: in the job file).
  $async.Future<SetCronJobEnabledResponse> setCronJobEnabled(
          $pb.ClientContext? ctx, SetCronJobEnabledRequest request) =>
      _client.invoke<SetCronJobEnabledResponse>(ctx, 'CronService',
          'SetCronJobEnabled', request, SetCronJobEnabledResponse());

  /// ListCronRuns lists a job's runs, newest first.
  $async.Future<ListCronRunsResponse> listCronRuns(
          $pb.ClientContext? ctx, ListCronRunsRequest request) =>
      _client.invoke<ListCronRunsResponse>(
          ctx, 'CronService', 'ListCronRuns', request, ListCronRunsResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
