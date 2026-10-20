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
  ],
};

/// Descriptor for `ModelWaitReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelWaitReasonDescriptor = $convert.base64Decode(
    'Cg9Nb2RlbFdhaXRSZWFzb24SIQodTU9ERUxfV0FJVF9SRUFTT05fVU5TUEVDSUZJRUQQABIgCh'
    'xNT0RFTF9XQUlUX1JFQVNPTl9TTE9UU19CVVNZEAESHgoaTU9ERUxfV0FJVF9SRUFTT05fU0xF'
    'RVBJTkcQAhIdChlNT0RFTF9XQUlUX1JFQVNPTl9MT0FESU5HEAM=');

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
    'IfCgttY3Bfc2VydmVycxgQIAMoCVIKbWNwU2VydmVycxISCgR5b2xvGBEgASgIUgR5b2xv');

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
  ],
};

/// Descriptor for `ListSessionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0U2Vzc2lvbnNSZXF1ZXN0EhsKCXBhZ2Vfc2l6ZRgBIAEoBVIIcGFnZVNpemUSHQoKcG'
    'FnZV90b2tlbhgCIAEoCVIJcGFnZVRva2VuEh0KCnByb2plY3RfaWQYAyABKAlSCXByb2plY3RJ'
    'ZA==');

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
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEAoDc2VxGAIgASgDUgNzZX'
    'ESLgoEdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBHRpbWUSQgoPbWVz'
    'c2FnZV9zdGFydGVkGAogASgLMhcuZmxpdC52MS5NZXNzYWdlU3RhcnRlZEgAUg5tZXNzYWdlU3'
    'RhcnRlZBIzCgp0ZXh0X2RlbHRhGAsgASgLMhIuZmxpdC52MS5UZXh0RGVsdGFIAFIJdGV4dERl'
    'bHRhEkIKD3JlYXNvbmluZ19kZWx0YRgMIAEoCzIXLmZsaXQudjEuUmVhc29uaW5nRGVsdGFIAF'
    'IOcmVhc29uaW5nRGVsdGESOQoMbWVzc2FnZV9kb25lGA0gASgLMhQuZmxpdC52MS5NZXNzYWdl'
    'RG9uZUgAUgttZXNzYWdlRG9uZRJGChF0b29sX2NhbGxfc3RhcnRlZBgOIAEoCzIYLmZsaXQudj'
    'EuVG9vbENhbGxTdGFydGVkSABSD3Rvb2xDYWxsU3RhcnRlZBI2Cgt0b29sX291dHB1dBgPIAEo'
    'CzITLmZsaXQudjEuVG9vbE91dHB1dEgAUgp0b29sT3V0cHV0Ej0KDnRvb2xfY2FsbF9kb25lGB'
    'AgASgLMhUuZmxpdC52MS5Ub29sQ2FsbERvbmVIAFIMdG9vbENhbGxEb25lEkUKEHByb21wdF9y'
    'ZXF1ZXN0ZWQYESABKAsyGC5mbGl0LnYxLlByb21wdFJlcXVlc3RlZEgAUg9wcm9tcHRSZXF1ZX'
    'N0ZWQSQgoPcHJvbXB0X3Jlc29sdmVkGBIgASgLMhcuZmxpdC52MS5Qcm9tcHRSZXNvbHZlZEgA'
    'Ug5wcm9tcHRSZXNvbHZlZBJJChJ0YXNrX3N0YXRlX2NoYW5nZWQYEyABKAsyGS5mbGl0LnYxLl'
    'Rhc2tTdGF0ZUNoYW5nZWRIAFIQdGFza1N0YXRlQ2hhbmdlZBI8Cg1tb2RlbF9jaGFuZ2VkGBQg'
    'ASgLMhUuZmxpdC52MS5Nb2RlbENoYW5nZWRIAFIMbW9kZWxDaGFuZ2VkEiYKBXVzYWdlGBUgAS'
    'gLMg4uZmxpdC52MS5Vc2FnZUgAUgV1c2FnZRIqCgVlcnJvchgWIAEoCzISLmZsaXQudjEuVHVy'
    'bkVycm9ySABSBWVycm9yEjkKDHRvZG9fdXBkYXRlZBgXIAEoCzIULmZsaXQudjEuVG9kb1VwZG'
    'F0ZWRIAFILdG9kb1VwZGF0ZWQSLwoIZmVlZGJhY2sYGCABKAsyES5mbGl0LnYxLkZlZWRiYWNr'
    'SABSCGZlZWRiYWNrEkwKE21jcF9zZXJ2ZXJzX2NoYW5nZWQYGSABKAsyGi5mbGl0LnYxLk1jcF'
    'NlcnZlcnNDaGFuZ2VkSABSEW1jcFNlcnZlcnNDaGFuZ2VkEjwKDXNlc3Npb25fbW92ZWQYGiAB'
    'KAsyFS5mbGl0LnYxLlNlc3Npb25Nb3ZlZEgAUgxzZXNzaW9uTW92ZWQSOQoMeW9sb19jaGFuZ2'
    'VkGBsgASgLMhQuZmxpdC52MS5Zb2xvQ2hhbmdlZEgAUgt5b2xvQ2hhbmdlZBJFChBwZXJtaXNz'
    'aW9uX2NoZWNrGBwgASgLMhguZmxpdC52MS5QZXJtaXNzaW9uQ2hlY2tIAFIPcGVybWlzc2lvbk'
    'NoZWNrEkkKEm1vZGVsX2NhbGxfc3RhcnRlZBgdIAEoCzIZLmZsaXQudjEuTW9kZWxDYWxsU3Rh'
    'cnRlZEgAUhBtb2RlbENhbGxTdGFydGVkEkIKD3Byb21wdF9wcm9ncmVzcxgeIAEoCzIXLmZsaX'
    'QudjEuUHJvbXB0UHJvZ3Jlc3NIAFIOcHJvbXB0UHJvZ3Jlc3MSQwoQbW9kZWxfY2FsbF9lbmRl'
    'ZBgfIAEoCzIXLmZsaXQudjEuTW9kZWxDYWxsRW5kZWRIAFIObW9kZWxDYWxsRW5kZWQSPwoObW'
    'Vzc2FnZV9xdWV1ZWQYICABKAsyFi5mbGl0LnYxLk1lc3NhZ2VRdWV1ZWRIAFINbWVzc2FnZVF1'
    'ZXVlZBJVChZxdWV1ZWRfbWVzc2FnZV91cGRhdGVkGCEgASgLMh0uZmxpdC52MS5RdWV1ZWRNZX'
    'NzYWdlVXBkYXRlZEgAUhRxdWV1ZWRNZXNzYWdlVXBkYXRlZBJbChhxdWV1ZWRfbWVzc2FnZV9k'
    'ZWxpdmVyZWQYIiABKAsyHy5mbGl0LnYxLlF1ZXVlZE1lc3NhZ2VEZWxpdmVyZWRIAFIWcXVldW'
    'VkTWVzc2FnZURlbGl2ZXJlZBJJChJtb2RlbF9jYWxsX3dhaXRpbmcYIyABKAsyGS5mbGl0LnYx'
    'Lk1vZGVsQ2FsbFdhaXRpbmdIAFIQbW9kZWxDYWxsV2FpdGluZxI5Cgxwcm9tcHRfY2FjaGUYJC'
    'ABKAsyFC5mbGl0LnYxLlByb21wdENhY2hlSABSC3Byb21wdENhY2hlElgKF3JlYXNvbmluZ19l'
    'bmRfcmVxdWVzdGVkGCUgASgLMh4uZmxpdC52MS5SZWFzb25pbmdFbmRSZXF1ZXN0ZWRIAFIVcm'
    'Vhc29uaW5nRW5kUmVxdWVzdGVkElIKFXJlYXNvbmluZ19lbmRfaWdub3JlZBgmIAEoCzIcLmZs'
    'aXQudjEuUmVhc29uaW5nRW5kSWdub3JlZEgAUhNyZWFzb25pbmdFbmRJZ25vcmVkEksKEmNvbX'
    'BhY3Rpb25fc3RhcnRlZBgnIAEoCzIaLmZsaXQudjEuQ29tcGFjdGlvblN0YXJ0ZWRIAFIRY29t'
    'cGFjdGlvblN0YXJ0ZWQSQgoPY29tcGFjdGlvbl9kb25lGCggASgLMhcuZmxpdC52MS5Db21wYW'
    'N0aW9uRG9uZUgAUg5jb21wYWN0aW9uRG9uZUIJCgdwYXlsb2Fk');

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
    'hSCXdpbGxSZXRyeRIjCg1jYWNoZWRfdG9rZW5zGBMgASgDUgxjYWNoZWRUb2tlbnM=');

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
  '.flit.v1.MessageQueued': MessageQueued$json,
  '.flit.v1.QueuedMessageUpdated': QueuedMessageUpdated$json,
  '.flit.v1.QueuedMessageDelivered': QueuedMessageDelivered$json,
  '.flit.v1.ModelCallWaiting': ModelCallWaiting$json,
  '.flit.v1.PromptCache': PromptCache$json,
  '.flit.v1.ReasoningEndRequested': ReasoningEndRequested$json,
  '.flit.v1.ReasoningEndIgnored': ReasoningEndIgnored$json,
  '.flit.v1.CompactionStarted': CompactionStarted$json,
  '.flit.v1.CompactionDone': CompactionDone$json,
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
    '9uc2USPAoHU2V0WW9sbxIXLmZsaXQudjEuU2V0WW9sb1JlcXVlc3QaGC5mbGl0LnYxLlNldFlv'
    'bG9SZXNwb25zZRJICgtNb3ZlU2Vzc2lvbhIbLmZsaXQudjEuTW92ZVNlc3Npb25SZXF1ZXN0Gh'
    'wuZmxpdC52MS5Nb3ZlU2Vzc2lvblJlc3BvbnNlEjMKBFJhdGUSFC5mbGl0LnYxLlJhdGVSZXF1'
    'ZXN0GhUuZmxpdC52MS5SYXRlUmVzcG9uc2USVgoOTGlzdE1jcFNlcnZlcnMSHi5mbGl0LnYxLk'
    'xpc3RNY3BTZXJ2ZXJzUmVxdWVzdBofLmZsaXQudjEuTGlzdE1jcFNlcnZlcnNSZXNwb25zZSID'
    'kAIBEksKDFNldE1jcFNlcnZlchIcLmZsaXQudjEuU2V0TWNwU2VydmVyUmVxdWVzdBodLmZsaX'
    'QudjEuU2V0TWNwU2VydmVyUmVzcG9uc2USSgoKTGlzdFNraWxscxIaLmZsaXQudjEuTGlzdFNr'
    'aWxsc1JlcXVlc3QaGy5mbGl0LnYxLkxpc3RTa2lsbHNSZXNwb25zZSIDkAIB');
