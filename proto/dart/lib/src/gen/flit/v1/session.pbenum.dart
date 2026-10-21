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

class PermissionVerdict extends $pb.ProtobufEnum {
  static const PermissionVerdict PERMISSION_VERDICT_UNSPECIFIED =
      PermissionVerdict._(
          0, _omitEnumNames ? '' : 'PERMISSION_VERDICT_UNSPECIFIED');

  /// Runs without asking.
  static const PermissionVerdict PERMISSION_VERDICT_SAFE =
      PermissionVerdict._(1, _omitEnumNames ? '' : 'PERMISSION_VERDICT_SAFE');

  /// The user is asked.
  static const PermissionVerdict PERMISSION_VERDICT_ASK =
      PermissionVerdict._(2, _omitEnumNames ? '' : 'PERMISSION_VERDICT_ASK');

  /// Refused; the model is told why.
  static const PermissionVerdict PERMISSION_VERDICT_BLOCK =
      PermissionVerdict._(3, _omitEnumNames ? '' : 'PERMISSION_VERDICT_BLOCK');

  /// The check failed (no or unreadable answer); the user is asked.
  static const PermissionVerdict PERMISSION_VERDICT_ERROR =
      PermissionVerdict._(4, _omitEnumNames ? '' : 'PERMISSION_VERDICT_ERROR');

  static const $core.List<PermissionVerdict> values = <PermissionVerdict>[
    PERMISSION_VERDICT_UNSPECIFIED,
    PERMISSION_VERDICT_SAFE,
    PERMISSION_VERDICT_ASK,
    PERMISSION_VERDICT_BLOCK,
    PERMISSION_VERDICT_ERROR,
  ];

  static final $core.List<PermissionVerdict?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PermissionVerdict? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PermissionVerdict._(super.value, super.name);
}

class ModelCallOutcome extends $pb.ProtobufEnum {
  static const ModelCallOutcome MODEL_CALL_OUTCOME_UNSPECIFIED =
      ModelCallOutcome._(
          0, _omitEnumNames ? '' : 'MODEL_CALL_OUTCOME_UNSPECIFIED');
  static const ModelCallOutcome MODEL_CALL_OUTCOME_OK =
      ModelCallOutcome._(1, _omitEnumNames ? '' : 'MODEL_CALL_OUTCOME_OK');

  /// The watchdog gave up: nothing arrived for too long (see phase).
  static const ModelCallOutcome MODEL_CALL_OUTCOME_STALLED =
      ModelCallOutcome._(2, _omitEnumNames ? '' : 'MODEL_CALL_OUTCOME_STALLED');

  /// The endpoint returned an error or the connection broke.
  static const ModelCallOutcome MODEL_CALL_OUTCOME_ERROR =
      ModelCallOutcome._(3, _omitEnumNames ? '' : 'MODEL_CALL_OUTCOME_ERROR');

  /// The turn was interrupted.
  static const ModelCallOutcome MODEL_CALL_OUTCOME_CANCELLED =
      ModelCallOutcome._(
          4, _omitEnumNames ? '' : 'MODEL_CALL_OUTCOME_CANCELLED');

  /// Someone asked for it to be sent again (RetryModelCall).
  static const ModelCallOutcome MODEL_CALL_OUTCOME_RETRIED =
      ModelCallOutcome._(5, _omitEnumNames ? '' : 'MODEL_CALL_OUTCOME_RETRIED');

  static const $core.List<ModelCallOutcome> values = <ModelCallOutcome>[
    MODEL_CALL_OUTCOME_UNSPECIFIED,
    MODEL_CALL_OUTCOME_OK,
    MODEL_CALL_OUTCOME_STALLED,
    MODEL_CALL_OUTCOME_ERROR,
    MODEL_CALL_OUTCOME_CANCELLED,
    MODEL_CALL_OUTCOME_RETRIED,
  ];

  static final $core.List<ModelCallOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ModelCallOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModelCallOutcome._(super.value, super.name);
}

/// ModelWaitReason is why a model call hasn't started, as the model server
/// reports it.
class ModelWaitReason extends $pb.ProtobufEnum {
  static const ModelWaitReason MODEL_WAIT_REASON_UNSPECIFIED =
      ModelWaitReason._(
          0, _omitEnumNames ? '' : 'MODEL_WAIT_REASON_UNSPECIFIED');

  /// Every slot of the llama.cpp server is busy with other requests; this
  /// one waits for a free one.
  static const ModelWaitReason MODEL_WAIT_REASON_SLOTS_BUSY = ModelWaitReason._(
      1, _omitEnumNames ? '' : 'MODEL_WAIT_REASON_SLOTS_BUSY');

  /// The model is asleep (idle, swapped out) and wakes up first.
  static const ModelWaitReason MODEL_WAIT_REASON_SLEEPING =
      ModelWaitReason._(2, _omitEnumNames ? '' : 'MODEL_WAIT_REASON_SLEEPING');

  /// The llama.cpp router is loading the model.
  static const ModelWaitReason MODEL_WAIT_REASON_LOADING =
      ModelWaitReason._(3, _omitEnumNames ? '' : 'MODEL_WAIT_REASON_LOADING');

