// This is a generated file - do not edit.
//
// Generated from flit/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/timestamp.pbjson.dart'
    as $0;

@$core.Deprecated('Use taskStateDescriptor instead')
const TaskState$json = {
  '1': 'TaskState',
  '2': [
    {'1': 'TASK_STATE_UNSPECIFIED', '2': 0},
    {'1': 'TASK_STATE_IDLE', '2': 1},
    {'1': 'TASK_STATE_WORKING', '2': 2},
    {'1': 'TASK_STATE_WAITING', '2': 3},
    {'1': 'TASK_STATE_STUCK', '2': 4},
    {'1': 'TASK_STATE_DONE', '2': 5},
  ],
};

/// Descriptor for `TaskState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List taskStateDescriptor = $convert.base64Decode(
    'CglUYXNrU3RhdGUSGgoWVEFTS19TVEFURV9VTlNQRUNJRklFRBAAEhMKD1RBU0tfU1RBVEVfSU'
    'RMRRABEhYKElRBU0tfU1RBVEVfV09SS0lORxACEhYKElRBU0tfU1RBVEVfV0FJVElORxADEhQK'
    'EFRBU0tfU1RBVEVfU1RVQ0sQBBITCg9UQVNLX1NUQVRFX0RPTkUQBQ==');

@$core.Deprecated('Use ratingTargetDescriptor instead')
const RatingTarget$json = {
  '1': 'RatingTarget',
  '2': [
    {'1': 'RATING_TARGET_UNSPECIFIED', '2': 0},
    {'1': 'RATING_TARGET_TURN', '2': 1},
    {'1': 'RATING_TARGET_MODEL', '2': 2},
  ],
};

/// Descriptor for `RatingTarget`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List ratingTargetDescriptor = $convert.base64Decode(
    'CgxSYXRpbmdUYXJnZXQSHQoZUkFUSU5HX1RBUkdFVF9VTlNQRUNJRklFRBAAEhYKElJBVElOR1'
    '9UQVJHRVRfVFVSThABEhcKE1JBVElOR19UQVJHRVRfTU9ERUwQAg==');

@$core.Deprecated('Use ratingDescriptor instead')
const Rating$json = {
  '1': 'Rating',
  '2': [
    {'1': 'RATING_UNSPECIFIED', '2': 0},
    {'1': 'RATING_GOOD', '2': 1},
    {'1': 'RATING_BAD', '2': 2},
  ],
};

/// Descriptor for `Rating`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List ratingDescriptor = $convert.base64Decode(
    'CgZSYXRpbmcSFgoSUkFUSU5HX1VOU1BFQ0lGSUVEEAASDwoLUkFUSU5HX0dPT0QQARIOCgpSQV'
    'RJTkdfQkFEEAI=');

@$core.Deprecated('Use roleDescriptor instead')
const Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'ROLE_UNSPECIFIED', '2': 0},
    {'1': 'ROLE_USER', '2': 1},
    {'1': 'ROLE_ASSISTANT', '2': 2},
  ],
};

/// Descriptor for `Role`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List roleDescriptor = $convert.base64Decode(
    'CgRSb2xlEhQKEFJPTEVfVU5TUEVDSUZJRUQQABINCglST0xFX1VTRVIQARISCg5ST0xFX0FTU0'
    'lTVEFOVBAC');

@$core.Deprecated('Use promptDecisionDescriptor instead')
const PromptDecision$json = {
  '1': 'PromptDecision',
  '2': [
    {'1': 'PROMPT_DECISION_UNSPECIFIED', '2': 0},
    {'1': 'PROMPT_DECISION_ALLOW', '2': 1},
    {'1': 'PROMPT_DECISION_DENY', '2': 2},
    {'1': 'PROMPT_DECISION_ALLOW_SESSION', '2': 3},
  ],
};

/// Descriptor for `PromptDecision`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List promptDecisionDescriptor = $convert.base64Decode(
    'Cg5Qcm9tcHREZWNpc2lvbhIfChtQUk9NUFRfREVDSVNJT05fVU5TUEVDSUZJRUQQABIZChVQUk'
    '9NUFRfREVDSVNJT05fQUxMT1cQARIYChRQUk9NUFRfREVDSVNJT05fREVOWRACEiEKHVBST01Q'
    'VF9ERUNJU0lPTl9BTExPV19TRVNTSU9OEAM=');

@$core.Deprecated('Use todoStatusDescriptor instead')
const TodoStatus$json = {
  '1': 'TodoStatus',
  '2': [
    {'1': 'TODO_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'TODO_STATUS_PENDING', '2': 1},
    {'1': 'TODO_STATUS_IN_PROGRESS', '2': 2},
    {'1': 'TODO_STATUS_COMPLETED', '2': 3},
  ],
};

/// Descriptor for `TodoStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List todoStatusDescriptor = $convert.base64Decode(
    'CgpUb2RvU3RhdHVzEhsKF1RPRE9fU1RBVFVTX1VOU1BFQ0lGSUVEEAASFwoTVE9ET19TVEFUVV'
    'NfUEVORElORxABEhsKF1RPRE9fU1RBVFVTX0lOX1BST0dSRVNTEAISGQoVVE9ET19TVEFUVVNf'
    'Q09NUExFVEVEEAM=');

@$core.Deprecated('Use permissionVerdictDescriptor instead')
const PermissionVerdict$json = {
  '1': 'PermissionVerdict',
  '2': [
    {'1': 'PERMISSION_VERDICT_UNSPECIFIED', '2': 0},
    {'1': 'PERMISSION_VERDICT_SAFE', '2': 1},
    {'1': 'PERMISSION_VERDICT_ASK', '2': 2},
    {'1': 'PERMISSION_VERDICT_BLOCK', '2': 3},
    {'1': 'PERMISSION_VERDICT_ERROR', '2': 4},
  ],
};

/// Descriptor for `PermissionVerdict`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List permissionVerdictDescriptor = $convert.base64Decode(
    'ChFQZXJtaXNzaW9uVmVyZGljdBIiCh5QRVJNSVNTSU9OX1ZFUkRJQ1RfVU5TUEVDSUZJRUQQAB'
    'IbChdQRVJNSVNTSU9OX1ZFUkRJQ1RfU0FGRRABEhoKFlBFUk1JU1NJT05fVkVSRElDVF9BU0sQ'
    'AhIcChhQRVJNSVNTSU9OX1ZFUkRJQ1RfQkxPQ0sQAxIcChhQRVJNSVNTSU9OX1ZFUkRJQ1RfRV'
    'JST1IQBA==');

@$core.Deprecated('Use modelCallOutcomeDescriptor instead')
const ModelCallOutcome$json = {
  '1': 'ModelCallOutcome',
  '2': [
    {'1': 'MODEL_CALL_OUTCOME_UNSPECIFIED', '2': 0},
    {'1': 'MODEL_CALL_OUTCOME_OK', '2': 1},
    {'1': 'MODEL_CALL_OUTCOME_STALLED', '2': 2},
    {'1': 'MODEL_CALL_OUTCOME_ERROR', '2': 3},
    {'1': 'MODEL_CALL_OUTCOME_CANCELLED', '2': 4},
    {'1': 'MODEL_CALL_OUTCOME_RETRIED', '2': 5},
  ],
};

/// Descriptor for `ModelCallOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelCallOutcomeDescriptor = $convert.base64Decode(
    'ChBNb2RlbENhbGxPdXRjb21lEiIKHk1PREVMX0NBTExfT1VUQ09NRV9VTlNQRUNJRklFRBAAEh'
    'kKFU1PREVMX0NBTExfT1VUQ09NRV9PSxABEh4KGk1PREVMX0NBTExfT1VUQ09NRV9TVEFMTEVE'
    'EAISHAoYTU9ERUxfQ0FMTF9PVVRDT01FX0VSUk9SEAMSIAocTU9ERUxfQ0FMTF9PVVRDT01FX0'
    'NBTkNFTExFRBAEEh4KGk1PREVMX0NBTExfT1VUQ09NRV9SRVRSSUVEEAU=');

@$core.Deprecated('Use modelWaitReasonDescriptor instead')
const ModelWaitReason$json = {
  '1': 'ModelWaitReason',
  '2': [
    {'1': 'MODEL_WAIT_REASON_UNSPECIFIED', '2': 0},
    {'1': 'MODEL_WAIT_REASON_SLOTS_BUSY', '2': 1},
    {'1': 'MODEL_WAIT_REASON_SLEEPING', '2': 2},
    {'1': 'MODEL_WAIT_REASON_LOADING', '2': 3},
    {'1': 'MODEL_WAIT_REASON_CONCURRENCY_LIMIT', '2': 4},
  ],
};

/// Descriptor for `ModelWaitReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelWaitReasonDescriptor = $convert.base64Decode(
    'Cg9Nb2RlbFdhaXRSZWFzb24SIQodTU9ERUxfV0FJVF9SRUFTT05fVU5TUEVDSUZJRUQQABIgCh'
    'xNT0RFTF9XQUlUX1JFQVNPTl9TTE9UU19CVVNZEAESHgoaTU9ERUxfV0FJVF9SRUFTT05fU0xF'
    'RVBJTkcQAhIdChlNT0RFTF9XQUlUX1JFQVNPTl9MT0FESU5HEAMSJwojTU9ERUxfV0FJVF9SRU'
    'FTT05fQ09OQ1VSUkVOQ1lfTElNSVQQBA==');

@$core.Deprecated('Use promptCacheActionDescriptor instead')
const PromptCacheAction$json = {
  '1': 'PromptCacheAction',
  '2': [
    {'1': 'PROMPT_CACHE_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'PROMPT_CACHE_ACTION_SAVED', '2': 1},
    {'1': 'PROMPT_CACHE_ACTION_RESTORED', '2': 2},
    {'1': 'PROMPT_CACHE_ACTION_DISCARDED', '2': 3},
  ],
};

/// Descriptor for `PromptCacheAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List promptCacheActionDescriptor = $convert.base64Decode(
    'ChFQcm9tcHRDYWNoZUFjdGlvbhIjCh9QUk9NUFRfQ0FDSEVfQUNUSU9OX1VOU1BFQ0lGSUVEEA'
    'ASHQoZUFJPTVBUX0NBQ0hFX0FDVElPTl9TQVZFRBABEiAKHFBST01QVF9DQUNIRV9BQ1RJT05f'
    'UkVTVE9SRUQQAhIhCh1QUk9NUFRfQ0FDSEVfQUNUSU9OX0RJU0NBUkRFRBAD');

@$core.Deprecated('Use branchKindDescriptor instead')
const BranchKind$json = {
  '1': 'BranchKind',
  '2': [
    {'1': 'BRANCH_KIND_UNSPECIFIED', '2': 0},
    {'1': 'BRANCH_KIND_RETRY', '2': 1},
    {'1': 'BRANCH_KIND_EDIT', '2': 2},
  ],
};

/// Descriptor for `BranchKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List branchKindDescriptor = $convert.base64Decode(
    'CgpCcmFuY2hLaW5kEhsKF0JSQU5DSF9LSU5EX1VOU1BFQ0lGSUVEEAASFQoRQlJBTkNIX0tJTk'
    'RfUkVUUlkQARIUChBCUkFOQ0hfS0lORF9FRElUEAI=');

@$core.Deprecated('Use gitDiffBaseDescriptor instead')
const GitDiffBase$json = {
  '1': 'GitDiffBase',
  '2': [
    {'1': 'GIT_DIFF_BASE_UNSPECIFIED', '2': 0},
    {'1': 'GIT_DIFF_BASE_SESSION_START', '2': 1},
    {'1': 'GIT_DIFF_BASE_HEAD_NO_BASE', '2': 2},
    {'1': 'GIT_DIFF_BASE_HEAD_BASE_MISSING', '2': 3},
    {'1': 'GIT_DIFF_BASE_EMPTY_TREE', '2': 4},
  ],
};

/// Descriptor for `GitDiffBase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gitDiffBaseDescriptor = $convert.base64Decode(
    'CgtHaXREaWZmQmFzZRIdChlHSVRfRElGRl9CQVNFX1VOU1BFQ0lGSUVEEAASHwobR0lUX0RJRk'
    'ZfQkFTRV9TRVNTSU9OX1NUQVJUEAESHgoaR0lUX0RJRkZfQkFTRV9IRUFEX05PX0JBU0UQAhIj'
    'Ch9HSVRfRElGRl9CQVNFX0hFQURfQkFTRV9NSVNTSU5HEAMSHAoYR0lUX0RJRkZfQkFTRV9FTV'
    'BUWV9UUkVFEAQ=');

@$core.Deprecated('Use gitFileStatusDescriptor instead')
const GitFileStatus$json = {
  '1': 'GitFileStatus',
  '2': [
    {'1': 'GIT_FILE_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'GIT_FILE_STATUS_MODIFIED', '2': 1},
    {'1': 'GIT_FILE_STATUS_ADDED', '2': 2},
    {'1': 'GIT_FILE_STATUS_DELETED', '2': 3},
    {'1': 'GIT_FILE_STATUS_RENAMED', '2': 4},
    {'1': 'GIT_FILE_STATUS_COPIED', '2': 5},
    {'1': 'GIT_FILE_STATUS_TYPE_CHANGED', '2': 6},
    {'1': 'GIT_FILE_STATUS_UNMERGED', '2': 7},
  ],
};

/// Descriptor for `GitFileStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gitFileStatusDescriptor = $convert.base64Decode(
    'Cg1HaXRGaWxlU3RhdHVzEh8KG0dJVF9GSUxFX1NUQVRVU19VTlNQRUNJRklFRBAAEhwKGEdJVF'
    '9GSUxFX1NUQVRVU19NT0RJRklFRBABEhkKFUdJVF9GSUxFX1NUQVRVU19BRERFRBACEhsKF0dJ'
    'VF9GSUxFX1NUQVRVU19ERUxFVEVEEAMSGwoXR0lUX0ZJTEVfU1RBVFVTX1JFTkFNRUQQBBIaCh'
    'ZHSVRfRklMRV9TVEFUVVNfQ09QSUVEEAUSIAocR0lUX0ZJTEVfU1RBVFVTX1RZUEVfQ0hBTkdF'
    'RBAGEhwKGEdJVF9GSUxFX1NUQVRVU19VTk1FUkdFRBAH');

@$core.Deprecated('Use subagentKindDescriptor instead')
const SubagentKind$json = {
  '1': 'SubagentKind',
  '2': [
    {'1': 'SUBAGENT_KIND_UNSPECIFIED', '2': 0},
    {'1': 'SUBAGENT_KIND_EXPLORE', '2': 1},
    {'1': 'SUBAGENT_KIND_BUILD', '2': 2},
  ],
};

/// Descriptor for `SubagentKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List subagentKindDescriptor = $convert.base64Decode(
    'CgxTdWJhZ2VudEtpbmQSHQoZU1VCQUdFTlRfS0lORF9VTlNQRUNJRklFRBAAEhkKFVNVQkFHRU'
    '5UX0tJTkRfRVhQTE9SRRABEhcKE1NVQkFHRU5UX0tJTkRfQlVJTEQQAg==');

@$core.Deprecated('Use subagentOutcomeDescriptor instead')
const SubagentOutcome$json = {
  '1': 'SubagentOutcome',
  '2': [
    {'1': 'SUBAGENT_OUTCOME_UNSPECIFIED', '2': 0},
    {'1': 'SUBAGENT_OUTCOME_DONE', '2': 1},
    {'1': 'SUBAGENT_OUTCOME_STEP_LIMIT', '2': 2},
    {'1': 'SUBAGENT_OUTCOME_CANCELLED', '2': 3},
    {'1': 'SUBAGENT_OUTCOME_ERROR', '2': 4},
  ],
};

/// Descriptor for `SubagentOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List subagentOutcomeDescriptor = $convert.base64Decode(
    'Cg9TdWJhZ2VudE91dGNvbWUSIAocU1VCQUdFTlRfT1VUQ09NRV9VTlNQRUNJRklFRBAAEhkKFV'
    'NVQkFHRU5UX09VVENPTUVfRE9ORRABEh8KG1NVQkFHRU5UX09VVENPTUVfU1RFUF9MSU1JVBAC'
    'Eh4KGlNVQkFHRU5UX09VVENPTUVfQ0FOQ0VMTEVEEAMSGgoWU1VCQUdFTlRfT1VUQ09NRV9FUl'
    'JPUhAE');

@$core.Deprecated('Use sessionDescriptor instead')
const Session$json = {
  '1': 'Session',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'team_id', '3': 2, '4': 1, '5': 9, '10': 'teamId'},
    {'1': 'project_id', '3': 3, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'working_dir', '3': 5, '4': 1, '5': 9, '10': 'workingDir'},
    {'1': 'provider', '3': 6, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 7, '4': 1, '5': 9, '10': 'model'},
    {
      '1': 'state',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.TaskState',
      '10': 'state'
    },
    {'1': 'last_seq', '3': 9, '4': 1, '5': 3, '10': 'lastSeq'},
    {
      '1': 'create_time',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createTime'
    },
    {
      '1': 'update_time',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updateTime'
    },
    {'1': 'effort', '3': 12, '4': 1, '5': 9, '10': 'effort'},
    {'1': 'role', '3': 13, '4': 1, '5': 9, '10': 'role'},
    {'1': 'context_tokens', '3': 14, '4': 1, '5': 3, '10': 'contextTokens'},
    {'1': 'context_length', '3': 15, '4': 1, '5': 3, '10': 'contextLength'},
    {'1': 'mcp_servers', '3': 16, '4': 3, '5': 9, '10': 'mcpServers'},
    {'1': 'yolo', '3': 17, '4': 1, '5': 8, '10': 'yolo'},
    {'1': 'branch_id', '3': 18, '4': 1, '5': 9, '10': 'branchId'},
    {'1': 'base_commit', '3': 19, '4': 1, '5': 9, '10': 'baseCommit'},
    {'1': 'cron_job', '3': 20, '4': 1, '5': 9, '10': 'cronJob'},
    {'1': 'archived', '3': 21, '4': 1, '5': 8, '10': 'archived'},
    {'1': 'source_dir', '3': 22, '4': 1, '5': 9, '10': 'sourceDir'},
    {'1': 'worktree_path', '3': 23, '4': 1, '5': 9, '10': 'worktreePath'},
    {'1': 'worktree_branch', '3': 24, '4': 1, '5': 9, '10': 'worktreeBranch'},
    {'1': 'worktree_removed', '3': 25, '4': 1, '5': 8, '10': 'worktreeRemoved'},
    {'1': 'webhook', '3': 26, '4': 1, '5': 9, '10': 'webhook'},
  ],
};

