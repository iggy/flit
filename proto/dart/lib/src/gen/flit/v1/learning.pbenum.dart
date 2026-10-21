// This is a generated file - do not edit.
//
// Generated from flit/v1/learning.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LearnAction extends $pb.ProtobufEnum {
  static const LearnAction LEARN_ACTION_UNSPECIFIED =
      LearnAction._(0, _omitEnumNames ? '' : 'LEARN_ACTION_UNSPECIFIED');
  static const LearnAction LEARN_ACTION_ADD =
      LearnAction._(1, _omitEnumNames ? '' : 'LEARN_ACTION_ADD');
  static const LearnAction LEARN_ACTION_UPDATE =
      LearnAction._(2, _omitEnumNames ? '' : 'LEARN_ACTION_UPDATE');
  static const LearnAction LEARN_ACTION_REMOVE =
      LearnAction._(3, _omitEnumNames ? '' : 'LEARN_ACTION_REMOVE');

  static const $core.List<LearnAction> values = <LearnAction>[
    LEARN_ACTION_UNSPECIFIED,
    LEARN_ACTION_ADD,
    LEARN_ACTION_UPDATE,
    LEARN_ACTION_REMOVE,
  ];

  static final $core.List<LearnAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static LearnAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LearnAction._(super.value, super.name);
}

class LearnTarget extends $pb.ProtobufEnum {
  static const LearnTarget LEARN_TARGET_UNSPECIFIED =
      LearnTarget._(0, _omitEnumNames ? '' : 'LEARN_TARGET_UNSPECIFIED');

  /// The user memory file, in every session.
  static const LearnTarget LEARN_TARGET_USER =
      LearnTarget._(1, _omitEnumNames ? '' : 'LEARN_TARGET_USER');

  /// The session's project's memory file.
  static const LearnTarget LEARN_TARGET_PROJECT =
      LearnTarget._(2, _omitEnumNames ? '' : 'LEARN_TARGET_PROJECT');

  /// The session's role's memory_file.
  static const LearnTarget LEARN_TARGET_ROLE =
      LearnTarget._(3, _omitEnumNames ? '' : 'LEARN_TARGET_ROLE');

  /// A skill's SKILL.md.
  static const LearnTarget LEARN_TARGET_SKILL =
      LearnTarget._(4, _omitEnumNames ? '' : 'LEARN_TARGET_SKILL');

  static const $core.List<LearnTarget> values = <LearnTarget>[
    LEARN_TARGET_UNSPECIFIED,
    LEARN_TARGET_USER,
    LEARN_TARGET_PROJECT,
    LEARN_TARGET_ROLE,
    LEARN_TARGET_SKILL,
  ];

  static final $core.List<LearnTarget?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static LearnTarget? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LearnTarget._(super.value, super.name);
}

class LearnStatus extends $pb.ProtobufEnum {
  static const LearnStatus LEARN_STATUS_UNSPECIFIED =
      LearnStatus._(0, _omitEnumNames ? '' : 'LEARN_STATUS_UNSPECIFIED');
  static const LearnStatus LEARN_STATUS_PENDING =
      LearnStatus._(1, _omitEnumNames ? '' : 'LEARN_STATUS_PENDING');
  static const LearnStatus LEARN_STATUS_ACCEPTED =
      LearnStatus._(2, _omitEnumNames ? '' : 'LEARN_STATUS_ACCEPTED');
  static const LearnStatus LEARN_STATUS_REJECTED =
      LearnStatus._(3, _omitEnumNames ? '' : 'LEARN_STATUS_REJECTED');

  static const $core.List<LearnStatus> values = <LearnStatus>[
    LEARN_STATUS_UNSPECIFIED,
    LEARN_STATUS_PENDING,
    LEARN_STATUS_ACCEPTED,
    LEARN_STATUS_REJECTED,
  ];

  static final $core.List<LearnStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static LearnStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LearnStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
