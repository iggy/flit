// This is a generated file - do not edit.
//
// Generated from flit/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// TaskState is what a session's agent is doing.
class TaskState extends $pb.ProtobufEnum {
  static const TaskState TASK_STATE_UNSPECIFIED =
      TaskState._(0, _omitEnumNames ? '' : 'TASK_STATE_UNSPECIFIED');

  /// Created, no turn has run yet.
  static const TaskState TASK_STATE_IDLE =
      TaskState._(1, _omitEnumNames ? '' : 'TASK_STATE_IDLE');

  /// A turn is running.
  static const TaskState TASK_STATE_WORKING =
      TaskState._(2, _omitEnumNames ? '' : 'TASK_STATE_WORKING');

  /// The turn is waiting for a client to answer a prompt.
  static const TaskState TASK_STATE_WAITING =
      TaskState._(3, _omitEnumNames ? '' : 'TASK_STATE_WAITING');

  /// The turn stopped on an error it could not get past.
  static const TaskState TASK_STATE_STUCK =
      TaskState._(4, _omitEnumNames ? '' : 'TASK_STATE_STUCK');

  /// The turn finished (or was interrupted); waiting for the next message.
  static const TaskState TASK_STATE_DONE =
      TaskState._(5, _omitEnumNames ? '' : 'TASK_STATE_DONE');

  static const $core.List<TaskState> values = <TaskState>[
    TASK_STATE_UNSPECIFIED,
    TASK_STATE_IDLE,
    TASK_STATE_WORKING,
    TASK_STATE_WAITING,
    TASK_STATE_STUCK,
    TASK_STATE_DONE,
  ];

  static final $core.List<TaskState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static TaskState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TaskState._(super.value, super.name);
}

class RatingTarget extends $pb.ProtobufEnum {
  static const RatingTarget RATING_TARGET_UNSPECIFIED =
      RatingTarget._(0, _omitEnumNames ? '' : 'RATING_TARGET_UNSPECIFIED');

  /// The result of the turn that produced message_id.
  static const RatingTarget RATING_TARGET_TURN =
      RatingTarget._(1, _omitEnumNames ? '' : 'RATING_TARGET_TURN');

  /// The model that produced message_id (or the session's current model).
  static const RatingTarget RATING_TARGET_MODEL =
      RatingTarget._(2, _omitEnumNames ? '' : 'RATING_TARGET_MODEL');

  static const $core.List<RatingTarget> values = <RatingTarget>[
    RATING_TARGET_UNSPECIFIED,
    RATING_TARGET_TURN,
    RATING_TARGET_MODEL,
  ];

  static final $core.List<RatingTarget?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static RatingTarget? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RatingTarget._(super.value, super.name);
}

class Rating extends $pb.ProtobufEnum {
  static const Rating RATING_UNSPECIFIED =
      Rating._(0, _omitEnumNames ? '' : 'RATING_UNSPECIFIED');
  static const Rating RATING_GOOD =
      Rating._(1, _omitEnumNames ? '' : 'RATING_GOOD');
  static const Rating RATING_BAD =
      Rating._(2, _omitEnumNames ? '' : 'RATING_BAD');

  static const $core.List<Rating> values = <Rating>[
    RATING_UNSPECIFIED,
    RATING_GOOD,
    RATING_BAD,
  ];

  static final $core.List<Rating?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Rating? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Rating._(super.value, super.name);
}

class Role extends $pb.ProtobufEnum {
  static const Role ROLE_UNSPECIFIED =
      Role._(0, _omitEnumNames ? '' : 'ROLE_UNSPECIFIED');
  static const Role ROLE_USER = Role._(1, _omitEnumNames ? '' : 'ROLE_USER');
  static const Role ROLE_ASSISTANT =
      Role._(2, _omitEnumNames ? '' : 'ROLE_ASSISTANT');

  static const $core.List<Role> values = <Role>[
    ROLE_UNSPECIFIED,
    ROLE_USER,
    ROLE_ASSISTANT,
  ];

  static final $core.List<Role?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Role? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Role._(super.value, super.name);
}

class PromptDecision extends $pb.ProtobufEnum {
  static const PromptDecision PROMPT_DECISION_UNSPECIFIED =
      PromptDecision._(0, _omitEnumNames ? '' : 'PROMPT_DECISION_UNSPECIFIED');
  static const PromptDecision PROMPT_DECISION_ALLOW =
      PromptDecision._(1, _omitEnumNames ? '' : 'PROMPT_DECISION_ALLOW');
  static const PromptDecision PROMPT_DECISION_DENY =
      PromptDecision._(2, _omitEnumNames ? '' : 'PROMPT_DECISION_DENY');

  /// Allow, and allow the prompt's session_patterns for the rest of the
  /// session without asking again. Only valid when the prompt offered
  /// session_patterns.
  static const PromptDecision PROMPT_DECISION_ALLOW_SESSION = PromptDecision._(
      3, _omitEnumNames ? '' : 'PROMPT_DECISION_ALLOW_SESSION');

  static const $core.List<PromptDecision> values = <PromptDecision>[
    PROMPT_DECISION_UNSPECIFIED,
    PROMPT_DECISION_ALLOW,
    PROMPT_DECISION_DENY,
    PROMPT_DECISION_ALLOW_SESSION,
  ];

  static final $core.List<PromptDecision?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PromptDecision? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PromptDecision._(super.value, super.name);
}

class TodoStatus extends $pb.ProtobufEnum {
  static const TodoStatus TODO_STATUS_UNSPECIFIED =
      TodoStatus._(0, _omitEnumNames ? '' : 'TODO_STATUS_UNSPECIFIED');
  static const TodoStatus TODO_STATUS_PENDING =
      TodoStatus._(1, _omitEnumNames ? '' : 'TODO_STATUS_PENDING');
  static const TodoStatus TODO_STATUS_IN_PROGRESS =
      TodoStatus._(2, _omitEnumNames ? '' : 'TODO_STATUS_IN_PROGRESS');
  static const TodoStatus TODO_STATUS_COMPLETED =
      TodoStatus._(3, _omitEnumNames ? '' : 'TODO_STATUS_COMPLETED');

  static const $core.List<TodoStatus> values = <TodoStatus>[
    TODO_STATUS_UNSPECIFIED,
    TODO_STATUS_PENDING,
    TODO_STATUS_IN_PROGRESS,
    TODO_STATUS_COMPLETED,
  ];

  static final $core.List<TodoStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TodoStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TodoStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