/// Descriptor for `Session`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptor = $convert.base64Decode(
    'CgdTZXNzaW9uEg4KAmlkGAEgASgJUgJpZBIXCgd0ZWFtX2lkGAIgASgJUgZ0ZWFtSWQSHQoKcH'
    'JvamVjdF9pZBgDIAEoCVIJcHJvamVjdElkEhQKBXRpdGxlGAQgASgJUgV0aXRsZRIfCgt3b3Jr'
    'aW5nX2RpchgFIAEoCVIKd29ya2luZ0RpchIaCghwcm92aWRlchgGIAEoCVIIcHJvdmlkZXISFA'
    'oFbW9kZWwYByABKAlSBW1vZGVsEigKBXN0YXRlGAggASgOMhIuZmxpdC52MS5UYXNrU3RhdGVS'
    'BXN0YXRlEhkKCGxhc3Rfc2VxGAkgASgDUgdsYXN0U2VxEjsKC2NyZWF0ZV90aW1lGAogASgLMh'
    'ouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7Cgt1cGRhdGVfdGltZRgL'
    'IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWUSFgoGZWZmb3J0GA'
    'wgASgJUgZlZmZvcnQSEgoEcm9sZRgNIAEoCVIEcm9sZRIlCg5jb250ZXh0X3Rva2VucxgOIAEo'
    'A1INY29udGV4dFRva2VucxIlCg5jb250ZXh0X2xlbmd0aBgPIAEoA1INY29udGV4dExlbmd0aB'
    'IfCgttY3Bfc2VydmVycxgQIAMoCVIKbWNwU2VydmVycxISCgR5b2xvGBEgASgIUgR5b2xvEhsK'
    'CWJyYW5jaF9pZBgSIAEoCVIIYnJhbmNoSWQSHwoLYmFzZV9jb21taXQYEyABKAlSCmJhc2VDb2'
    '1taXQSGQoIY3Jvbl9qb2IYFCABKAlSB2Nyb25Kb2ISGgoIYXJjaGl2ZWQYFSABKAhSCGFyY2hp'
    'dmVkEh0KCnNvdXJjZV9kaXIYFiABKAlSCXNvdXJjZURpchIjCg13b3JrdHJlZV9wYXRoGBcgAS'
    'gJUgx3b3JrdHJlZVBhdGgSJwoPd29ya3RyZWVfYnJhbmNoGBggASgJUg53b3JrdHJlZUJyYW5j'
    'aBIpChB3b3JrdHJlZV9yZW1vdmVkGBkgASgIUg93b3JrdHJlZVJlbW92ZWQSGAoHd2ViaG9vax'
    'gaIAEoCVIHd2ViaG9vaw==');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'working_dir', '3': 1, '4': 1, '5': 9, '10': 'workingDir'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
    {'1': 'role', '3': 5, '4': 1, '5': 9, '10': 'role'},
    {'1': 'effort', '3': 6, '4': 1, '5': 9, '10': 'effort'},
    {'1': 'project_id', '3': 7, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'yolo', '3': 8, '4': 1, '5': 8, '9': 0, '10': 'yolo', '17': true},
  ],
  '8': [
    {'1': '_yolo'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBIfCgt3b3JraW5nX2RpchgBIAEoCVIKd29ya2luZ0Rpch'
    'IUCgV0aXRsZRgCIAEoCVIFdGl0bGUSGgoIcHJvdmlkZXIYAyABKAlSCHByb3ZpZGVyEhQKBW1v'
    'ZGVsGAQgASgJUgVtb2RlbBISCgRyb2xlGAUgASgJUgRyb2xlEhYKBmVmZm9ydBgGIAEoCVIGZW'
    'Zmb3J0Eh0KCnByb2plY3RfaWQYByABKAlSCXByb2plY3RJZBIXCgR5b2xvGAggASgISABSBHlv'
    'bG+IAQFCBwoFX3lvbG8=');

@$core.Deprecated('Use createSessionResponseDescriptor instead')
const CreateSessionResponse$json = {
  '1': 'CreateSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `CreateSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionResponseDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVTZXNzaW9uUmVzcG9uc2USKgoHc2Vzc2lvbhgBIAEoCzIQLmZsaXQudjEuU2Vzc2'
    'lvblIHc2Vzc2lvbg==');

@$core.Deprecated('Use listSessionsRequestDescriptor instead')
const ListSessionsRequest$json = {
  '1': 'ListSessionsRequest',
  '2': [
    {'1': 'page_size', '3': 1, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 2, '4': 1, '5': 9, '10': 'pageToken'},
    {'1': 'project_id', '3': 3, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'include_archived', '3': 4, '4': 1, '5': 8, '10': 'includeArchived'},
  ],
};

/// Descriptor for `ListSessionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0U2Vzc2lvbnNSZXF1ZXN0EhsKCXBhZ2Vfc2l6ZRgBIAEoBVIIcGFnZVNpemUSHQoKcG'
    'FnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEh0KCnByb2plY3RfaWQYAyABKAlSCXByb2plY3RJ'
    'ZBIpChBpbmNsdWRlX2FyY2hpdmVkGAQgASgIUg9pbmNsdWRlQXJjaGl2ZWQ=');

@$core.Deprecated('Use listSessionsResponseDescriptor instead')
const ListSessionsResponse$json = {
  '1': 'ListSessionsResponse',
  '2': [
    {
      '1': 'sessions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'sessions'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListSessionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0U2Vzc2lvbnNSZXNwb25zZRIsCghzZXNzaW9ucxgBIAMoCzIQLmZsaXQudjEuU2Vzc2'
    'lvblIIc2Vzc2lvbnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu');

@$core.Deprecated('Use getSessionRequestDescriptor instead')
const GetSessionRequest$json = {
  '1': 'GetSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionRequestDescriptor = $convert.base64Decode(
    'ChFHZXRTZXNzaW9uUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use getSessionResponseDescriptor instead')
const GetSessionResponse$json = {
  '1': 'GetSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `GetSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSessionResponseDescriptor = $convert.base64Decode(
    'ChJHZXRTZXNzaW9uUmVzcG9uc2USKgoHc2Vzc2lvbhgBIAEoCzIQLmZsaXQudjEuU2Vzc2lvbl'
    'IHc2Vzc2lvbg==');

@$core.Deprecated('Use attachRequestDescriptor instead')
const AttachRequest$json = {
  '1': 'AttachRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'from_seq', '3': 2, '4': 1, '5': 3, '10': 'fromSeq'},
  ],
};

/// Descriptor for `AttachRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachRequestDescriptor = $convert.base64Decode(
    'Cg1BdHRhY2hSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIZCghmcm9tX3'
    'NlcRgCIAEoA1IHZnJvbVNlcQ==');

@$core.Deprecated('Use attachResponseDescriptor instead')
const AttachResponse$json = {
  '1': 'AttachResponse',
  '2': [
    {
      '1': 'event',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Event',
      '10': 'event'
    },
  ],
};

/// Descriptor for `AttachResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachResponseDescriptor = $convert.base64Decode(
    'Cg5BdHRhY2hSZXNwb25zZRIkCgVldmVudBgBIAEoCzIOLmZsaXQudjEuRXZlbnRSBWV2ZW50');

@$core.Deprecated('Use sendRequestDescriptor instead')
const SendRequest$json = {
  '1': 'SendRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `SendRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendRequestDescriptor = $convert.base64Decode(
    'CgtTZW5kUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEgoEdGV4dBgCIA'
    'EoCVIEdGV4dBIWCgZjbGllbnQYAyABKAlSBmNsaWVudA==');

@$core.Deprecated('Use sendResponseDescriptor instead')
const SendResponse$json = {
  '1': 'SendResponse',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {'1': 'queue_id', '3': 2, '4': 1, '5': 9, '10': 'queueId'},
  ],
};

/// Descriptor for `SendResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendResponseDescriptor = $convert.base64Decode(
    'CgxTZW5kUmVzcG9uc2USEAoDc2VxGAEgASgDUgNzZXESGQoIcXVldWVfaWQYAiABKAlSB3F1ZX'
    'VlSWQ=');

@$core.Deprecated('Use editQueuedMessageRequestDescriptor instead')
const EditQueuedMessageRequest$json = {
  '1': 'EditQueuedMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'queue_id', '3': 2, '4': 1, '5': 9, '10': 'queueId'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `EditQueuedMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editQueuedMessageRequestDescriptor =
    $convert.base64Decode(
        'ChhFZGl0UXVldWVkTWVzc2FnZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbk'
        'lkEhkKCHF1ZXVlX2lkGAIgASgJUgdxdWV1ZUlkEhIKBHRleHQYAyABKAlSBHRleHQ=');

@$core.Deprecated('Use editQueuedMessageResponseDescriptor instead')
const EditQueuedMessageResponse$json = {
  '1': 'EditQueuedMessageResponse',
};

/// Descriptor for `EditQueuedMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editQueuedMessageResponseDescriptor =
    $convert.base64Decode('ChlFZGl0UXVldWVkTWVzc2FnZVJlc3BvbnNl');

@$core.Deprecated('Use cancelQueuedMessageRequestDescriptor instead')
const CancelQueuedMessageRequest$json = {
  '1': 'CancelQueuedMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'queue_id', '3': 2, '4': 1, '5': 9, '10': 'queueId'},
  ],
};

/// Descriptor for `CancelQueuedMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelQueuedMessageRequestDescriptor =
    $convert.base64Decode(
        'ChpDYW5jZWxRdWV1ZWRNZXNzYWdlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW'
        '9uSWQSGQoIcXVldWVfaWQYAiABKAlSB3F1ZXVlSWQ=');

@$core.Deprecated('Use cancelQueuedMessageResponseDescriptor instead')
const CancelQueuedMessageResponse$json = {
  '1': 'CancelQueuedMessageResponse',
};

/// Descriptor for `CancelQueuedMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelQueuedMessageResponseDescriptor =
    $convert.base64Decode('ChtDYW5jZWxRdWV1ZWRNZXNzYWdlUmVzcG9uc2U=');

@$core.Deprecated('Use interruptRequestDescriptor instead')
const InterruptRequest$json = {
  '1': 'InterruptRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `InterruptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List interruptRequestDescriptor = $convert.base64Decode(
    'ChBJbnRlcnJ1cHRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZA==');

@$core.Deprecated('Use interruptResponseDescriptor instead')
const InterruptResponse$json = {
  '1': 'InterruptResponse',
  '2': [
    {'1': 'interrupted', '3': 1, '4': 1, '5': 8, '10': 'interrupted'},
  ],
};

/// Descriptor for `InterruptResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List interruptResponseDescriptor = $convert.base64Decode(
    'ChFJbnRlcnJ1cHRSZXNwb25zZRIgCgtpbnRlcnJ1cHRlZBgBIAEoCFILaW50ZXJydXB0ZWQ=');

@$core.Deprecated('Use retryModelCallRequestDescriptor instead')
const RetryModelCallRequest$json = {
  '1': 'RetryModelCallRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `RetryModelCallRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List retryModelCallRequestDescriptor = $convert.base64Decode(
    'ChVSZXRyeU1vZGVsQ2FsbFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use retryModelCallResponseDescriptor instead')
const RetryModelCallResponse$json = {
  '1': 'RetryModelCallResponse',
};

/// Descriptor for `RetryModelCallResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List retryModelCallResponseDescriptor =
    $convert.base64Decode('ChZSZXRyeU1vZGVsQ2FsbFJlc3BvbnNl');

@$core.Deprecated('Use endReasoningRequestDescriptor instead')
const EndReasoningRequest$json = {
  '1': 'EndReasoningRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'client', '3': 2, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `EndReasoningRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endReasoningRequestDescriptor = $convert.base64Decode(
    'ChNFbmRSZWFzb25pbmdSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIWCg'
    'ZjbGllbnQYAiABKAlSBmNsaWVudA==');

@$core.Deprecated('Use endReasoningResponseDescriptor instead')
const EndReasoningResponse$json = {
  '1': 'EndReasoningResponse',
};

/// Descriptor for `EndReasoningResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endReasoningResponseDescriptor =
    $convert.base64Decode('ChRFbmRSZWFzb25pbmdSZXNwb25zZQ==');

@$core.Deprecated('Use compactRequestDescriptor instead')
const CompactRequest$json = {
  '1': 'CompactRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'client', '3': 2, '4': 1, '5': 9, '10': 'client'},
    {'1': 'instructions', '3': 3, '4': 1, '5': 9, '10': 'instructions'},
  ],
};

/// Descriptor for `CompactRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compactRequestDescriptor = $convert.base64Decode(
    'Cg5Db21wYWN0UmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFgoGY2xpZW'
    '50GAIgASgJUgZjbGllbnQSIgoMaW5zdHJ1Y3Rpb25zGAMgASgJUgxpbnN0cnVjdGlvbnM=');

@$core.Deprecated('Use compactResponseDescriptor instead')
const CompactResponse$json = {
  '1': 'CompactResponse',
  '2': [
    {'1': 'queued', '3': 1, '4': 1, '5': 8, '10': 'queued'},
  ],
};

/// Descriptor for `CompactResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compactResponseDescriptor = $convert
    .base64Decode('Cg9Db21wYWN0UmVzcG9uc2USFgoGcXVldWVkGAEgASgIUgZxdWV1ZWQ=');

@$core.Deprecated('Use answerPromptRequestDescriptor instead')
const AnswerPromptRequest$json = {
  '1': 'AnswerPromptRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'prompt_id', '3': 2, '4': 1, '5': 9, '10': 'promptId'},
    {
      '1': 'decision',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.PromptDecision',
      '10': 'decision'
    },
    {'1': 'client', '3': 4, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `AnswerPromptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List answerPromptRequestDescriptor = $convert.base64Decode(
    'ChNBbnN3ZXJQcm9tcHRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIbCg'
    'lwcm9tcHRfaWQYAiABKAlSCHByb21wdElkEjMKCGRlY2lzaW9uGAMgASgOMhcuZmxpdC52MS5Q'
    'cm9tcHREZWNpc2lvblIIZGVjaXNpb24SFgoGY2xpZW50GAQgASgJUgZjbGllbnQ=');

@$core.Deprecated('Use answerPromptResponseDescriptor instead')
const AnswerPromptResponse$json = {
  '1': 'AnswerPromptResponse',
};

/// Descriptor for `AnswerPromptResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List answerPromptResponseDescriptor =
    $convert.base64Decode('ChRBbnN3ZXJQcm9tcHRSZXNwb25zZQ==');

@$core.Deprecated('Use setModelRequestDescriptor instead')
const SetModelRequest$json = {
  '1': 'SetModelRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'provider', '3': 2, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 3, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `SetModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setModelRequestDescriptor = $convert.base64Decode(
    'Cg9TZXRNb2RlbFJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhoKCHByb3'
    'ZpZGVyGAIgASgJUghwcm92aWRlchIUCgVtb2RlbBgDIAEoCVIFbW9kZWw=');

@$core.Deprecated('Use setModelResponseDescriptor instead')
const SetModelResponse$json = {
  '1': 'SetModelResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setModelResponseDescriptor = $convert.base64Decode(
    'ChBTZXRNb2RlbFJlc3BvbnNlEioKB3Nlc3Npb24YASABKAsyEC5mbGl0LnYxLlNlc3Npb25SB3'
    'Nlc3Npb24=');

@$core.Deprecated('Use moveSessionRequestDescriptor instead')
const MoveSessionRequest$json = {
  '1': 'MoveSessionRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project_id', '3': 2, '4': 1, '5': 9, '10': 'projectId'},
  ],
};

/// Descriptor for `MoveSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveSessionRequestDescriptor = $convert.base64Decode(
    'ChJNb3ZlU2Vzc2lvblJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh0KCn'
    'Byb2plY3RfaWQYAiABKAlSCXByb2plY3RJZA==');

@$core.Deprecated('Use moveSessionResponseDescriptor instead')
const MoveSessionResponse$json = {
  '1': 'MoveSessionResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `MoveSessionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveSessionResponseDescriptor = $convert.base64Decode(
    'ChNNb3ZlU2Vzc2lvblJlc3BvbnNlEioKB3Nlc3Npb24YASABKAsyEC5mbGl0LnYxLlNlc3Npb2'
    '5SB3Nlc3Npb24=');