  static const $core.List<ModelWaitReason> values = <ModelWaitReason>[
    MODEL_WAIT_REASON_UNSPECIFIED,
    MODEL_WAIT_REASON_SLOTS_BUSY,
    MODEL_WAIT_REASON_SLEEPING,
    MODEL_WAIT_REASON_LOADING,
  ];

  static final $core.List<ModelWaitReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ModelWaitReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModelWaitReason._(super.value, super.name);
}

class PromptCacheAction extends $pb.ProtobufEnum {
  static const PromptCacheAction PROMPT_CACHE_ACTION_UNSPECIFIED =
      PromptCacheAction._(
          0, _omitEnumNames ? '' : 'PROMPT_CACHE_ACTION_UNSPECIFIED');

  /// The session's cache was written to a save file on the llama.cpp server
  /// (another session needed its slot, or it sat idle).
  static const PromptCacheAction PROMPT_CACHE_ACTION_SAVED =
      PromptCacheAction._(1, _omitEnumNames ? '' : 'PROMPT_CACHE_ACTION_SAVED');

  /// The session's saved cache was loaded back into a slot before a call.
  static const PromptCacheAction PROMPT_CACHE_ACTION_RESTORED =
      PromptCacheAction._(
          2, _omitEnumNames ? '' : 'PROMPT_CACHE_ACTION_RESTORED');

  /// The session's save file no longer matches its prompt (the conversation
  /// was compacted), so it won't be restored.
  static const PromptCacheAction PROMPT_CACHE_ACTION_DISCARDED =
      PromptCacheAction._(
          3, _omitEnumNames ? '' : 'PROMPT_CACHE_ACTION_DISCARDED');

  static const $core.List<PromptCacheAction> values = <PromptCacheAction>[
    PROMPT_CACHE_ACTION_UNSPECIFIED,
    PROMPT_CACHE_ACTION_SAVED,
    PROMPT_CACHE_ACTION_RESTORED,
    PROMPT_CACHE_ACTION_DISCARDED,
  ];

  static final $core.List<PromptCacheAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PromptCacheAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PromptCacheAction._(super.value, super.name);
}

class BranchKind extends $pb.ProtobufEnum {
  static const BranchKind BRANCH_KIND_UNSPECIFIED =
      BranchKind._(0, _omitEnumNames ? '' : 'BRANCH_KIND_UNSPECIFIED');

  /// RetryFromMessage: the same user message, answered again.
  static const BranchKind BRANCH_KIND_RETRY =
      BranchKind._(1, _omitEnumNames ? '' : 'BRANCH_KIND_RETRY');

  /// EditMessage: a different user message in its place.
  static const BranchKind BRANCH_KIND_EDIT =
      BranchKind._(2, _omitEnumNames ? '' : 'BRANCH_KIND_EDIT');

  static const $core.List<BranchKind> values = <BranchKind>[
    BRANCH_KIND_UNSPECIFIED,
    BRANCH_KIND_RETRY,
    BRANCH_KIND_EDIT,
  ];

  static final $core.List<BranchKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static BranchKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BranchKind._(super.value, super.name);
}

/// GitDiffBase says what a session's changes are compared against.
class GitDiffBase extends $pb.ProtobufEnum {
  static const GitDiffBase GIT_DIFF_BASE_UNSPECIFIED =
      GitDiffBase._(0, _omitEnumNames ? '' : 'GIT_DIFF_BASE_UNSPECIFIED');

  /// The session's base commit.
  static const GitDiffBase GIT_DIFF_BASE_SESSION_START =
      GitDiffBase._(1, _omitEnumNames ? '' : 'GIT_DIFF_BASE_SESSION_START');

  /// HEAD, because the session has no base commit.
  static const GitDiffBase GIT_DIFF_BASE_HEAD_NO_BASE =
      GitDiffBase._(2, _omitEnumNames ? '' : 'GIT_DIFF_BASE_HEAD_NO_BASE');

  /// HEAD, because the base commit no longer exists in the repository.
  static const GitDiffBase GIT_DIFF_BASE_HEAD_BASE_MISSING =
      GitDiffBase._(3, _omitEnumNames ? '' : 'GIT_DIFF_BASE_HEAD_BASE_MISSING');

  /// The empty tree: there is no base and no HEAD commit, so every file is
  /// new.
  static const GitDiffBase GIT_DIFF_BASE_EMPTY_TREE =
      GitDiffBase._(4, _omitEnumNames ? '' : 'GIT_DIFF_BASE_EMPTY_TREE');

  static const $core.List<GitDiffBase> values = <GitDiffBase>[
    GIT_DIFF_BASE_UNSPECIFIED,
    GIT_DIFF_BASE_SESSION_START,
    GIT_DIFF_BASE_HEAD_NO_BASE,
    GIT_DIFF_BASE_HEAD_BASE_MISSING,
    GIT_DIFF_BASE_EMPTY_TREE,
  ];

  static final $core.List<GitDiffBase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static GitDiffBase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GitDiffBase._(super.value, super.name);
}

