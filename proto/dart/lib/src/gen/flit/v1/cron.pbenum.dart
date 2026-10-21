// This is a generated file - do not edit.
//
// Generated from flit/v1/cron.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CronAsk extends $pb.ProtobufEnum {
  static const CronAsk CRON_ASK_UNSPECIFIED =
      CronAsk._(0, _omitEnumNames ? '' : 'CRON_ASK_UNSPECIFIED');

  /// A command that would ask is refused at once.
  static const CronAsk CRON_ASK_DENY =
      CronAsk._(1, _omitEnumNames ? '' : 'CRON_ASK_DENY');

  /// The prompt is held for ask_timeout, then refused.
  static const CronAsk CRON_ASK_WAIT =
      CronAsk._(2, _omitEnumNames ? '' : 'CRON_ASK_WAIT');

  static const $core.List<CronAsk> values = <CronAsk>[
    CRON_ASK_UNSPECIFIED,
    CRON_ASK_DENY,
    CRON_ASK_WAIT,
  ];

  static final $core.List<CronAsk?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CronAsk? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CronAsk._(super.value, super.name);
}

class CronRunState extends $pb.ProtobufEnum {
  static const CronRunState CRON_RUN_STATE_UNSPECIFIED =
      CronRunState._(0, _omitEnumNames ? '' : 'CRON_RUN_STATE_UNSPECIFIED');
  static const CronRunState CRON_RUN_STATE_RUNNING =
      CronRunState._(1, _omitEnumNames ? '' : 'CRON_RUN_STATE_RUNNING');

  /// Finished; the summary is the report's first line.
  static const CronRunState CRON_RUN_STATE_OK =
      CronRunState._(2, _omitEnumNames ? '' : 'CRON_RUN_STATE_OK');

  /// Finished, but something it wanted to do was refused (see
  /// refused_commands) or needs a look.
  static const CronRunState CRON_RUN_STATE_NEEDS_ATTENTION =
      CronRunState._(3, _omitEnumNames ? '' : 'CRON_RUN_STATE_NEEDS_ATTENTION');

  /// The run could not start or its turn ended in an error.
  static const CronRunState CRON_RUN_STATE_FAILED =
      CronRunState._(4, _omitEnumNames ? '' : 'CRON_RUN_STATE_FAILED');

  /// Not run: the previous run was still going.
  static const CronRunState CRON_RUN_STATE_SKIPPED =
      CronRunState._(5, _omitEnumNames ? '' : 'CRON_RUN_STATE_SKIPPED');

  static const $core.List<CronRunState> values = <CronRunState>[
    CRON_RUN_STATE_UNSPECIFIED,
    CRON_RUN_STATE_RUNNING,
    CRON_RUN_STATE_OK,
    CRON_RUN_STATE_NEEDS_ATTENTION,
    CRON_RUN_STATE_FAILED,
    CRON_RUN_STATE_SKIPPED,
  ];

  static final $core.List<CronRunState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static CronRunState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CronRunState._(super.value, super.name);
}

class CronTrigger extends $pb.ProtobufEnum {
  static const CronTrigger CRON_TRIGGER_UNSPECIFIED =
      CronTrigger._(0, _omitEnumNames ? '' : 'CRON_TRIGGER_UNSPECIFIED');
  static const CronTrigger CRON_TRIGGER_SCHEDULE =
      CronTrigger._(1, _omitEnumNames ? '' : 'CRON_TRIGGER_SCHEDULE');

  /// A slot missed while flit was down, run late at startup.
  static const CronTrigger CRON_TRIGGER_CATCH_UP =
      CronTrigger._(2, _omitEnumNames ? '' : 'CRON_TRIGGER_CATCH_UP');

  /// RunCronJob, "flit cron run" or the cron tool.
  static const CronTrigger CRON_TRIGGER_MANUAL =
      CronTrigger._(3, _omitEnumNames ? '' : 'CRON_TRIGGER_MANUAL');

  static const $core.List<CronTrigger> values = <CronTrigger>[
    CRON_TRIGGER_UNSPECIFIED,
    CRON_TRIGGER_SCHEDULE,
    CRON_TRIGGER_CATCH_UP,
    CRON_TRIGGER_MANUAL,
  ];

  static final $core.List<CronTrigger?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CronTrigger? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CronTrigger._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