@$core.Deprecated('Use rateRequestDescriptor instead')
const RateRequest$json = {
  '1': 'RateRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'target',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.RatingTarget',
      '10': 'target'
    },
    {
      '1': 'rating',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.Rating',
      '10': 'rating'
    },
    {'1': 'message_id', '3': 4, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'note', '3': 5, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `RateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rateRequestDescriptor = $convert.base64Decode(
    'CgtSYXRlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSLQoGdGFyZ2V0GA'
    'IgASgOMhUuZmxpdC52MS5SYXRpbmdUYXJnZXRSBnRhcmdldBInCgZyYXRpbmcYAyABKA4yDy5m'
    'bGl0LnYxLlJhdGluZ1IGcmF0aW5nEh0KCm1lc3NhZ2VfaWQYBCABKAlSCW1lc3NhZ2VJZBISCg'
    'Rub3RlGAUgASgJUgRub3Rl');

@$core.Deprecated('Use rateResponseDescriptor instead')
const RateResponse$json = {
  '1': 'RateResponse',
};

/// Descriptor for `RateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rateResponseDescriptor =
    $convert.base64Decode('CgxSYXRlUmVzcG9uc2U=');

@$core.Deprecated('Use mcpServerDescriptor instead')
const McpServer$json = {
  '1': 'McpServer',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'running', '3': 3, '4': 1, '5': 8, '10': 'running'},
    {'1': 'tool_count', '3': 4, '4': 1, '5': 5, '10': 'toolCount'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `McpServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mcpServerDescriptor = $convert.base64Decode(
    'CglNY3BTZXJ2ZXISEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgdlbmFibGVkGAIgASgIUgdlbmFibG'
    'VkEhgKB3J1bm5pbmcYAyABKAhSB3J1bm5pbmcSHQoKdG9vbF9jb3VudBgEIAEoBVIJdG9vbENv'
    'dW50EhQKBWVycm9yGAUgASgJUgVlcnJvcg==');

@$core.Deprecated('Use listMcpServersRequestDescriptor instead')
const ListMcpServersRequest$json = {
  '1': 'ListMcpServersRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ListMcpServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMcpServersRequestDescriptor = $convert.base64Decode(
    'ChVMaXN0TWNwU2VydmVyc1JlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use listMcpServersResponseDescriptor instead')
const ListMcpServersResponse$json = {
  '1': 'ListMcpServersResponse',
  '2': [
    {
      '1': 'servers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.McpServer',
      '10': 'servers'
    },
  ],
};

/// Descriptor for `ListMcpServersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMcpServersResponseDescriptor =
    $convert.base64Decode(
        'ChZMaXN0TWNwU2VydmVyc1Jlc3BvbnNlEiwKB3NlcnZlcnMYASADKAsyEi5mbGl0LnYxLk1jcF'
        'NlcnZlclIHc2VydmVycw==');

@$core.Deprecated('Use skillDescriptor instead')
const Skill$json = {
  '1': 'Skill',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
  ],
};

/// Descriptor for `Skill`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillDescriptor = $convert.base64Decode(
    'CgVTa2lsbBISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZXNjcm'
    'lwdGlvbhIWCgZzb3VyY2UYAyABKAlSBnNvdXJjZQ==');

@$core.Deprecated('Use listSkillsRequestDescriptor instead')
const ListSkillsRequest$json = {
  '1': 'ListSkillsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ListSkillsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSkillsRequestDescriptor = $convert.base64Decode(
    'ChFMaXN0U2tpbGxzUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use listSkillsResponseDescriptor instead')
const ListSkillsResponse$json = {
  '1': 'ListSkillsResponse',
  '2': [
    {
      '1': 'skills',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Skill',
      '10': 'skills'
    },
  ],
};

/// Descriptor for `ListSkillsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSkillsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0U2tpbGxzUmVzcG9uc2USJgoGc2tpbGxzGAEgAygLMg4uZmxpdC52MS5Ta2lsbFIGc2'
    'tpbGxz');

@$core.Deprecated('Use setMcpServerRequestDescriptor instead')
const SetMcpServerRequest$json = {
  '1': 'SetMcpServerRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'server', '3': 2, '4': 1, '5': 9, '10': 'server'},
    {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SetMcpServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setMcpServerRequestDescriptor = $convert.base64Decode(
    'ChNTZXRNY3BTZXJ2ZXJSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIWCg'
    'ZzZXJ2ZXIYAiABKAlSBnNlcnZlchIYCgdlbmFibGVkGAMgASgIUgdlbmFibGVk');

@$core.Deprecated('Use retryFromMessageRequestDescriptor instead')
const RetryFromMessageRequest$json = {
  '1': 'RetryFromMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `RetryFromMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List retryFromMessageRequestDescriptor = $convert.base64Decode(
    'ChdSZXRyeUZyb21NZXNzYWdlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSW'
    'QSHQoKbWVzc2FnZV9pZBgCIAEoCVIJbWVzc2FnZUlkEhYKBmNsaWVudBgDIAEoCVIGY2xpZW50');

@$core.Deprecated('Use retryFromMessageResponseDescriptor instead')
const RetryFromMessageResponse$json = {
  '1': 'RetryFromMessageResponse',
  '2': [
    {'1': 'branch_id', '3': 1, '4': 1, '5': 9, '10': 'branchId'},
    {'1': 'seq', '3': 2, '4': 1, '5': 3, '10': 'seq'},
  ],
};

/// Descriptor for `RetryFromMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List retryFromMessageResponseDescriptor =
    $convert.base64Decode(
        'ChhSZXRyeUZyb21NZXNzYWdlUmVzcG9uc2USGwoJYnJhbmNoX2lkGAEgASgJUghicmFuY2hJZB'
        'IQCgNzZXEYAiABKANSA3NlcQ==');

@$core.Deprecated('Use editMessageRequestDescriptor instead')
const EditMessageRequest$json = {
  '1': 'EditMessageRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'client', '3': 4, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `EditMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editMessageRequestDescriptor = $convert.base64Decode(
    'ChJFZGl0TWVzc2FnZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh0KCm'
    '1lc3NhZ2VfaWQYAiABKAlSCW1lc3NhZ2VJZBISCgR0ZXh0GAMgASgJUgR0ZXh0EhYKBmNsaWVu'
    'dBgEIAEoCVIGY2xpZW50');

@$core.Deprecated('Use editMessageResponseDescriptor instead')
const EditMessageResponse$json = {
  '1': 'EditMessageResponse',
  '2': [
    {'1': 'branch_id', '3': 1, '4': 1, '5': 9, '10': 'branchId'},
    {'1': 'seq', '3': 2, '4': 1, '5': 3, '10': 'seq'},
  ],
};

/// Descriptor for `EditMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editMessageResponseDescriptor = $convert.base64Decode(
    'ChNFZGl0TWVzc2FnZVJlc3BvbnNlEhsKCWJyYW5jaF9pZBgBIAEoCVIIYnJhbmNoSWQSEAoDc2'
    'VxGAIgASgDUgNzZXE=');

@$core.Deprecated('Use switchBranchRequestDescriptor instead')
const SwitchBranchRequest$json = {
  '1': 'SwitchBranchRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'branch_id', '3': 2, '4': 1, '5': 9, '10': 'branchId'},
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `SwitchBranchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List switchBranchRequestDescriptor = $convert.base64Decode(
    'ChNTd2l0Y2hCcmFuY2hSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIbCg'
    'licmFuY2hfaWQYAiABKAlSCGJyYW5jaElkEhYKBmNsaWVudBgDIAEoCVIGY2xpZW50');

@$core.Deprecated('Use switchBranchResponseDescriptor instead')
const SwitchBranchResponse$json = {
  '1': 'SwitchBranchResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SwitchBranchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List switchBranchResponseDescriptor = $convert.base64Decode(
    'ChRTd2l0Y2hCcmFuY2hSZXNwb25zZRIqCgdzZXNzaW9uGAEgASgLMhAuZmxpdC52MS5TZXNzaW'
    '9uUgdzZXNzaW9u');

@$core.Deprecated('Use setMcpServerResponseDescriptor instead')
const SetMcpServerResponse$json = {
  '1': 'SetMcpServerResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetMcpServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setMcpServerResponseDescriptor = $convert.base64Decode(
    'ChRTZXRNY3BTZXJ2ZXJSZXNwb25zZRIqCgdzZXNzaW9uGAEgASgLMhAuZmxpdC52MS5TZXNzaW'
    '9uUgdzZXNzaW9u');

@$core.Deprecated('Use setEffortRequestDescriptor instead')
const SetEffortRequest$json = {
  '1': 'SetEffortRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'effort', '3': 2, '4': 1, '5': 9, '10': 'effort'},
  ],
};

/// Descriptor for `SetEffortRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setEffortRequestDescriptor = $convert.base64Decode(
    'ChBTZXRFZmZvcnRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBIWCgZlZm'
    'ZvcnQYAiABKAlSBmVmZm9ydA==');

@$core.Deprecated('Use setEffortResponseDescriptor instead')
const SetEffortResponse$json = {
  '1': 'SetEffortResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetEffortResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setEffortResponseDescriptor = $convert.base64Decode(
    'ChFTZXRFZmZvcnRSZXNwb25zZRIqCgdzZXNzaW9uGAEgASgLMhAuZmxpdC52MS5TZXNzaW9uUg'
    'dzZXNzaW9u');

@$core.Deprecated('Use setRoleRequestDescriptor instead')
const SetRoleRequest$json = {
  '1': 'SetRoleRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'role', '3': 2, '4': 1, '5': 9, '10': 'role'},
  ],
};

/// Descriptor for `SetRoleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRoleRequestDescriptor = $convert.base64Decode(
    'Cg5TZXRSb2xlUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEgoEcm9sZR'
    'gCIAEoCVIEcm9sZQ==');

@$core.Deprecated('Use setRoleResponseDescriptor instead')
const SetRoleResponse$json = {
  '1': 'SetRoleResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetRoleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRoleResponseDescriptor = $convert.base64Decode(
    'Cg9TZXRSb2xlUmVzcG9uc2USKgoHc2Vzc2lvbhgBIAEoCzIQLmZsaXQudjEuU2Vzc2lvblIHc2'
    'Vzc2lvbg==');

@$core.Deprecated('Use setYoloRequestDescriptor instead')
const SetYoloRequest$json = {
  '1': 'SetYoloRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'yolo', '3': 2, '4': 1, '5': 8, '10': 'yolo'},
  ],
};

/// Descriptor for `SetYoloRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setYoloRequestDescriptor = $convert.base64Decode(
    'Cg5TZXRZb2xvUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEgoEeW9sbx'
    'gCIAEoCFIEeW9sbw==');

@$core.Deprecated('Use setYoloResponseDescriptor instead')
const SetYoloResponse$json = {
  '1': 'SetYoloResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
  ],
};