class GitFileStatus extends $pb.ProtobufEnum {
  static const GitFileStatus GIT_FILE_STATUS_UNSPECIFIED =
      GitFileStatus._(0, _omitEnumNames ? '' : 'GIT_FILE_STATUS_UNSPECIFIED');
  static const GitFileStatus GIT_FILE_STATUS_MODIFIED =
      GitFileStatus._(1, _omitEnumNames ? '' : 'GIT_FILE_STATUS_MODIFIED');
  static const GitFileStatus GIT_FILE_STATUS_ADDED =
      GitFileStatus._(2, _omitEnumNames ? '' : 'GIT_FILE_STATUS_ADDED');
  static const GitFileStatus GIT_FILE_STATUS_DELETED =
      GitFileStatus._(3, _omitEnumNames ? '' : 'GIT_FILE_STATUS_DELETED');
  static const GitFileStatus GIT_FILE_STATUS_RENAMED =
      GitFileStatus._(4, _omitEnumNames ? '' : 'GIT_FILE_STATUS_RENAMED');
  static const GitFileStatus GIT_FILE_STATUS_COPIED =
      GitFileStatus._(5, _omitEnumNames ? '' : 'GIT_FILE_STATUS_COPIED');
  static const GitFileStatus GIT_FILE_STATUS_TYPE_CHANGED =
      GitFileStatus._(6, _omitEnumNames ? '' : 'GIT_FILE_STATUS_TYPE_CHANGED');
  static const GitFileStatus GIT_FILE_STATUS_UNMERGED =
      GitFileStatus._(7, _omitEnumNames ? '' : 'GIT_FILE_STATUS_UNMERGED');

  static const $core.List<GitFileStatus> values = <GitFileStatus>[
    GIT_FILE_STATUS_UNSPECIFIED,
    GIT_FILE_STATUS_MODIFIED,
    GIT_FILE_STATUS_ADDED,
    GIT_FILE_STATUS_DELETED,
    GIT_FILE_STATUS_RENAMED,
    GIT_FILE_STATUS_COPIED,
    GIT_FILE_STATUS_TYPE_CHANGED,
    GIT_FILE_STATUS_UNMERGED,
  ];

  static final $core.List<GitFileStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static GitFileStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GitFileStatus._(super.value, super.name);
}

/// SubagentKind is what a subagent may do.
class SubagentKind extends $pb.ProtobufEnum {
  static const SubagentKind SUBAGENT_KIND_UNSPECIFIED =
      SubagentKind._(0, _omitEnumNames ? '' : 'SUBAGENT_KIND_UNSPECIFIED');

  /// Read-only tools only; never asks the user anything.
  static const SubagentKind SUBAGENT_KIND_EXPLORE =
      SubagentKind._(1, _omitEnumNames ? '' : 'SUBAGENT_KIND_EXPLORE');

  /// Every tool the session has (but agent); its calls go through the
  /// session's permission rules and prompts like the agent's own.
  static const SubagentKind SUBAGENT_KIND_BUILD =
      SubagentKind._(2, _omitEnumNames ? '' : 'SUBAGENT_KIND_BUILD');

  static const $core.List<SubagentKind> values = <SubagentKind>[
    SUBAGENT_KIND_UNSPECIFIED,
    SUBAGENT_KIND_EXPLORE,
    SUBAGENT_KIND_BUILD,
  ];

  static final $core.List<SubagentKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SubagentKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SubagentKind._(super.value, super.name);
}

class SubagentOutcome extends $pb.ProtobufEnum {
  static const SubagentOutcome SUBAGENT_OUTCOME_UNSPECIFIED = SubagentOutcome._(
      0, _omitEnumNames ? '' : 'SUBAGENT_OUTCOME_UNSPECIFIED');

  /// It finished and wrote its report.
  static const SubagentOutcome SUBAGENT_OUTCOME_DONE =
      SubagentOutcome._(1, _omitEnumNames ? '' : 'SUBAGENT_OUTCOME_DONE');

  /// It hit its step cap; report is what it wrote when told to stop.
  static const SubagentOutcome SUBAGENT_OUTCOME_STEP_LIMIT =
      SubagentOutcome._(2, _omitEnumNames ? '' : 'SUBAGENT_OUTCOME_STEP_LIMIT');

  /// The turn was stopped.
  static const SubagentOutcome SUBAGENT_OUTCOME_CANCELLED =
      SubagentOutcome._(3, _omitEnumNames ? '' : 'SUBAGENT_OUTCOME_CANCELLED');

  /// It could not run or its model call failed (see error).
  static const SubagentOutcome SUBAGENT_OUTCOME_ERROR =
      SubagentOutcome._(4, _omitEnumNames ? '' : 'SUBAGENT_OUTCOME_ERROR');

  static const $core.List<SubagentOutcome> values = <SubagentOutcome>[
    SUBAGENT_OUTCOME_UNSPECIFIED,
    SUBAGENT_OUTCOME_DONE,
    SUBAGENT_OUTCOME_STEP_LIMIT,
    SUBAGENT_OUTCOME_CANCELLED,
    SUBAGENT_OUTCOME_ERROR,
  ];

  static final $core.List<SubagentOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SubagentOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SubagentOutcome._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