/// Descriptor for `SetYoloResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setYoloResponseDescriptor = $convert.base64Decode(
    'Cg9TZXRZb2xvUmVzcG9uc2USKgoHc2Vzc2lvbhgBIAEoCzIQLmZsaXQudjEuU2Vzc2lvblIHc2'
    'Vzc2lvbg==');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'seq', '3': 2, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'time',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'time'
    },
    {'1': 'branch_id', '3': 4, '4': 1, '5': 9, '10': 'branchId'},
    {
      '1': 'message_started',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.MessageStarted',
      '9': 0,
      '10': 'messageStarted'
    },
    {
      '1': 'text_delta',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.TextDelta',
      '9': 0,
      '10': 'textDelta'
    },
    {
      '1': 'reasoning_delta',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ReasoningDelta',
      '9': 0,
      '10': 'reasoningDelta'
    },
    {
      '1': 'message_done',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.MessageDone',
      '9': 0,
      '10': 'messageDone'
    },
    {
      '1': 'tool_call_started',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ToolCallStarted',
      '9': 0,
      '10': 'toolCallStarted'
    },
    {
      '1': 'tool_output',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ToolOutput',
      '9': 0,
      '10': 'toolOutput'
    },
    {
      '1': 'tool_call_done',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ToolCallDone',
      '9': 0,
      '10': 'toolCallDone'
    },
    {
      '1': 'prompt_requested',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.PromptRequested',
      '9': 0,
      '10': 'promptRequested'
    },
    {
      '1': 'prompt_resolved',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.PromptResolved',
      '9': 0,
      '10': 'promptResolved'
    },
    {
      '1': 'task_state_changed',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.TaskStateChanged',
      '9': 0,
      '10': 'taskStateChanged'
    },
    {
      '1': 'model_changed',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ModelChanged',
      '9': 0,
      '10': 'modelChanged'
    },
    {
      '1': 'usage',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Usage',
      '9': 0,
      '10': 'usage'
    },
    {
      '1': 'error',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.TurnError',
      '9': 0,
      '10': 'error'
    },
    {
      '1': 'todo_updated',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.TodoUpdated',
      '9': 0,
      '10': 'todoUpdated'
    },
    {
      '1': 'feedback',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Feedback',
      '9': 0,
      '10': 'feedback'
    },
    {
      '1': 'mcp_servers_changed',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.McpServersChanged',
      '9': 0,
      '10': 'mcpServersChanged'
    },
    {
      '1': 'session_moved',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.SessionMoved',
      '9': 0,
      '10': 'sessionMoved'
    },
    {
      '1': 'yolo_changed',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.YoloChanged',
      '9': 0,
      '10': 'yoloChanged'
    },
    {
      '1': 'permission_check',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.PermissionCheck',
      '9': 0,
      '10': 'permissionCheck'
    },
    {
      '1': 'model_call_started',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ModelCallStarted',
      '9': 0,
      '10': 'modelCallStarted'
    },
    {
      '1': 'prompt_progress',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.PromptProgress',
      '9': 0,
      '10': 'promptProgress'
    },
    {
      '1': 'model_call_ended',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ModelCallEnded',
      '9': 0,
      '10': 'modelCallEnded'
    },
    {
      '1': 'message_queued',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.MessageQueued',
      '9': 0,
      '10': 'messageQueued'
    },
    {
      '1': 'queued_message_updated',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.QueuedMessageUpdated',
      '9': 0,
      '10': 'queuedMessageUpdated'
    },
    {
      '1': 'queued_message_delivered',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.QueuedMessageDelivered',
      '9': 0,
      '10': 'queuedMessageDelivered'
    },
    {
      '1': 'model_call_waiting',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ModelCallWaiting',
      '9': 0,
      '10': 'modelCallWaiting'
    },
    {
      '1': 'prompt_cache',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.PromptCache',
      '9': 0,
      '10': 'promptCache'
    },
    {
      '1': 'reasoning_end_requested',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ReasoningEndRequested',
      '9': 0,
      '10': 'reasoningEndRequested'
    },
    {
      '1': 'reasoning_end_ignored',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ReasoningEndIgnored',
      '9': 0,
      '10': 'reasoningEndIgnored'
    },
    {
      '1': 'compaction_started',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.CompactionStarted',
      '9': 0,
      '10': 'compactionStarted'
    },
    {
      '1': 'compaction_done',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.CompactionDone',
      '9': 0,
      '10': 'compactionDone'
    },
    {
      '1': 'branch_created',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.BranchCreated',
      '9': 0,
      '10': 'branchCreated'
    },
    {
      '1': 'branch_switched',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.BranchSwitched',
      '9': 0,
      '10': 'branchSwitched'
    },
    {
      '1': 'cron_run',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.CronRunStarted',
      '9': 0,
      '10': 'cronRun'
    },
    {
      '1': 'subagent_started',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.SubagentStarted',
      '9': 0,
      '10': 'subagentStarted'
    },
    {
      '1': 'subagent_event',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.SubagentEvent',
      '9': 0,
      '10': 'subagentEvent'
    },
    {
      '1': 'subagent_done',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.SubagentDone',
      '9': 0,
      '10': 'subagentDone'
    },
    {
      '1': 'worktree_created',
      '3': 47,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.WorktreeCreated',
      '9': 0,
      '10': 'worktreeCreated'
    },
    {
      '1': 'worktree_skipped',
      '3': 48,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.WorktreeSkipped',
      '9': 0,
      '10': 'worktreeSkipped'
    },
    {
      '1': 'worktree_removed',
      '3': 49,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.WorktreeRemoved',
      '9': 0,
      '10': 'worktreeRemoved'
    },
    {
      '1': 'worktree_kept',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.WorktreeKept',
      '9': 0,
      '10': 'worktreeKept'
    },
    {
      '1': 'webhook_run',
      '3': 51,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.WebhookRunStarted',
      '9': 0,
      '10': 'webhookRun'
    },
    {
      '1': 'role_changed',
      '3': 52,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.RoleChanged',
      '9': 0,
      '10': 'roleChanged'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEAoDc2VxGAIgASgDUgNzZX'
    'ESLgoEdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBHRpbWUSGwoJYnJh'
    'bmNoX2lkGAQgASgJUghicmFuY2hJZBJCCg9tZXNzYWdlX3N0YXJ0ZWQYCiABKAsyFy5mbGl0Ln'
    'YxLk1lc3NhZ2VTdGFydGVkSABSDm1lc3NhZ2VTdGFydGVkEjMKCnRleHRfZGVsdGEYCyABKAsy'
    'Ei5mbGl0LnYxLlRleHREZWx0YUgAUgl0ZXh0RGVsdGESQgoPcmVhc29uaW5nX2RlbHRhGAwgAS'
    'gLMhcuZmxpdC52MS5SZWFzb25pbmdEZWx0YUgAUg5yZWFzb25pbmdEZWx0YRI5CgxtZXNzYWdl'
    'X2RvbmUYDSABKAsyFC5mbGl0LnYxLk1lc3NhZ2VEb25lSABSC21lc3NhZ2VEb25lEkYKEXRvb2'
    'xfY2FsbF9zdGFydGVkGA4gASgLMhguZmxpdC52MS5Ub29sQ2FsbFN0YXJ0ZWRIAFIPdG9vbENh'
    'bGxTdGFydGVkEjYKC3Rvb2xfb3V0cHV0GA8gASgLMhMuZmxpdC52MS5Ub29sT3V0cHV0SABSCn'
    'Rvb2xPdXRwdXQSPQoOdG9vbF9jYWxsX2RvbmUYECABKAsyFS5mbGl0LnYxLlRvb2xDYWxsRG9u'
    'ZUgAUgx0b29sQ2FsbERvbmUSRQoQcHJvbXB0X3JlcXVlc3RlZBgRIAEoCzIYLmZsaXQudjEuUH'
    'JvbXB0UmVxdWVzdGVkSABSD3Byb21wdFJlcXVlc3RlZBJCCg9wcm9tcHRfcmVzb2x2ZWQYEiAB'
    'KAsyFy5mbGl0LnYxLlByb21wdFJlc29sdmVkSABSDnByb21wdFJlc29sdmVkEkkKEnRhc2tfc3'
    'RhdGVfY2hhbmdlZBgTIAEoCzIZLmZsaXQudjEuVGFza1N0YXRlQ2hhbmdlZEgAUhB0YXNrU3Rh'
    'dGVDaGFuZ2VkEjwKDW1vZGVsX2NoYW5nZWQYFCABKAsyFS5mbGl0LnYxLk1vZGVsQ2hhbmdlZE'
    'gAUgxtb2RlbENoYW5nZWQSJgoFdXNhZ2UYFSABKAsyDi5mbGl0LnYxLlVzYWdlSABSBXVzYWdl'
    'EioKBWVycm9yGBYgASgLMhIuZmxpdC52MS5UdXJuRXJyb3JIAFIFZXJyb3ISOQoMdG9kb191cG'
    'RhdGVkGBcgASgLMhQuZmxpdC52MS5Ub2RvVXBkYXRlZEgAUgt0b2RvVXBkYXRlZBIvCghmZWVk'
    'YmFjaxgYIAEoCzIRLmZsaXQudjEuRmVlZGJhY2tIAFIIZmVlZGJhY2sSTAoTbWNwX3NlcnZlcn'
    'NfY2hhbmdlZBgZIAEoCzIaLmZsaXQudjEuTWNwU2VydmVyc0NoYW5nZWRIAFIRbWNwU2VydmVy'
    'c0NoYW5nZWQSPAoNc2Vzc2lvbl9tb3ZlZBgaIAEoCzIVLmZsaXQudjEuU2Vzc2lvbk1vdmVkSA'
    'BSDHNlc3Npb25Nb3ZlZBI5Cgx5b2xvX2NoYW5nZWQYGyABKAsyFC5mbGl0LnYxLllvbG9DaGFu'
    'Z2VkSABSC3lvbG9DaGFuZ2VkEkUKEHBlcm1pc3Npb25fY2hlY2sYHCABKAsyGC5mbGl0LnYxLl'
    'Blcm1pc3Npb25DaGVja0gAUg9wZXJtaXNzaW9uQ2hlY2sSSQoSbW9kZWxfY2FsbF9zdGFydGVk'
    'GB0gASgLMhkuZmxpdC52MS5Nb2RlbENhbGxTdGFydGVkSABSEG1vZGVsQ2FsbFN0YXJ0ZWQSQg'
    'oPcHJvbXB0X3Byb2dyZXNzGB4gASgLMhcuZmxpdC52MS5Qcm9tcHRQcm9ncmVzc0gAUg5wcm9t'
    'cHRQcm9ncmVzcxJDChBtb2RlbF9jYWxsX2VuZGVkGB8gASgLMhcuZmxpdC52MS5Nb2RlbENhbG'
    'xFbmRlZEgAUg5tb2RlbENhbGxFbmRlZBI/Cg5tZXNzYWdlX3F1ZXVlZBggIAEoCzIWLmZsaXQu'
    'djEuTWVzc2FnZVF1ZXVlZEgAUg1tZXNzYWdlUXVldWVkElUKFnF1ZXVlZF9tZXNzYWdlX3VwZG'
    'F0ZWQYISABKAsyHS5mbGl0LnYxLlF1ZXVlZE1lc3NhZ2VVcGRhdGVkSABSFHF1ZXVlZE1lc3Nh'
    'Z2VVcGRhdGVkElsKGHF1ZXVlZF9tZXNzYWdlX2RlbGl2ZXJlZBgiIAEoCzIfLmZsaXQudjEuUX'
    'VldWVkTWVzc2FnZURlbGl2ZXJlZEgAUhZxdWV1ZWRNZXNzYWdlRGVsaXZlcmVkEkkKEm1vZGVs'
    'X2NhbGxfd2FpdGluZxgjIAEoCzIZLmZsaXQudjEuTW9kZWxDYWxsV2FpdGluZ0gAUhBtb2RlbE'
    'NhbGxXYWl0aW5nEjkKDHByb21wdF9jYWNoZRgkIAEoCzIULmZsaXQudjEuUHJvbXB0Q2FjaGVI'
    'AFILcHJvbXB0Q2FjaGUSWAoXcmVhc29uaW5nX2VuZF9yZXF1ZXN0ZWQYJSABKAsyHi5mbGl0Ln'
    'YxLlJlYXNvbmluZ0VuZFJlcXVlc3RlZEgAUhVyZWFzb25pbmdFbmRSZXF1ZXN0ZWQSUgoVcmVh'
    'c29uaW5nX2VuZF9pZ25vcmVkGCYgASgLMhwuZmxpdC52MS5SZWFzb25pbmdFbmRJZ25vcmVkSA'
    'BSE3JlYXNvbmluZ0VuZElnbm9yZWQSSwoSY29tcGFjdGlvbl9zdGFydGVkGCcgASgLMhouZmxp'
    'dC52MS5Db21wYWN0aW9uU3RhcnRlZEgAUhFjb21wYWN0aW9uU3RhcnRlZBJCCg9jb21wYWN0aW'
    '9uX2RvbmUYKCABKAsyFy5mbGl0LnYxLkNvbXBhY3Rpb25Eb25lSABSDmNvbXBhY3Rpb25Eb25l'
    'Ej8KDmJyYW5jaF9jcmVhdGVkGCkgASgLMhYuZmxpdC52MS5CcmFuY2hDcmVhdGVkSABSDWJyYW'
    '5jaENyZWF0ZWQSQgoPYnJhbmNoX3N3aXRjaGVkGCogASgLMhcuZmxpdC52MS5CcmFuY2hTd2l0'
    'Y2hlZEgAUg5icmFuY2hTd2l0Y2hlZBI0Cghjcm9uX3J1bhgrIAEoCzIXLmZsaXQudjEuQ3Jvbl'
    'J1blN0YXJ0ZWRIAFIHY3JvblJ1bhJFChBzdWJhZ2VudF9zdGFydGVkGCwgASgLMhguZmxpdC52'
    'MS5TdWJhZ2VudFN0YXJ0ZWRIAFIPc3ViYWdlbnRTdGFydGVkEj8KDnN1YmFnZW50X2V2ZW50GC'
    '0gASgLMhYuZmxpdC52MS5TdWJhZ2VudEV2ZW50SABSDXN1YmFnZW50RXZlbnQSPAoNc3ViYWdl'
    'bnRfZG9uZRguIAEoCzIVLmZsaXQudjEuU3ViYWdlbnREb25lSABSDHN1YmFnZW50RG9uZRJFCh'
    'B3b3JrdHJlZV9jcmVhdGVkGC8gASgLMhguZmxpdC52MS5Xb3JrdHJlZUNyZWF0ZWRIAFIPd29y'
    'a3RyZWVDcmVhdGVkEkUKEHdvcmt0cmVlX3NraXBwZWQYMCABKAsyGC5mbGl0LnYxLldvcmt0cm'
    'VlU2tpcHBlZEgAUg93b3JrdHJlZVNraXBwZWQSRQoQd29ya3RyZWVfcmVtb3ZlZBgxIAEoCzIY'
    'LmZsaXQudjEuV29ya3RyZWVSZW1vdmVkSABSD3dvcmt0cmVlUmVtb3ZlZBI8Cg13b3JrdHJlZV'
    '9rZXB0GDIgASgLMhUuZmxpdC52MS5Xb3JrdHJlZUtlcHRIAFIMd29ya3RyZWVLZXB0Ej0KC3dl'
    'Ymhvb2tfcnVuGDMgASgLMhouZmxpdC52MS5XZWJob29rUnVuU3RhcnRlZEgAUgp3ZWJob29rUn'
    'VuEjkKDHJvbGVfY2hhbmdlZBg0IAEoCzIULmZsaXQudjEuUm9sZUNoYW5nZWRIAFILcm9sZUNo'
    'YW5nZWRCCQoHcGF5bG9hZA==');

@$core.Deprecated('Use messageStartedDescriptor instead')
const MessageStarted$json = {
  '1': 'MessageStarted',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'role', '3': 2, '4': 1, '5': 14, '6': '.flit.v1.Role', '10': 'role'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `MessageStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageStartedDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdlU3RhcnRlZBIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSIQoEcm9sZR'
    'gCIAEoDjINLmZsaXQudjEuUm9sZVIEcm9sZRIaCghwcm92aWRlchgDIAEoCVIIcHJvdmlkZXIS'
    'FAoFbW9kZWwYBCABKAlSBW1vZGVs');

@$core.Deprecated('Use textDeltaDescriptor instead')
const TextDelta$json = {
  '1': 'TextDelta',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `TextDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textDeltaDescriptor = $convert.base64Decode(
    'CglUZXh0RGVsdGESHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEhIKBHRleHQYAiABKA'
    'lSBHRleHQ=');

@$core.Deprecated('Use reasoningDeltaDescriptor instead')
const ReasoningDelta$json = {
  '1': 'ReasoningDelta',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `ReasoningDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasoningDeltaDescriptor = $convert.base64Decode(
    'Cg5SZWFzb25pbmdEZWx0YRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSEgoEdGV4dB'
    'gCIAEoCVIEdGV4dA==');

@$core.Deprecated('Use messageDoneDescriptor instead')
const MessageDone$json = {
  '1': 'MessageDone',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'reasoning', '3': 3, '4': 1, '5': 9, '10': 'reasoning'},
    {'1': 'finish_reason', '3': 4, '4': 1, '5': 9, '10': 'finishReason'},
  ],
};

/// Descriptor for `MessageDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDoneDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlRG9uZRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSEgoEdGV4dBgCIA'
    'EoCVIEdGV4dBIcCglyZWFzb25pbmcYAyABKAlSCXJlYXNvbmluZxIjCg1maW5pc2hfcmVhc29u'
    'GAQgASgJUgxmaW5pc2hSZWFzb24=');

@$core.Deprecated('Use toolCallStartedDescriptor instead')
const ToolCallStarted$json = {
  '1': 'ToolCallStarted',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'tool_call_id', '3': 2, '4': 1, '5': 9, '10': 'toolCallId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'arguments', '3': 4, '4': 1, '5': 9, '10': 'arguments'},
  ],
};

/// Descriptor for `ToolCallStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolCallStartedDescriptor = $convert.base64Decode(
    'Cg9Ub29sQ2FsbFN0YXJ0ZWQSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEiAKDHRvb2'
    'xfY2FsbF9pZBgCIAEoCVIKdG9vbENhbGxJZBISCgRuYW1lGAMgASgJUgRuYW1lEhwKCWFyZ3Vt'
    'ZW50cxgEIAEoCVIJYXJndW1lbnRz');

@$core.Deprecated('Use toolOutputDescriptor instead')
const ToolOutput$json = {
  '1': 'ToolOutput',
  '2': [
    {'1': 'tool_call_id', '3': 1, '4': 1, '5': 9, '10': 'toolCallId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `ToolOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolOutputDescriptor = $convert.base64Decode(
    'CgpUb29sT3V0cHV0EiAKDHRvb2xfY2FsbF9pZBgBIAEoCVIKdG9vbENhbGxJZBISCgR0ZXh0GA'
    'IgASgJUgR0ZXh0');

@$core.Deprecated('Use toolCallDoneDescriptor instead')
const ToolCallDone$json = {
  '1': 'ToolCallDone',
  '2': [
    {'1': 'tool_call_id', '3': 1, '4': 1, '5': 9, '10': 'toolCallId'},
    {'1': 'result', '3': 2, '4': 1, '5': 9, '10': 'result'},
    {'1': 'is_error', '3': 3, '4': 1, '5': 8, '10': 'isError'},
    {'1': 'truncated', '3': 4, '4': 1, '5': 8, '10': 'truncated'},
    {'1': 'omitted_bytes', '3': 5, '4': 1, '5': 3, '10': 'omittedBytes'},
  ],
};

/// Descriptor for `ToolCallDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List toolCallDoneDescriptor = $convert.base64Decode(
    'CgxUb29sQ2FsbERvbmUSIAoMdG9vbF9jYWxsX2lkGAEgASgJUgp0b29sQ2FsbElkEhYKBnJlc3'
    'VsdBgCIAEoCVIGcmVzdWx0EhkKCGlzX2Vycm9yGAMgASgIUgdpc0Vycm9yEhwKCXRydW5jYXRl'
    'ZBgEIAEoCFIJdHJ1bmNhdGVkEiMKDW9taXR0ZWRfYnl0ZXMYBSABKANSDG9taXR0ZWRCeXRlcw'
    '==');

@$core.Deprecated('Use promptRequestedDescriptor instead')
const PromptRequested$json = {
  '1': 'PromptRequested',
  '2': [
    {'1': 'prompt_id', '3': 1, '4': 1, '5': 9, '10': 'promptId'},
    {'1': 'tool_call_id', '3': 2, '4': 1, '5': 9, '10': 'toolCallId'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'detail', '3': 4, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'session_patterns', '3': 5, '4': 3, '5': 9, '10': 'sessionPatterns'},
    {'1': 'safety_reason', '3': 6, '4': 1, '5': 9, '10': 'safetyReason'},
  ],
};

/// Descriptor for `PromptRequested`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptRequestedDescriptor = $convert.base64Decode(
    'Cg9Qcm9tcHRSZXF1ZXN0ZWQSGwoJcHJvbXB0X2lkGAEgASgJUghwcm9tcHRJZBIgCgx0b29sX2'
    'NhbGxfaWQYAiABKAlSCnRvb2xDYWxsSWQSFAoFdGl0bGUYAyABKAlSBXRpdGxlEhYKBmRldGFp'
    'bBgEIAEoCVIGZGV0YWlsEikKEHNlc3Npb25fcGF0dGVybnMYBSADKAlSD3Nlc3Npb25QYXR0ZX'
    'JucxIjCg1zYWZldHlfcmVhc29uGAYgASgJUgxzYWZldHlSZWFzb24=');

@$core.Deprecated('Use promptResolvedDescriptor instead')
const PromptResolved$json = {
  '1': 'PromptResolved',
  '2': [
    {'1': 'prompt_id', '3': 1, '4': 1, '5': 9, '10': 'promptId'},
    {
      '1': 'decision',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.PromptDecision',
      '10': 'decision'
    },
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
    {'1': 'reason', '3': 4, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'session_patterns', '3': 5, '4': 3, '5': 9, '10': 'sessionPatterns'},
  ],
};

/// Descriptor for `PromptResolved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptResolvedDescriptor = $convert.base64Decode(
    'Cg5Qcm9tcHRSZXNvbHZlZBIbCglwcm9tcHRfaWQYASABKAlSCHByb21wdElkEjMKCGRlY2lzaW'
    '9uGAIgASgOMhcuZmxpdC52MS5Qcm9tcHREZWNpc2lvblIIZGVjaXNpb24SFgoGY2xpZW50GAMg'
    'ASgJUgZjbGllbnQSFgoGcmVhc29uGAQgASgJUgZyZWFzb24SKQoQc2Vzc2lvbl9wYXR0ZXJucx'
    'gFIAMoCVIPc2Vzc2lvblBhdHRlcm5z');

@$core.Deprecated('Use taskStateChangedDescriptor instead')
const TaskStateChanged$json = {
  '1': 'TaskStateChanged',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.TaskState',
      '10': 'state'
    },
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `TaskStateChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskStateChangedDescriptor = $convert.base64Decode(
    'ChBUYXNrU3RhdGVDaGFuZ2VkEigKBXN0YXRlGAEgASgOMhIuZmxpdC52MS5UYXNrU3RhdGVSBX'
    'N0YXRlEhYKBnJlYXNvbhgCIAEoCVIGcmVhc29u');

@$core.Deprecated('Use modelChangedDescriptor instead')
const ModelChanged$json = {
  '1': 'ModelChanged',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
    {'1': 'effort', '3': 3, '4': 1, '5': 9, '10': 'effort'},
    {'1': 'context_length', '3': 4, '4': 1, '5': 3, '10': 'contextLength'},
  ],
};

/// Descriptor for `ModelChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelChangedDescriptor = $convert.base64Decode(
    'CgxNb2RlbENoYW5nZWQSGgoIcHJvdmlkZXIYASABKAlSCHByb3ZpZGVyEhQKBW1vZGVsGAIgAS'
    'gJUgVtb2RlbBIWCgZlZmZvcnQYAyABKAlSBmVmZm9ydBIlCg5jb250ZXh0X2xlbmd0aBgEIAEo'
    'A1INY29udGV4dExlbmd0aA==');

@$core.Deprecated('Use roleChangedDescriptor instead')
const RoleChanged$json = {
  '1': 'RoleChanged',
  '2': [
    {'1': 'role', '3': 1, '4': 1, '5': 9, '10': 'role'},
    {'1': 'previous_role', '3': 2, '4': 1, '5': 9, '10': 'previousRole'},
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `RoleChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleChangedDescriptor = $convert.base64Decode(
    'CgtSb2xlQ2hhbmdlZBISCgRyb2xlGAEgASgJUgRyb2xlEiMKDXByZXZpb3VzX3JvbGUYAiABKA'
    'lSDHByZXZpb3VzUm9sZRIWCgZjbGllbnQYAyABKAlSBmNsaWVudA==');

@$core.Deprecated('Use usageDescriptor instead')
const Usage$json = {
  '1': 'Usage',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'input_tokens', '3': 2, '4': 1, '5': 3, '10': 'inputTokens'},
    {'1': 'output_tokens', '3': 3, '4': 1, '5': 3, '10': 'outputTokens'},
    {'1': 'total_tokens', '3': 4, '4': 1, '5': 3, '10': 'totalTokens'},
    {'1': 'context_length', '3': 5, '4': 1, '5': 3, '10': 'contextLength'},
    {
      '1': 'time_to_first_token_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'timeToFirstTokenMs'
    },
    {
      '1': 'prompt_tokens_per_second',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'promptTokensPerSecond'
    },
    {
      '1': 'generation_tokens_per_second',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'generationTokensPerSecond'
    },
    {'1': 'timing_source', '3': 9, '4': 1, '5': 9, '10': 'timingSource'},
    {'1': 'cached_tokens', '3': 10, '4': 1, '5': 3, '10': 'cachedTokens'},
  ],
};

/// Descriptor for `Usage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List usageDescriptor = $convert.base64Decode(
    'CgVVc2FnZRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSIQoMaW5wdXRfdG9rZW5zGA'
    'IgASgDUgtpbnB1dFRva2VucxIjCg1vdXRwdXRfdG9rZW5zGAMgASgDUgxvdXRwdXRUb2tlbnMS'
    'IQoMdG90YWxfdG9rZW5zGAQgASgDUgt0b3RhbFRva2VucxIlCg5jb250ZXh0X2xlbmd0aBgFIA'
    'EoA1INY29udGV4dExlbmd0aBIyChZ0aW1lX3RvX2ZpcnN0X3Rva2VuX21zGAYgASgDUhJ0aW1l'
    'VG9GaXJzdFRva2VuTXMSNwoYcHJvbXB0X3Rva2Vuc19wZXJfc2Vjb25kGAcgASgBUhVwcm9tcH'
    'RUb2tlbnNQZXJTZWNvbmQSPwocZ2VuZXJhdGlvbl90b2tlbnNfcGVyX3NlY29uZBgIIAEoAVIZ'
    'Z2VuZXJhdGlvblRva2Vuc1BlclNlY29uZBIjCg10aW1pbmdfc291cmNlGAkgASgJUgx0aW1pbm'
    'dTb3VyY2USIwoNY2FjaGVkX3Rva2VucxgKIAEoA1IMY2FjaGVkVG9rZW5z');

@$core.Deprecated('Use todoUpdatedDescriptor instead')
const TodoUpdated$json = {
  '1': 'TodoUpdated',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.TodoItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `TodoUpdated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List todoUpdatedDescriptor = $convert.base64Decode(
    'CgtUb2RvVXBkYXRlZBInCgVpdGVtcxgBIAMoCzIRLmZsaXQudjEuVG9kb0l0ZW1SBWl0ZW1z');

@$core.Deprecated('Use todoItemDescriptor instead')
const TodoItem$json = {
  '1': 'TodoItem',
  '2': [
    {'1': 'content', '3': 1, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.TodoStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `TodoItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List todoItemDescriptor = $convert.base64Decode(
    'CghUb2RvSXRlbRIYCgdjb250ZW50GAEgASgJUgdjb250ZW50EisKBnN0YXR1cxgCIAEoDjITLm'
    'ZsaXQudjEuVG9kb1N0YXR1c1IGc3RhdHVz');

@$core.Deprecated('Use turnErrorDescriptor instead')
const TurnError$json = {
  '1': 'TurnError',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'turn_can_continue', '3': 2, '4': 1, '5': 8, '10': 'turnCanContinue'},
  ],
};

/// Descriptor for `TurnError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List turnErrorDescriptor = $convert.base64Decode(
    'CglUdXJuRXJyb3ISGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZRIqChF0dXJuX2Nhbl9jb250aW'
    '51ZRgCIAEoCFIPdHVybkNhbkNvbnRpbnVl');

@$core.Deprecated('Use feedbackDescriptor instead')
const Feedback$json = {
  '1': 'Feedback',
  '2': [
    {
      '1': 'target',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.RatingTarget',
      '10': 'target'
    },
    {
      '1': 'rating',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.Rating',
      '10': 'rating'
    },
    {'1': 'message_id', '3': 3, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'note', '3': 4, '4': 1, '5': 9, '10': 'note'},
    {'1': 'provider', '3': 5, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 6, '4': 1, '5': 9, '10': 'model'},
    {'1': 'client', '3': 7, '4': 1, '5': 9, '10': 'client'},
    {'1': 'turn_id', '3': 8, '4': 1, '5': 9, '10': 'turnId'},
  ],
};

/// Descriptor for `Feedback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedbackDescriptor = $convert.base64Decode(
    'CghGZWVkYmFjaxItCgZ0YXJnZXQYASABKA4yFS5mbGl0LnYxLlJhdGluZ1RhcmdldFIGdGFyZ2'
    'V0EicKBnJhdGluZxgCIAEoDjIPLmZsaXQudjEuUmF0aW5nUgZyYXRpbmcSHQoKbWVzc2FnZV9p'
    'ZBgDIAEoCVIJbWVzc2FnZUlkEhIKBG5vdGUYBCABKAlSBG5vdGUSGgoIcHJvdmlkZXIYBSABKA'
    'lSCHByb3ZpZGVyEhQKBW1vZGVsGAYgASgJUgVtb2RlbBIWCgZjbGllbnQYByABKAlSBmNsaWVu'
    'dBIXCgd0dXJuX2lkGAggASgJUgZ0dXJuSWQ=');

@$core.Deprecated('Use mcpServersChangedDescriptor instead')
const McpServersChanged$json = {
  '1': 'McpServersChanged',
  '2': [
    {'1': 'enabled', '3': 1, '4': 3, '5': 9, '10': 'enabled'},
  ],
};

/// Descriptor for `McpServersChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mcpServersChangedDescriptor = $convert.base64Decode(
    'ChFNY3BTZXJ2ZXJzQ2hhbmdlZBIYCgdlbmFibGVkGAEgAygJUgdlbmFibGVk');

@$core.Deprecated('Use sessionMovedDescriptor instead')
const SessionMoved$json = {
  '1': 'SessionMoved',
  '2': [
    {'1': 'project_id', '3': 1, '4': 1, '5': 9, '10': 'projectId'},
  ],
};

/// Descriptor for `SessionMoved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionMovedDescriptor = $convert.base64Decode(
    'CgxTZXNzaW9uTW92ZWQSHQoKcHJvamVjdF9pZBgBIAEoCVIJcHJvamVjdElk');

@$core.Deprecated('Use yoloChangedDescriptor instead')
const YoloChanged$json = {
  '1': 'YoloChanged',
  '2': [
    {'1': 'yolo', '3': 1, '4': 1, '5': 8, '10': 'yolo'},
    {'1': 'client', '3': 2, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `YoloChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List yoloChangedDescriptor = $convert.base64Decode(
    'CgtZb2xvQ2hhbmdlZBISCgR5b2xvGAEgASgIUgR5b2xvEhYKBmNsaWVudBgCIAEoCVIGY2xpZW'
    '50');

@$core.Deprecated('Use permissionCheckDescriptor instead')
const PermissionCheck$json = {
  '1': 'PermissionCheck',
  '2': [
    {'1': 'tool_call_id', '3': 1, '4': 1, '5': 9, '10': 'toolCallId'},
    {'1': 'command', '3': 2, '4': 1, '5': 9, '10': 'command'},
    {
      '1': 'verdict',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.PermissionVerdict',
      '10': 'verdict'
    },
    {'1': 'reason', '3': 4, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'provider', '3': 5, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 6, '4': 1, '5': 9, '10': 'model'},
    {'1': 'model_call_id', '3': 7, '4': 1, '5': 9, '10': 'modelCallId'},
    {'1': 'turn_id', '3': 8, '4': 1, '5': 9, '10': 'turnId'},
  ],
};

/// Descriptor for `PermissionCheck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionCheckDescriptor = $convert.base64Decode(
    'Cg9QZXJtaXNzaW9uQ2hlY2sSIAoMdG9vbF9jYWxsX2lkGAEgASgJUgp0b29sQ2FsbElkEhgKB2'
    'NvbW1hbmQYAiABKAlSB2NvbW1hbmQSNAoHdmVyZGljdBgDIAEoDjIaLmZsaXQudjEuUGVybWlz'
    'c2lvblZlcmRpY3RSB3ZlcmRpY3QSFgoGcmVhc29uGAQgASgJUgZyZWFzb24SGgoIcHJvdmlkZX'
    'IYBSABKAlSCHByb3ZpZGVyEhQKBW1vZGVsGAYgASgJUgVtb2RlbBIiCg1tb2RlbF9jYWxsX2lk'
    'GAcgASgJUgttb2RlbENhbGxJZBIXCgd0dXJuX2lkGAggASgJUgZ0dXJuSWQ=');

@$core.Deprecated('Use modelCallStartedDescriptor instead')
const ModelCallStarted$json = {
  '1': 'ModelCallStarted',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'attempt', '3': 2, '4': 1, '5': 5, '10': 'attempt'},
    {
      '1': 'first_byte_timeout_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'firstByteTimeoutMs'
    },
    {'1': 'stall_timeout_ms', '3': 4, '4': 1, '5': 3, '10': 'stallTimeoutMs'},
  ],
};

/// Descriptor for `ModelCallStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelCallStartedDescriptor = $convert.base64Decode(
    'ChBNb2RlbENhbGxTdGFydGVkEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZBIYCgdhdH'
    'RlbXB0GAIgASgFUgdhdHRlbXB0EjEKFWZpcnN0X2J5dGVfdGltZW91dF9tcxgDIAEoA1ISZmly'
    'c3RCeXRlVGltZW91dE1zEigKEHN0YWxsX3RpbWVvdXRfbXMYBCABKANSDnN0YWxsVGltZW91dE'
    '1z');

@$core.Deprecated('Use promptProgressDescriptor instead')
const PromptProgress$json = {
  '1': 'PromptProgress',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'attempt', '3': 2, '4': 1, '5': 5, '10': 'attempt'},
    {'1': 'processed', '3': 3, '4': 1, '5': 3, '10': 'processed'},
    {'1': 'total', '3': 4, '4': 1, '5': 3, '10': 'total'},
    {'1': 'cached', '3': 5, '4': 1, '5': 3, '10': 'cached'},
    {'1': 'elapsed_ms', '3': 6, '4': 1, '5': 3, '10': 'elapsedMs'},
  ],
};

/// Descriptor for `PromptProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptProgressDescriptor = $convert.base64Decode(
    'Cg5Qcm9tcHRQcm9ncmVzcxIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSGAoHYXR0ZW'
    '1wdBgCIAEoBVIHYXR0ZW1wdBIcCglwcm9jZXNzZWQYAyABKANSCXByb2Nlc3NlZBIUCgV0b3Rh'
    'bBgEIAEoA1IFdG90YWwSFgoGY2FjaGVkGAUgASgDUgZjYWNoZWQSHQoKZWxhcHNlZF9tcxgGIA'
    'EoA1IJZWxhcHNlZE1z');

@$core.Deprecated('Use modelCallEndedDescriptor instead')
const ModelCallEnded$json = {
  '1': 'ModelCallEnded',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'attempt', '3': 2, '4': 1, '5': 5, '10': 'attempt'},
    {
      '1': 'outcome',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.ModelCallOutcome',
      '10': 'outcome'
    },
    {'1': 'phase', '3': 4, '4': 1, '5': 9, '10': 'phase'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
    {
      '1': 'response_headers_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'responseHeadersMs'
    },
    {'1': 'first_byte_ms', '3': 7, '4': 1, '5': 3, '10': 'firstByteMs'},
    {'1': 'first_token_ms', '3': 8, '4': 1, '5': 3, '10': 'firstTokenMs'},
    {'1': 'last_byte_ms', '3': 9, '4': 1, '5': 3, '10': 'lastByteMs'},
    {'1': 'total_ms', '3': 10, '4': 1, '5': 3, '10': 'totalMs'},
    {'1': 'bytes', '3': 11, '4': 1, '5': 3, '10': 'bytes'},
    {'1': 'input_tokens', '3': 12, '4': 1, '5': 3, '10': 'inputTokens'},
    {'1': 'output_tokens', '3': 13, '4': 1, '5': 3, '10': 'outputTokens'},
    {'1': 'prompt_tokens', '3': 14, '4': 1, '5': 3, '10': 'promptTokens'},
    {'1': 'prompt_ms', '3': 15, '4': 1, '5': 3, '10': 'promptMs'},
    {'1': 'predicted_tokens', '3': 16, '4': 1, '5': 3, '10': 'predictedTokens'},
    {'1': 'predicted_ms', '3': 17, '4': 1, '5': 3, '10': 'predictedMs'},
    {'1': 'will_retry', '3': 18, '4': 1, '5': 8, '10': 'willRetry'},
    {'1': 'cached_tokens', '3': 19, '4': 1, '5': 3, '10': 'cachedTokens'},
    {'1': 'streamed_tokens', '3': 20, '4': 1, '5': 3, '10': 'streamedTokens'},
    {'1': 'prompt_processed', '3': 21, '4': 1, '5': 3, '10': 'promptProcessed'},
    {'1': 'prompt_total', '3': 22, '4': 1, '5': 3, '10': 'promptTotal'},
    {
      '1': 'server',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.ModelServerState',
      '10': 'server'
    },
  ],
};

/// Descriptor for `ModelCallEnded`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelCallEndedDescriptor = $convert.base64Decode(
    'Cg5Nb2RlbENhbGxFbmRlZBIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSGAoHYXR0ZW'
    '1wdBgCIAEoBVIHYXR0ZW1wdBIzCgdvdXRjb21lGAMgASgOMhkuZmxpdC52MS5Nb2RlbENhbGxP'
    'dXRjb21lUgdvdXRjb21lEhQKBXBoYXNlGAQgASgJUgVwaGFzZRIUCgVlcnJvchgFIAEoCVIFZX'
    'Jyb3ISLgoTcmVzcG9uc2VfaGVhZGVyc19tcxgGIAEoA1IRcmVzcG9uc2VIZWFkZXJzTXMSIgoN'
    'Zmlyc3RfYnl0ZV9tcxgHIAEoA1ILZmlyc3RCeXRlTXMSJAoOZmlyc3RfdG9rZW5fbXMYCCABKA'
    'NSDGZpcnN0VG9rZW5NcxIgCgxsYXN0X2J5dGVfbXMYCSABKANSCmxhc3RCeXRlTXMSGQoIdG90'
    'YWxfbXMYCiABKANSB3RvdGFsTXMSFAoFYnl0ZXMYCyABKANSBWJ5dGVzEiEKDGlucHV0X3Rva2'
    'VucxgMIAEoA1ILaW5wdXRUb2tlbnMSIwoNb3V0cHV0X3Rva2VucxgNIAEoA1IMb3V0cHV0VG9r'
    'ZW5zEiMKDXByb21wdF90b2tlbnMYDiABKANSDHByb21wdFRva2VucxIbCglwcm9tcHRfbXMYDy'
    'ABKANSCHByb21wdE1zEikKEHByZWRpY3RlZF90b2tlbnMYECABKANSD3ByZWRpY3RlZFRva2Vu'
    'cxIhCgxwcmVkaWN0ZWRfbXMYESABKANSC3ByZWRpY3RlZE1zEh0KCndpbGxfcmV0cnkYEiABKA'
    'hSCXdpbGxSZXRyeRIjCg1jYWNoZWRfdG9rZW5zGBMgASgDUgxjYWNoZWRUb2tlbnMSJwoPc3Ry'
    'ZWFtZWRfdG9rZW5zGBQgASgDUg5zdHJlYW1lZFRva2VucxIpChBwcm9tcHRfcHJvY2Vzc2VkGB'
    'UgASgDUg9wcm9tcHRQcm9jZXNzZWQSIQoMcHJvbXB0X3RvdGFsGBYgASgDUgtwcm9tcHRUb3Rh'
    'bBIxCgZzZXJ2ZXIYFyABKAsyGS5mbGl0LnYxLk1vZGVsU2VydmVyU3RhdGVSBnNlcnZlcg==');

@$core.Deprecated('Use modelServerStateDescriptor instead')
const ModelServerState$json = {
  '1': 'ModelServerState',
  '2': [
    {'1': 'model_state', '3': 1, '4': 1, '5': 9, '10': 'modelState'},
    {
      '1': 'slots',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.LlamaSlot',
      '10': 'slots'
    },
    {
      '1': 'pinned_slot',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'pinnedSlot',
      '17': true
    },
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
    {'1': 'sample_ms', '3': 5, '4': 1, '5': 3, '10': 'sampleMs'},
    {'1': 'slots_error', '3': 6, '4': 1, '5': 9, '10': 'slotsError'},
  ],
  '8': [
    {'1': '_pinned_slot'},
  ],
};

/// Descriptor for `ModelServerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelServerStateDescriptor = $convert.base64Decode(
    'ChBNb2RlbFNlcnZlclN0YXRlEh8KC21vZGVsX3N0YXRlGAEgASgJUgptb2RlbFN0YXRlEigKBX'
    'Nsb3RzGAIgAygLMhIuZmxpdC52MS5MbGFtYVNsb3RSBXNsb3RzEiQKC3Bpbm5lZF9zbG90GAMg'
    'ASgFSABSCnBpbm5lZFNsb3SIAQESFAoFZXJyb3IYBCABKAlSBWVycm9yEhsKCXNhbXBsZV9tcx'
    'gFIAEoA1IIc2FtcGxlTXMSHwoLc2xvdHNfZXJyb3IYBiABKAlSCnNsb3RzRXJyb3JCDgoMX3Bp'
    'bm5lZF9zbG90');

@$core.Deprecated('Use llamaSlotDescriptor instead')
const LlamaSlot$json = {
  '1': 'LlamaSlot',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'is_processing', '3': 2, '4': 1, '5': 8, '10': 'isProcessing'},
    {'1': 'id_task', '3': 3, '4': 1, '5': 3, '10': 'idTask'},
    {'1': 'n_ctx', '3': 4, '4': 1, '5': 3, '10': 'nCtx'},
    {'1': 'prompt_tokens', '3': 5, '4': 1, '5': 3, '10': 'promptTokens'},
    {'1': 'prompt_processed', '3': 6, '4': 1, '5': 3, '10': 'promptProcessed'},
    {'1': 'prompt_cached', '3': 7, '4': 1, '5': 3, '10': 'promptCached'},
    {'1': 'decoded', '3': 8, '4': 1, '5': 3, '10': 'decoded'},
    {
      '1': 'prompt_processed_delta',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'promptProcessedDelta'
    },
    {'1': 'decoded_delta', '3': 10, '4': 1, '5': 3, '10': 'decodedDelta'},
  ],
};

/// Descriptor for `LlamaSlot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List llamaSlotDescriptor = $convert.base64Decode(
    'CglMbGFtYVNsb3QSDgoCaWQYASABKAVSAmlkEiMKDWlzX3Byb2Nlc3NpbmcYAiABKAhSDGlzUH'
    'JvY2Vzc2luZxIXCgdpZF90YXNrGAMgASgDUgZpZFRhc2sSEwoFbl9jdHgYBCABKANSBG5DdHgS'
    'IwoNcHJvbXB0X3Rva2VucxgFIAEoA1IMcHJvbXB0VG9rZW5zEikKEHByb21wdF9wcm9jZXNzZW'
    'QYBiABKANSD3Byb21wdFByb2Nlc3NlZBIjCg1wcm9tcHRfY2FjaGVkGAcgASgDUgxwcm9tcHRD'
    'YWNoZWQSGAoHZGVjb2RlZBgIIAEoA1IHZGVjb2RlZBI0ChZwcm9tcHRfcHJvY2Vzc2VkX2RlbH'
    'RhGAkgASgDUhRwcm9tcHRQcm9jZXNzZWREZWx0YRIjCg1kZWNvZGVkX2RlbHRhGAogASgDUgxk'
    'ZWNvZGVkRGVsdGE=');

@$core.Deprecated('Use messageQueuedDescriptor instead')
const MessageQueued$json = {
  '1': 'MessageQueued',
  '2': [
    {'1': 'queue_id', '3': 1, '4': 1, '5': 9, '10': 'queueId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `MessageQueued`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageQueuedDescriptor = $convert.base64Decode(
    'Cg1NZXNzYWdlUXVldWVkEhkKCHF1ZXVlX2lkGAEgASgJUgdxdWV1ZUlkEhIKBHRleHQYAiABKA'
    'lSBHRleHQSFgoGY2xpZW50GAMgASgJUgZjbGllbnQ=');

@$core.Deprecated('Use queuedMessageUpdatedDescriptor instead')
const QueuedMessageUpdated$json = {
  '1': 'QueuedMessageUpdated',
  '2': [
    {'1': 'queue_id', '3': 1, '4': 1, '5': 9, '10': 'queueId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'cancelled', '3': 3, '4': 1, '5': 8, '10': 'cancelled'},
  ],
};

/// Descriptor for `QueuedMessageUpdated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queuedMessageUpdatedDescriptor = $convert.base64Decode(
    'ChRRdWV1ZWRNZXNzYWdlVXBkYXRlZBIZCghxdWV1ZV9pZBgBIAEoCVIHcXVldWVJZBISCgR0ZX'
    'h0GAIgASgJUgR0ZXh0EhwKCWNhbmNlbGxlZBgDIAEoCFIJY2FuY2VsbGVk');

@$core.Deprecated('Use queuedMessageDeliveredDescriptor instead')
const QueuedMessageDelivered$json = {
  '1': 'QueuedMessageDelivered',
  '2': [
    {'1': 'queue_id', '3': 1, '4': 1, '5': 9, '10': 'queueId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
  ],
};

/// Descriptor for `QueuedMessageDelivered`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queuedMessageDeliveredDescriptor =
    $convert.base64Decode(
        'ChZRdWV1ZWRNZXNzYWdlRGVsaXZlcmVkEhkKCHF1ZXVlX2lkGAEgASgJUgdxdWV1ZUlkEh0KCm'
        '1lc3NhZ2VfaWQYAiABKAlSCW1lc3NhZ2VJZA==');

@$core.Deprecated('Use modelCallWaitingDescriptor instead')
const ModelCallWaiting$json = {
  '1': 'ModelCallWaiting',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'attempt', '3': 2, '4': 1, '5': 5, '10': 'attempt'},
    {
      '1': 'reason',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.ModelWaitReason',
      '10': 'reason'
    },
    {'1': 'total_slots', '3': 4, '4': 1, '5': 5, '10': 'totalSlots'},
  ],
};

/// Descriptor for `ModelCallWaiting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelCallWaitingDescriptor = $convert.base64Decode(
    'ChBNb2RlbENhbGxXYWl0aW5nEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZBIYCgdhdH'
    'RlbXB0GAIgASgFUgdhdHRlbXB0EjAKBnJlYXNvbhgDIAEoDjIYLmZsaXQudjEuTW9kZWxXYWl0'
    'UmVhc29uUgZyZWFzb24SHwoLdG90YWxfc2xvdHMYBCABKAVSCnRvdGFsU2xvdHM=');

@$core.Deprecated('Use promptCacheDescriptor instead')
const PromptCache$json = {
  '1': 'PromptCache',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.PromptCacheAction',
      '10': 'action'
    },
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'slot', '3': 3, '4': 1, '5': 5, '10': 'slot'},
    {'1': 'file', '3': 4, '4': 1, '5': 9, '10': 'file'},
    {'1': 'tokens', '3': 5, '4': 1, '5': 3, '10': 'tokens'},
    {'1': 'elapsed_ms', '3': 6, '4': 1, '5': 3, '10': 'elapsedMs'},
    {'1': 'error', '3': 7, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `PromptCache`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptCacheDescriptor = $convert.base64Decode(
    'CgtQcm9tcHRDYWNoZRIyCgZhY3Rpb24YASABKA4yGi5mbGl0LnYxLlByb21wdENhY2hlQWN0aW'
    '9uUgZhY3Rpb24SHQoKbWVzc2FnZV9pZBgCIAEoCVIJbWVzc2FnZUlkEhIKBHNsb3QYAyABKAVS'
    'BHNsb3QSEgoEZmlsZRgEIAEoCVIEZmlsZRIWCgZ0b2tlbnMYBSABKANSBnRva2VucxIdCgplbG'
    'Fwc2VkX21zGAYgASgDUgllbGFwc2VkTXMSFAoFZXJyb3IYByABKAlSBWVycm9y');

@$core.Deprecated('Use reasoningEndRequestedDescriptor instead')
const ReasoningEndRequested$json = {
  '1': 'ReasoningEndRequested',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'client', '3': 2, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `ReasoningEndRequested`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasoningEndRequestedDescriptor = $convert.base64Decode(
    'ChVSZWFzb25pbmdFbmRSZXF1ZXN0ZWQSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEh'
    'YKBmNsaWVudBgCIAEoCVIGY2xpZW50');

@$core.Deprecated('Use reasoningEndIgnoredDescriptor instead')
const ReasoningEndIgnored$json = {
  '1': 'ReasoningEndIgnored',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
  ],
};

/// Descriptor for `ReasoningEndIgnored`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasoningEndIgnoredDescriptor = $convert.base64Decode(
    'ChNSZWFzb25pbmdFbmRJZ25vcmVkEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZA==');

@$core.Deprecated('Use compactionStartedDescriptor instead')
const CompactionStarted$json = {
  '1': 'CompactionStarted',
  '2': [
    {'1': 'compaction_id', '3': 1, '4': 1, '5': 9, '10': 'compactionId'},
    {'1': 'auto', '3': 2, '4': 1, '5': 8, '10': 'auto'},
    {'1': 'client', '3': 3, '4': 1, '5': 9, '10': 'client'},
    {'1': 'tokens', '3': 4, '4': 1, '5': 3, '10': 'tokens'},
    {'1': 'context_length', '3': 5, '4': 1, '5': 3, '10': 'contextLength'},
    {'1': 'provider', '3': 6, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 7, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `CompactionStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compactionStartedDescriptor = $convert.base64Decode(
    'ChFDb21wYWN0aW9uU3RhcnRlZBIjCg1jb21wYWN0aW9uX2lkGAEgASgJUgxjb21wYWN0aW9uSW'
    'QSEgoEYXV0bxgCIAEoCFIEYXV0bxIWCgZjbGllbnQYAyABKAlSBmNsaWVudBIWCgZ0b2tlbnMY'
    'BCABKANSBnRva2VucxIlCg5jb250ZXh0X2xlbmd0aBgFIAEoA1INY29udGV4dExlbmd0aBIaCg'
    'hwcm92aWRlchgGIAEoCVIIcHJvdmlkZXISFAoFbW9kZWwYByABKAlSBW1vZGVs');

@$core.Deprecated('Use compactionDoneDescriptor instead')
const CompactionDone$json = {
  '1': 'CompactionDone',
  '2': [
    {'1': 'compaction_id', '3': 1, '4': 1, '5': 9, '10': 'compactionId'},
    {'1': 'auto', '3': 2, '4': 1, '5': 8, '10': 'auto'},
    {'1': 'summary', '3': 3, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'covered_seq', '3': 4, '4': 1, '5': 3, '10': 'coveredSeq'},
    {'1': 'tokens_before', '3': 5, '4': 1, '5': 3, '10': 'tokensBefore'},
    {'1': 'tokens_after', '3': 6, '4': 1, '5': 3, '10': 'tokensAfter'},
    {'1': 'tokens_exact', '3': 7, '4': 1, '5': 8, '10': 'tokensExact'},
    {'1': 'context_length', '3': 8, '4': 1, '5': 3, '10': 'contextLength'},
    {'1': 'provider', '3': 9, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 10, '4': 1, '5': 9, '10': 'model'},
    {'1': 'model_call_id', '3': 11, '4': 1, '5': 9, '10': 'modelCallId'},
    {'1': 'elapsed_ms', '3': 12, '4': 1, '5': 3, '10': 'elapsedMs'},
    {'1': 'kept_turns', '3': 13, '4': 1, '5': 5, '10': 'keptTurns'},
    {'1': 'error', '3': 14, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `CompactionDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compactionDoneDescriptor = $convert.base64Decode(
    'Cg5Db21wYWN0aW9uRG9uZRIjCg1jb21wYWN0aW9uX2lkGAEgASgJUgxjb21wYWN0aW9uSWQSEg'
    'oEYXV0bxgCIAEoCFIEYXV0bxIYCgdzdW1tYXJ5GAMgASgJUgdzdW1tYXJ5Eh8KC2NvdmVyZWRf'
    'c2VxGAQgASgDUgpjb3ZlcmVkU2VxEiMKDXRva2Vuc19iZWZvcmUYBSABKANSDHRva2Vuc0JlZm'
    '9yZRIhCgx0b2tlbnNfYWZ0ZXIYBiABKANSC3Rva2Vuc0FmdGVyEiEKDHRva2Vuc19leGFjdBgH'
    'IAEoCFILdG9rZW5zRXhhY3QSJQoOY29udGV4dF9sZW5ndGgYCCABKANSDWNvbnRleHRMZW5ndG'
    'gSGgoIcHJvdmlkZXIYCSABKAlSCHByb3ZpZGVyEhQKBW1vZGVsGAogASgJUgVtb2RlbBIiCg1t'
    'b2RlbF9jYWxsX2lkGAsgASgJUgttb2RlbENhbGxJZBIdCgplbGFwc2VkX21zGAwgASgDUgllbG'
    'Fwc2VkTXMSHQoKa2VwdF90dXJucxgNIAEoBVIJa2VwdFR1cm5zEhQKBWVycm9yGA4gASgJUgVl'
    'cnJvcg==');

@$core.Deprecated('Use branchCreatedDescriptor instead')
const BranchCreated$json = {
  '1': 'BranchCreated',
  '2': [
    {'1': 'branch_id', '3': 1, '4': 1, '5': 9, '10': 'branchId'},
    {'1': 'parent_branch_id', '3': 2, '4': 1, '5': 9, '10': 'parentBranchId'},
    {'1': 'fork_seq', '3': 3, '4': 1, '5': 3, '10': 'forkSeq'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.BranchKind',
      '10': 'kind'
    },
    {'1': 'message_id', '3': 5, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'client', '3': 6, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `BranchCreated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List branchCreatedDescriptor = $convert.base64Decode(
    'Cg1CcmFuY2hDcmVhdGVkEhsKCWJyYW5jaF9pZBgBIAEoCVIIYnJhbmNoSWQSKAoQcGFyZW50X2'
    'JyYW5jaF9pZBgCIAEoCVIOcGFyZW50QnJhbmNoSWQSGQoIZm9ya19zZXEYAyABKANSB2ZvcmtT'
    'ZXESJwoEa2luZBgEIAEoDjITLmZsaXQudjEuQnJhbmNoS2luZFIEa2luZBIdCgptZXNzYWdlX2'
    'lkGAUgASgJUgltZXNzYWdlSWQSFgoGY2xpZW50GAYgASgJUgZjbGllbnQ=');

@$core.Deprecated('Use branchSwitchedDescriptor instead')
const BranchSwitched$json = {
  '1': 'BranchSwitched',
  '2': [
    {'1': 'branch_id', '3': 1, '4': 1, '5': 9, '10': 'branchId'},
    {'1': 'client', '3': 2, '4': 1, '5': 9, '10': 'client'},
  ],
};

/// Descriptor for `BranchSwitched`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List branchSwitchedDescriptor = $convert.base64Decode(
    'Cg5CcmFuY2hTd2l0Y2hlZBIbCglicmFuY2hfaWQYASABKAlSCGJyYW5jaElkEhYKBmNsaWVudB'
    'gCIAEoCVIGY2xpZW50');

@$core.Deprecated('Use gitStatusRequestDescriptor instead')
const GitStatusRequest$json = {
  '1': 'GitStatusRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GitStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitStatusRequestDescriptor = $convert.base64Decode(
    'ChBHaXRTdGF0dXNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZA==');

@$core.Deprecated('Use gitFileChangeDescriptor instead')
const GitFileChange$json = {
  '1': 'GitFileChange',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'old_path', '3': 2, '4': 1, '5': 9, '10': 'oldPath'},
    {
      '1': 'status',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.GitFileStatus',
      '10': 'status'
    },
    {'1': 'additions', '3': 4, '4': 1, '5': 5, '10': 'additions'},
    {'1': 'deletions', '3': 5, '4': 1, '5': 5, '10': 'deletions'},
    {'1': 'binary', '3': 6, '4': 1, '5': 8, '10': 'binary'},
    {'1': 'staged', '3': 7, '4': 1, '5': 8, '10': 'staged'},
    {'1': 'unstaged', '3': 8, '4': 1, '5': 8, '10': 'unstaged'},
    {'1': 'untracked', '3': 9, '4': 1, '5': 8, '10': 'untracked'},
  ],
};

/// Descriptor for `GitFileChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitFileChangeDescriptor = $convert.base64Decode(
    'Cg1HaXRGaWxlQ2hhbmdlEhIKBHBhdGgYASABKAlSBHBhdGgSGQoIb2xkX3BhdGgYAiABKAlSB2'
    '9sZFBhdGgSLgoGc3RhdHVzGAMgASgOMhYuZmxpdC52MS5HaXRGaWxlU3RhdHVzUgZzdGF0dXMS'
    'HAoJYWRkaXRpb25zGAQgASgFUglhZGRpdGlvbnMSHAoJZGVsZXRpb25zGAUgASgFUglkZWxldG'
    'lvbnMSFgoGYmluYXJ5GAYgASgIUgZiaW5hcnkSFgoGc3RhZ2VkGAcgASgIUgZzdGFnZWQSGgoI'
    'dW5zdGFnZWQYCCABKAhSCHVuc3RhZ2VkEhwKCXVudHJhY2tlZBgJIAEoCFIJdW50cmFja2Vk');

@$core.Deprecated('Use gitStatusResponseDescriptor instead')
const GitStatusResponse$json = {
  '1': 'GitStatusResponse',
  '2': [
    {'1': 'is_repo', '3': 1, '4': 1, '5': 8, '10': 'isRepo'},
    {'1': 'root', '3': 2, '4': 1, '5': 9, '10': 'root'},
    {'1': 'branch', '3': 3, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'head', '3': 4, '4': 1, '5': 9, '10': 'head'},
    {'1': 'detached', '3': 5, '4': 1, '5': 8, '10': 'detached'},
    {'1': 'upstream', '3': 6, '4': 1, '5': 9, '10': 'upstream'},
    {'1': 'ahead', '3': 7, '4': 1, '5': 5, '10': 'ahead'},
    {'1': 'behind', '3': 8, '4': 1, '5': 5, '10': 'behind'},
    {'1': 'staged_count', '3': 9, '4': 1, '5': 5, '10': 'stagedCount'},
    {'1': 'unstaged_count', '3': 10, '4': 1, '5': 5, '10': 'unstagedCount'},
    {'1': 'untracked_count', '3': 11, '4': 1, '5': 5, '10': 'untrackedCount'},
    {'1': 'conflicted_count', '3': 12, '4': 1, '5': 5, '10': 'conflictedCount'},
    {'1': 'base_commit', '3': 13, '4': 1, '5': 9, '10': 'baseCommit'},
    {'1': 'diff_base', '3': 14, '4': 1, '5': 9, '10': 'diffBase'},
    {
      '1': 'diff_base_kind',
      '3': 15,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.GitDiffBase',
      '10': 'diffBaseKind'
    },
    {
      '1': 'files',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.GitFileChange',
      '10': 'files'
    },
    {'1': 'files_truncated', '3': 17, '4': 1, '5': 8, '10': 'filesTruncated'},
  ],
};

/// Descriptor for `GitStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitStatusResponseDescriptor = $convert.base64Decode(
    'ChFHaXRTdGF0dXNSZXNwb25zZRIXCgdpc19yZXBvGAEgASgIUgZpc1JlcG8SEgoEcm9vdBgCIA'
    'EoCVIEcm9vdBIWCgZicmFuY2gYAyABKAlSBmJyYW5jaBISCgRoZWFkGAQgASgJUgRoZWFkEhoK'
    'CGRldGFjaGVkGAUgASgIUghkZXRhY2hlZBIaCgh1cHN0cmVhbRgGIAEoCVIIdXBzdHJlYW0SFA'
    'oFYWhlYWQYByABKAVSBWFoZWFkEhYKBmJlaGluZBgIIAEoBVIGYmVoaW5kEiEKDHN0YWdlZF9j'
    'b3VudBgJIAEoBVILc3RhZ2VkQ291bnQSJQoOdW5zdGFnZWRfY291bnQYCiABKAVSDXVuc3RhZ2'
    'VkQ291bnQSJwoPdW50cmFja2VkX2NvdW50GAsgASgFUg51bnRyYWNrZWRDb3VudBIpChBjb25m'
    'bGljdGVkX2NvdW50GAwgASgFUg9jb25mbGljdGVkQ291bnQSHwoLYmFzZV9jb21taXQYDSABKA'
    'lSCmJhc2VDb21taXQSGwoJZGlmZl9iYXNlGA4gASgJUghkaWZmQmFzZRI6Cg5kaWZmX2Jhc2Vf'
    'a2luZBgPIAEoDjIULmZsaXQudjEuR2l0RGlmZkJhc2VSDGRpZmZCYXNlS2luZBIsCgVmaWxlcx'
    'gQIAMoCzIWLmZsaXQudjEuR2l0RmlsZUNoYW5nZVIFZmlsZXMSJwoPZmlsZXNfdHJ1bmNhdGVk'
    'GBEgASgIUg5maWxlc1RydW5jYXRlZA==');

@$core.Deprecated('Use gitDiffRequestDescriptor instead')
const GitDiffRequest$json = {
  '1': 'GitDiffRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'max_bytes', '3': 3, '4': 1, '5': 5, '10': 'maxBytes'},
  ],
};

/// Descriptor for `GitDiffRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitDiffRequestDescriptor = $convert.base64Decode(
    'Cg5HaXREaWZmUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEgoEcGF0aB'
    'gCIAEoCVIEcGF0aBIbCgltYXhfYnl0ZXMYAyABKAVSCG1heEJ5dGVz');

@$core.Deprecated('Use gitDiffResponseDescriptor instead')
const GitDiffResponse$json = {
  '1': 'GitDiffResponse',
  '2': [
    {'1': 'is_repo', '3': 1, '4': 1, '5': 8, '10': 'isRepo'},
    {'1': 'diff_base', '3': 2, '4': 1, '5': 9, '10': 'diffBase'},
    {
      '1': 'diff_base_kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.GitDiffBase',
      '10': 'diffBaseKind'
    },
    {'1': 'diff', '3': 4, '4': 1, '5': 9, '10': 'diff'},
    {'1': 'truncated', '3': 5, '4': 1, '5': 8, '10': 'truncated'},
  ],
};

/// Descriptor for `GitDiffResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitDiffResponseDescriptor = $convert.base64Decode(
    'Cg9HaXREaWZmUmVzcG9uc2USFwoHaXNfcmVwbxgBIAEoCFIGaXNSZXBvEhsKCWRpZmZfYmFzZR'
    'gCIAEoCVIIZGlmZkJhc2USOgoOZGlmZl9iYXNlX2tpbmQYAyABKA4yFC5mbGl0LnYxLkdpdERp'
    'ZmZCYXNlUgxkaWZmQmFzZUtpbmQSEgoEZGlmZhgEIAEoCVIEZGlmZhIcCgl0cnVuY2F0ZWQYBS'
    'ABKAhSCXRydW5jYXRlZA==');

@$core.Deprecated('Use cronRunStartedDescriptor instead')
const CronRunStarted$json = {
  '1': 'CronRunStarted',
  '2': [
    {'1': 'job', '3': 1, '4': 1, '5': 9, '10': 'job'},
    {'1': 'schedule', '3': 2, '4': 1, '5': 9, '10': 'schedule'},
    {'1': 'schedule_text', '3': 3, '4': 1, '5': 9, '10': 'scheduleText'},
    {
      '1': 'trigger',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.CronTrigger',
      '10': 'trigger'
    },
    {
      '1': 'scheduled_time',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'scheduledTime'
    },
    {'1': 'run_id', '3': 6, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'ask', '3': 7, '4': 1, '5': 14, '6': '.flit.v1.CronAsk', '10': 'ask'},
    {
      '1': 'ask_timeout_seconds',
      '3': 8,
      '4': 1,
      '5': 3,
      '10': 'askTimeoutSeconds'
    },
    {'1': 'yolo', '3': 9, '4': 1, '5': 8, '10': 'yolo'},
  ],
};

/// Descriptor for `CronRunStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cronRunStartedDescriptor = $convert.base64Decode(
    'Cg5Dcm9uUnVuU3RhcnRlZBIQCgNqb2IYASABKAlSA2pvYhIaCghzY2hlZHVsZRgCIAEoCVIIc2'
    'NoZWR1bGUSIwoNc2NoZWR1bGVfdGV4dBgDIAEoCVIMc2NoZWR1bGVUZXh0Ei4KB3RyaWdnZXIY'
    'BCABKA4yFC5mbGl0LnYxLkNyb25UcmlnZ2VyUgd0cmlnZ2VyEkEKDnNjaGVkdWxlZF90aW1lGA'
    'UgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFINc2NoZWR1bGVkVGltZRIVCgZydW5f'
    'aWQYBiABKAlSBXJ1bklkEiIKA2FzaxgHIAEoDjIQLmZsaXQudjEuQ3JvbkFza1IDYXNrEi4KE2'
    'Fza190aW1lb3V0X3NlY29uZHMYCCABKANSEWFza1RpbWVvdXRTZWNvbmRzEhIKBHlvbG8YCSAB'
    'KAhSBHlvbG8=');

@$core.Deprecated('Use webhookRunStartedDescriptor instead')
const WebhookRunStarted$json = {
  '1': 'WebhookRunStarted',
  '2': [
    {'1': 'hook', '3': 1, '4': 1, '5': 9, '10': 'hook'},
    {'1': 'source', '3': 2, '4': 1, '5': 9, '10': 'source'},
    {'1': 'event', '3': 3, '4': 1, '5': 9, '10': 'event'},
    {'1': 'action', '3': 4, '4': 1, '5': 9, '10': 'action'},
    {'1': 'delivery_id', '3': 5, '4': 1, '5': 9, '10': 'deliveryId'},
    {'1': 'summary', '3': 6, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'run_id', '3': 7, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'url', '3': 8, '4': 1, '5': 9, '10': 'url'},
    {'1': 'ask', '3': 9, '4': 1, '5': 14, '6': '.flit.v1.CronAsk', '10': 'ask'},
    {
      '1': 'ask_timeout_seconds',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'askTimeoutSeconds'
    },
    {'1': 'yolo', '3': 11, '4': 1, '5': 8, '10': 'yolo'},
  ],
};

/// Descriptor for `WebhookRunStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webhookRunStartedDescriptor = $convert.base64Decode(
    'ChFXZWJob29rUnVuU3RhcnRlZBISCgRob29rGAEgASgJUgRob29rEhYKBnNvdXJjZRgCIAEoCV'
    'IGc291cmNlEhQKBWV2ZW50GAMgASgJUgVldmVudBIWCgZhY3Rpb24YBCABKAlSBmFjdGlvbhIf'
    'CgtkZWxpdmVyeV9pZBgFIAEoCVIKZGVsaXZlcnlJZBIYCgdzdW1tYXJ5GAYgASgJUgdzdW1tYX'
    'J5EhUKBnJ1bl9pZBgHIAEoCVIFcnVuSWQSEAoDdXJsGAggASgJUgN1cmwSIgoDYXNrGAkgASgO'
    'MhAuZmxpdC52MS5Dcm9uQXNrUgNhc2sSLgoTYXNrX3RpbWVvdXRfc2Vjb25kcxgKIAEoA1IRYX'
    'NrVGltZW91dFNlY29uZHMSEgoEeW9sbxgLIAEoCFIEeW9sbw==');

@$core.Deprecated('Use subagentStartedDescriptor instead')
const SubagentStarted$json = {
  '1': 'SubagentStarted',
  '2': [
    {'1': 'tool_call_id', '3': 1, '4': 1, '5': 9, '10': 'toolCallId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.SubagentKind',
      '10': 'kind'
    },
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
    {'1': 'effort', '3': 5, '4': 1, '5': 9, '10': 'effort'},
    {'1': 'task', '3': 6, '4': 1, '5': 9, '10': 'task'},
    {'1': 'max_steps', '3': 7, '4': 1, '5': 5, '10': 'maxSteps'},
  ],
};

/// Descriptor for `SubagentStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subagentStartedDescriptor = $convert.base64Decode(
    'Cg9TdWJhZ2VudFN0YXJ0ZWQSIAoMdG9vbF9jYWxsX2lkGAEgASgJUgp0b29sQ2FsbElkEikKBG'
    'tpbmQYAiABKA4yFS5mbGl0LnYxLlN1YmFnZW50S2luZFIEa2luZBIaCghwcm92aWRlchgDIAEo'
    'CVIIcHJvdmlkZXISFAoFbW9kZWwYBCABKAlSBW1vZGVsEhYKBmVmZm9ydBgFIAEoCVIGZWZmb3'
    'J0EhIKBHRhc2sYBiABKAlSBHRhc2sSGwoJbWF4X3N0ZXBzGAcgASgFUghtYXhTdGVwcw==');

@$core.Deprecated('Use subagentEventDescriptor instead')
const SubagentEvent$json = {
  '1': 'SubagentEvent',
  '2': [
    {'1': 'tool_call_id', '3': 1, '4': 1, '5': 9, '10': 'toolCallId'},
    {
      '1': 'event',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Event',
      '10': 'event'
    },
  ],
};

/// Descriptor for `SubagentEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subagentEventDescriptor = $convert.base64Decode(
    'Cg1TdWJhZ2VudEV2ZW50EiAKDHRvb2xfY2FsbF9pZBgBIAEoCVIKdG9vbENhbGxJZBIkCgVldm'
    'VudBgCIAEoCzIOLmZsaXQudjEuRXZlbnRSBWV2ZW50');

@$core.Deprecated('Use subagentDoneDescriptor instead')
const SubagentDone$json = {
  '1': 'SubagentDone',
  '2': [
    {'1': 'tool_call_id', '3': 1, '4': 1, '5': 9, '10': 'toolCallId'},
    {
      '1': 'outcome',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.SubagentOutcome',
      '10': 'outcome'
    },
    {'1': 'report', '3': 3, '4': 1, '5': 9, '10': 'report'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
    {'1': 'steps', '3': 5, '4': 1, '5': 5, '10': 'steps'},
  ],
};

/// Descriptor for `SubagentDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subagentDoneDescriptor = $convert.base64Decode(
    'CgxTdWJhZ2VudERvbmUSIAoMdG9vbF9jYWxsX2lkGAEgASgJUgp0b29sQ2FsbElkEjIKB291dG'
    'NvbWUYAiABKA4yGC5mbGl0LnYxLlN1YmFnZW50T3V0Y29tZVIHb3V0Y29tZRIWCgZyZXBvcnQY'
    'AyABKAlSBnJlcG9ydBIUCgVlcnJvchgEIAEoCVIFZXJyb3ISFAoFc3RlcHMYBSABKAVSBXN0ZX'
    'Bz');

@$core.Deprecated('Use worktreeCreatedDescriptor instead')
const WorktreeCreated$json = {
  '1': 'WorktreeCreated',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'branch', '3': 2, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'base_commit', '3': 3, '4': 1, '5': 9, '10': 'baseCommit'},
    {'1': 'source_root', '3': 4, '4': 1, '5': 9, '10': 'sourceRoot'},
    {
      '1': 'copies',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.WorktreeCopy',
      '10': 'copies'
    },
  ],
};

/// Descriptor for `WorktreeCreated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List worktreeCreatedDescriptor = $convert.base64Decode(
    'Cg9Xb3JrdHJlZUNyZWF0ZWQSEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZicmFuY2gYAiABKAlSBm'
    'JyYW5jaBIfCgtiYXNlX2NvbW1pdBgDIAEoCVIKYmFzZUNvbW1pdBIfCgtzb3VyY2Vfcm9vdBgE'
    'IAEoCVIKc291cmNlUm9vdBItCgZjb3BpZXMYBSADKAsyFS5mbGl0LnYxLldvcmt0cmVlQ29weV'
    'IGY29waWVz');

@$core.Deprecated('Use worktreeCopyDescriptor instead')
const WorktreeCopy$json = {
  '1': 'WorktreeCopy',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'method', '3': 2, '4': 1, '5': 9, '10': 'method'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `WorktreeCopy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List worktreeCopyDescriptor = $convert.base64Decode(
    'CgxXb3JrdHJlZUNvcHkSEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZtZXRob2QYAiABKAlSBm1ldG'
    'hvZBIUCgVlcnJvchgDIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use worktreeSkippedDescriptor instead')
const WorktreeSkipped$json = {
  '1': 'WorktreeSkipped',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `WorktreeSkipped`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List worktreeSkippedDescriptor = $convert
    .base64Decode('Cg9Xb3JrdHJlZVNraXBwZWQSFgoGcmVhc29uGAEgASgJUgZyZWFzb24=');

@$core.Deprecated('Use worktreeRemovedDescriptor instead')
const WorktreeRemoved$json = {
  '1': 'WorktreeRemoved',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'branch', '3': 2, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'branch_kept', '3': 3, '4': 1, '5': 8, '10': 'branchKept'},
    {'1': 'commits', '3': 4, '4': 1, '5': 5, '10': 'commits'},
  ],
};

/// Descriptor for `WorktreeRemoved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List worktreeRemovedDescriptor = $convert.base64Decode(
    'Cg9Xb3JrdHJlZVJlbW92ZWQSEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZicmFuY2gYAiABKAlSBm'
    'JyYW5jaBIfCgticmFuY2hfa2VwdBgDIAEoCFIKYnJhbmNoS2VwdBIYCgdjb21taXRzGAQgASgF'
    'Ugdjb21taXRz');

@$core.Deprecated('Use worktreeKeptDescriptor instead')
const WorktreeKept$json = {
  '1': 'WorktreeKept',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'branch', '3': 2, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'reason', '3': 3, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `WorktreeKept`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List worktreeKeptDescriptor = $convert.base64Decode(
    'CgxXb3JrdHJlZUtlcHQSEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZicmFuY2gYAiABKAlSBmJyYW'
    '5jaBIWCgZyZWFzb24YAyABKAlSBnJlYXNvbg==');

@$core.Deprecated('Use removeWorktreeRequestDescriptor instead')
const RemoveWorktreeRequest$json = {
  '1': 'RemoveWorktreeRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `RemoveWorktreeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeWorktreeRequestDescriptor = $convert.base64Decode(
    'ChVSZW1vdmVXb3JrdHJlZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use removeWorktreeResponseDescriptor instead')
const RemoveWorktreeResponse$json = {
  '1': 'RemoveWorktreeResponse',
  '2': [
    {
      '1': 'session',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Session',
      '10': 'session'
    },
    {'1': 'branch_kept', '3': 2, '4': 1, '5': 8, '10': 'branchKept'},
    {'1': 'commits', '3': 3, '4': 1, '5': 5, '10': 'commits'},
  ],
};

/// Descriptor for `RemoveWorktreeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeWorktreeResponseDescriptor = $convert.base64Decode(
    'ChZSZW1vdmVXb3JrdHJlZVJlc3BvbnNlEioKB3Nlc3Npb24YASABKAsyEC5mbGl0LnYxLlNlc3'
    'Npb25SB3Nlc3Npb24SHwoLYnJhbmNoX2tlcHQYAiABKAhSCmJyYW5jaEtlcHQSGAoHY29tbWl0'
    'cxgDIAEoBVIHY29tbWl0cw==');

const $core.Map<$core.String, $core.dynamic> SessionServiceBase$json = {
  '1': 'SessionService',
  '2': [
    {
      '1': 'CreateSession',
      '2': '.flit.v1.CreateSessionRequest',
      '3': '.flit.v1.CreateSessionResponse'
    },
    {
      '1': 'ListSessions',
      '2': '.flit.v1.ListSessionsRequest',
      '3': '.flit.v1.ListSessionsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetSession',
      '2': '.flit.v1.GetSessionRequest',
      '3': '.flit.v1.GetSessionResponse',
      '4': {'34': 1},
    },
    {
      '1': 'Attach',
      '2': '.flit.v1.AttachRequest',
      '3': '.flit.v1.AttachResponse',
      '6': true
    },
    {'1': 'Send', '2': '.flit.v1.SendRequest', '3': '.flit.v1.SendResponse'},
    {
      '1': 'EditQueuedMessage',
      '2': '.flit.v1.EditQueuedMessageRequest',
      '3': '.flit.v1.EditQueuedMessageResponse'
    },
    {
      '1': 'CancelQueuedMessage',
      '2': '.flit.v1.CancelQueuedMessageRequest',
      '3': '.flit.v1.CancelQueuedMessageResponse'
    },
    {
      '1': 'Interrupt',
      '2': '.flit.v1.InterruptRequest',
      '3': '.flit.v1.InterruptResponse'
    },
    {
      '1': 'RetryModelCall',
      '2': '.flit.v1.RetryModelCallRequest',
      '3': '.flit.v1.RetryModelCallResponse'
    },
    {
      '1': 'EndReasoning',
      '2': '.flit.v1.EndReasoningRequest',
      '3': '.flit.v1.EndReasoningResponse'
    },
    {
      '1': 'Compact',
      '2': '.flit.v1.CompactRequest',
      '3': '.flit.v1.CompactResponse'
    },
    {
      '1': 'AnswerPrompt',
      '2': '.flit.v1.AnswerPromptRequest',
      '3': '.flit.v1.AnswerPromptResponse'
    },
    {
      '1': 'SetModel',
      '2': '.flit.v1.SetModelRequest',
      '3': '.flit.v1.SetModelResponse'
    },
    {
      '1': 'SetEffort',
      '2': '.flit.v1.SetEffortRequest',
      '3': '.flit.v1.SetEffortResponse'
    },
    {
      '1': 'SetRole',
      '2': '.flit.v1.SetRoleRequest',
      '3': '.flit.v1.SetRoleResponse'
    },
    {
      '1': 'SetYolo',
      '2': '.flit.v1.SetYoloRequest',
      '3': '.flit.v1.SetYoloResponse'
    },
    {
      '1': 'MoveSession',
      '2': '.flit.v1.MoveSessionRequest',
      '3': '.flit.v1.MoveSessionResponse'
    },
    {'1': 'Rate', '2': '.flit.v1.RateRequest', '3': '.flit.v1.RateResponse'},
    {
      '1': 'ListMcpServers',
      '2': '.flit.v1.ListMcpServersRequest',
      '3': '.flit.v1.ListMcpServersResponse',
      '4': {'34': 1},
    },
    {
      '1': 'SetMcpServer',
      '2': '.flit.v1.SetMcpServerRequest',
      '3': '.flit.v1.SetMcpServerResponse'
    },
    {
      '1': 'ListSkills',
      '2': '.flit.v1.ListSkillsRequest',
      '3': '.flit.v1.ListSkillsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'RetryFromMessage',
      '2': '.flit.v1.RetryFromMessageRequest',
      '3': '.flit.v1.RetryFromMessageResponse'
    },
    {
      '1': 'EditMessage',
      '2': '.flit.v1.EditMessageRequest',
      '3': '.flit.v1.EditMessageResponse'
    },
    {
      '1': 'SwitchBranch',
      '2': '.flit.v1.SwitchBranchRequest',
      '3': '.flit.v1.SwitchBranchResponse'
    },
    {
      '1': 'GitStatus',
      '2': '.flit.v1.GitStatusRequest',
      '3': '.flit.v1.GitStatusResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GitDiff',
      '2': '.flit.v1.GitDiffRequest',
      '3': '.flit.v1.GitDiffResponse',
      '4': {'34': 1},
    },
    {
      '1': 'RemoveWorktree',
      '2': '.flit.v1.RemoveWorktreeRequest',
      '3': '.flit.v1.RemoveWorktreeResponse'
    },
  ],
};

@$core.Deprecated('Use sessionServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SessionServiceBase$messageJson = {
  '.flit.v1.CreateSessionRequest': CreateSessionRequest$json,
  '.flit.v1.CreateSessionResponse': CreateSessionResponse$json,
  '.flit.v1.Session': Session$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.flit.v1.ListSessionsRequest': ListSessionsRequest$json,
  '.flit.v1.ListSessionsResponse': ListSessionsResponse$json,
  '.flit.v1.GetSessionRequest': GetSessionRequest$json,
  '.flit.v1.GetSessionResponse': GetSessionResponse$json,
  '.flit.v1.AttachRequest': AttachRequest$json,
  '.flit.v1.AttachResponse': AttachResponse$json,
  '.flit.v1.Event': Event$json,
  '.flit.v1.MessageStarted': MessageStarted$json,
  '.flit.v1.TextDelta': TextDelta$json,
  '.flit.v1.ReasoningDelta': ReasoningDelta$json,
  '.flit.v1.MessageDone': MessageDone$json,
  '.flit.v1.ToolCallStarted': ToolCallStarted$json,
  '.flit.v1.ToolOutput': ToolOutput$json,
  '.flit.v1.ToolCallDone': ToolCallDone$json,
  '.flit.v1.PromptRequested': PromptRequested$json,
  '.flit.v1.PromptResolved': PromptResolved$json,
  '.flit.v1.TaskStateChanged': TaskStateChanged$json,
  '.flit.v1.ModelChanged': ModelChanged$json,
  '.flit.v1.Usage': Usage$json,
  '.flit.v1.TurnError': TurnError$json,
  '.flit.v1.TodoUpdated': TodoUpdated$json,
  '.flit.v1.TodoItem': TodoItem$json,
  '.flit.v1.Feedback': Feedback$json,
  '.flit.v1.McpServersChanged': McpServersChanged$json,
  '.flit.v1.SessionMoved': SessionMoved$json,
  '.flit.v1.YoloChanged': YoloChanged$json,
  '.flit.v1.PermissionCheck': PermissionCheck$json,
  '.flit.v1.ModelCallStarted': ModelCallStarted$json,
  '.flit.v1.PromptProgress': PromptProgress$json,
  '.flit.v1.ModelCallEnded': ModelCallEnded$json,
  '.flit.v1.ModelServerState': ModelServerState$json,
  '.flit.v1.LlamaSlot': LlamaSlot$json,
  '.flit.v1.MessageQueued': MessageQueued$json,
  '.flit.v1.QueuedMessageUpdated': QueuedMessageUpdated$json,
  '.flit.v1.QueuedMessageDelivered': QueuedMessageDelivered$json,
  '.flit.v1.ModelCallWaiting': ModelCallWaiting$json,
  '.flit.v1.PromptCache': PromptCache$json,
  '.flit.v1.ReasoningEndRequested': ReasoningEndRequested$json,
  '.flit.v1.ReasoningEndIgnored': ReasoningEndIgnored$json,
  '.flit.v1.CompactionStarted': CompactionStarted$json,
  '.flit.v1.CompactionDone': CompactionDone$json,
  '.flit.v1.BranchCreated': BranchCreated$json,
  '.flit.v1.BranchSwitched': BranchSwitched$json,
  '.flit.v1.CronRunStarted': CronRunStarted$json,
  '.flit.v1.SubagentStarted': SubagentStarted$json,
  '.flit.v1.SubagentEvent': SubagentEvent$json,
  '.flit.v1.SubagentDone': SubagentDone$json,
  '.flit.v1.WorktreeCreated': WorktreeCreated$json,
  '.flit.v1.WorktreeCopy': WorktreeCopy$json,
  '.flit.v1.WorktreeSkipped': WorktreeSkipped$json,
  '.flit.v1.WorktreeRemoved': WorktreeRemoved$json,
  '.flit.v1.WorktreeKept': WorktreeKept$json,
  '.flit.v1.WebhookRunStarted': WebhookRunStarted$json,
  '.flit.v1.RoleChanged': RoleChanged$json,
  '.flit.v1.SendRequest': SendRequest$json,
  '.flit.v1.SendResponse': SendResponse$json,
  '.flit.v1.EditQueuedMessageRequest': EditQueuedMessageRequest$json,
  '.flit.v1.EditQueuedMessageResponse': EditQueuedMessageResponse$json,
  '.flit.v1.CancelQueuedMessageRequest': CancelQueuedMessageRequest$json,
  '.flit.v1.CancelQueuedMessageResponse': CancelQueuedMessageResponse$json,
  '.flit.v1.InterruptRequest': InterruptRequest$json,
  '.flit.v1.InterruptResponse': InterruptResponse$json,
  '.flit.v1.RetryModelCallRequest': RetryModelCallRequest$json,
  '.flit.v1.RetryModelCallResponse': RetryModelCallResponse$json,
  '.flit.v1.EndReasoningRequest': EndReasoningRequest$json,
  '.flit.v1.EndReasoningResponse': EndReasoningResponse$json,
  '.flit.v1.CompactRequest': CompactRequest$json,
  '.flit.v1.CompactResponse': CompactResponse$json,
  '.flit.v1.AnswerPromptRequest': AnswerPromptRequest$json,
  '.flit.v1.AnswerPromptResponse': AnswerPromptResponse$json,
  '.flit.v1.SetModelRequest': SetModelRequest$json,
  '.flit.v1.SetModelResponse': SetModelResponse$json,
  '.flit.v1.SetEffortRequest': SetEffortRequest$json,
  '.flit.v1.SetEffortResponse': SetEffortResponse$json,
  '.flit.v1.SetRoleRequest': SetRoleRequest$json,
  '.flit.v1.SetRoleResponse': SetRoleResponse$json,
  '.flit.v1.SetYoloRequest': SetYoloRequest$json,
  '.flit.v1.SetYoloResponse': SetYoloResponse$json,
  '.flit.v1.MoveSessionRequest': MoveSessionRequest$json,
  '.flit.v1.MoveSessionResponse': MoveSessionResponse$json,
  '.flit.v1.RateRequest': RateRequest$json,
  '.flit.v1.RateResponse': RateResponse$json,
  '.flit.v1.ListMcpServersRequest': ListMcpServersRequest$json,
  '.flit.v1.ListMcpServersResponse': ListMcpServersResponse$json,
  '.flit.v1.McpServer': McpServer$json,
  '.flit.v1.SetMcpServerRequest': SetMcpServerRequest$json,
  '.flit.v1.SetMcpServerResponse': SetMcpServerResponse$json,
  '.flit.v1.ListSkillsRequest': ListSkillsRequest$json,
  '.flit.v1.ListSkillsResponse': ListSkillsResponse$json,
  '.flit.v1.Skill': Skill$json,
  '.flit.v1.RetryFromMessageRequest': RetryFromMessageRequest$json,
  '.flit.v1.RetryFromMessageResponse': RetryFromMessageResponse$json,
  '.flit.v1.EditMessageRequest': EditMessageRequest$json,
  '.flit.v1.EditMessageResponse': EditMessageResponse$json,
  '.flit.v1.SwitchBranchRequest': SwitchBranchRequest$json,
  '.flit.v1.SwitchBranchResponse': SwitchBranchResponse$json,
  '.flit.v1.GitStatusRequest': GitStatusRequest$json,
  '.flit.v1.GitStatusResponse': GitStatusResponse$json,
  '.flit.v1.GitFileChange': GitFileChange$json,
  '.flit.v1.GitDiffRequest': GitDiffRequest$json,
  '.flit.v1.GitDiffResponse': GitDiffResponse$json,
  '.flit.v1.RemoveWorktreeRequest': RemoveWorktreeRequest$json,
  '.flit.v1.RemoveWorktreeResponse': RemoveWorktreeResponse$json,
};

/// Descriptor for `SessionService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List sessionServiceDescriptor = $convert.base64Decode(
    'Cg5TZXNzaW9uU2VydmljZRJOCg1DcmVhdGVTZXNzaW9uEh0uZmxpdC52MS5DcmVhdGVTZXNzaW'
    '9uUmVxdWVzdBoeLmZsaXQudjEuQ3JlYXRlU2Vzc2lvblJlc3BvbnNlElAKDExpc3RTZXNzaW9u'
    'cxIcLmZsaXQudjEuTGlzdFNlc3Npb25zUmVxdWVzdBodLmZsaXQudjEuTGlzdFNlc3Npb25zUm'
    'VzcG9uc2UiA5ACARJKCgpHZXRTZXNzaW9uEhouZmxpdC52MS5HZXRTZXNzaW9uUmVxdWVzdBob'
    'LmZsaXQudjEuR2V0U2Vzc2lvblJlc3BvbnNlIgOQAgESOwoGQXR0YWNoEhYuZmxpdC52MS5BdH'
    'RhY2hSZXF1ZXN0GhcuZmxpdC52MS5BdHRhY2hSZXNwb25zZTABEjMKBFNlbmQSFC5mbGl0LnYx'
    'LlNlbmRSZXF1ZXN0GhUuZmxpdC52MS5TZW5kUmVzcG9uc2USWgoRRWRpdFF1ZXVlZE1lc3NhZ2'
    'USIS5mbGl0LnYxLkVkaXRRdWV1ZWRNZXNzYWdlUmVxdWVzdBoiLmZsaXQudjEuRWRpdFF1ZXVl'
    'ZE1lc3NhZ2VSZXNwb25zZRJgChNDYW5jZWxRdWV1ZWRNZXNzYWdlEiMuZmxpdC52MS5DYW5jZW'
    'xRdWV1ZWRNZXNzYWdlUmVxdWVzdBokLmZsaXQudjEuQ2FuY2VsUXVldWVkTWVzc2FnZVJlc3Bv'
    'bnNlEkIKCUludGVycnVwdBIZLmZsaXQudjEuSW50ZXJydXB0UmVxdWVzdBoaLmZsaXQudjEuSW'
    '50ZXJydXB0UmVzcG9uc2USUQoOUmV0cnlNb2RlbENhbGwSHi5mbGl0LnYxLlJldHJ5TW9kZWxD'
    'YWxsUmVxdWVzdBofLmZsaXQudjEuUmV0cnlNb2RlbENhbGxSZXNwb25zZRJLCgxFbmRSZWFzb2'
    '5pbmcSHC5mbGl0LnYxLkVuZFJlYXNvbmluZ1JlcXVlc3QaHS5mbGl0LnYxLkVuZFJlYXNvbmlu'
    'Z1Jlc3BvbnNlEjwKB0NvbXBhY3QSFy5mbGl0LnYxLkNvbXBhY3RSZXF1ZXN0GhguZmxpdC52MS'
    '5Db21wYWN0UmVzcG9uc2USSwoMQW5zd2VyUHJvbXB0EhwuZmxpdC52MS5BbnN3ZXJQcm9tcHRS'
    'ZXF1ZXN0Gh0uZmxpdC52MS5BbnN3ZXJQcm9tcHRSZXNwb25zZRI/CghTZXRNb2RlbBIYLmZsaX'
    'QudjEuU2V0TW9kZWxSZXF1ZXN0GhkuZmxpdC52MS5TZXRNb2RlbFJlc3BvbnNlEkIKCVNldEVm'
    'Zm9ydBIZLmZsaXQudjEuU2V0RWZmb3J0UmVxdWVzdBoaLmZsaXQudjEuU2V0RWZmb3J0UmVzcG'
    '9uc2USPAoHU2V0Um9sZRIXLmZsaXQudjEuU2V0Um9sZVJlcXVlc3QaGC5mbGl0LnYxLlNldFJv'
    'bGVSZXNwb25zZRI8CgdTZXRZb2xvEhcuZmxpdC52MS5TZXRZb2xvUmVxdWVzdBoYLmZsaXQudj'
    'EuU2V0WW9sb1Jlc3BvbnNlEkgKC01vdmVTZXNzaW9uEhsuZmxpdC52MS5Nb3ZlU2Vzc2lvblJl'
    'cXVlc3QaHC5mbGl0LnYxLk1vdmVTZXNzaW9uUmVzcG9uc2USMwoEUmF0ZRIULmZsaXQudjEuUm'
    'F0ZVJlcXVlc3QaFS5mbGl0LnYxLlJhdGVSZXNwb25zZRJWCg5MaXN0TWNwU2VydmVycxIeLmZs'
    'aXQudjEuTGlzdE1jcFNlcnZlcnNSZXF1ZXN0Gh8uZmxpdC52MS5MaXN0TWNwU2VydmVyc1Jlc3'
    'BvbnNlIgOQAgESSwoMU2V0TWNwU2VydmVyEhwuZmxpdC52MS5TZXRNY3BTZXJ2ZXJSZXF1ZXN0'
    'Gh0uZmxpdC52MS5TZXRNY3BTZXJ2ZXJSZXNwb25zZRJKCgpMaXN0U2tpbGxzEhouZmxpdC52MS'
    '5MaXN0U2tpbGxzUmVxdWVzdBobLmZsaXQudjEuTGlzdFNraWxsc1Jlc3BvbnNlIgOQAgESVwoQ'
    'UmV0cnlGcm9tTWVzc2FnZRIgLmZsaXQudjEuUmV0cnlGcm9tTWVzc2FnZVJlcXVlc3QaIS5mbG'
    'l0LnYxLlJldHJ5RnJvbU1lc3NhZ2VSZXNwb25zZRJICgtFZGl0TWVzc2FnZRIbLmZsaXQudjEu'
    'RWRpdE1lc3NhZ2VSZXF1ZXN0GhwuZmxpdC52MS5FZGl0TWVzc2FnZVJlc3BvbnNlEksKDFN3aX'
    'RjaEJyYW5jaBIcLmZsaXQudjEuU3dpdGNoQnJhbmNoUmVxdWVzdBodLmZsaXQudjEuU3dpdGNo'
    'QnJhbmNoUmVzcG9uc2USRwoJR2l0U3RhdHVzEhkuZmxpdC52MS5HaXRTdGF0dXNSZXF1ZXN0Gh'
    'ouZmxpdC52MS5HaXRTdGF0dXNSZXNwb25zZSIDkAIBEkEKB0dpdERpZmYSFy5mbGl0LnYxLkdp'
    'dERpZmZSZXF1ZXN0GhguZmxpdC52MS5HaXREaWZmUmVzcG9uc2UiA5ACARJRCg5SZW1vdmVXb3'
    'JrdHJlZRIeLmZsaXQudjEuUmVtb3ZlV29ya3RyZWVSZXF1ZXN0Gh8uZmxpdC52MS5SZW1vdmVX'
    'b3JrdHJlZVJlc3BvbnNl');
