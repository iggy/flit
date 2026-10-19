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
  ],
};

/// Descriptor for `ModelCallOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelCallOutcomeDescriptor = $convert.base64Decode(
    'ChBNb2RlbENhbGxPdXRjb21lEiIKHk1PREVMX0NBTExfT1VUQ09NRV9VTlNQRUNJRklFRBAAEh'
    'kKFU1PREVMX0NBTExfT1VUQ09NRV9PSxABEh4KGk1PREVMX0NBTExfT1VUQ09NRV9TVEFMTEVE'
    'EAISHAoYTU9ERUxfQ0FMTF9PVVRDT01FX0VSUk9SEAMSIAocTU9ERUxfQ0FMTF9PVVRDT01FX0'
    'NBTkNFTExFRBAE');

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
  ],
};

/// Descriptor for `SendRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendRequestDescriptor = $convert.base64Decode(
    'CgtTZW5kUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSEgoEdGV4dBgCIA'
    'EoCVIEdGV4dA==');

@$core.Deprecated('Use sendResponseDescriptor instead')
const SendResponse$json = {
  '1': 'SendResponse',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
  ],
};

/// Descriptor for `SendResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendResponseDescriptor =
    $convert.base64Decode('CgxTZW5kUmVzcG9uc2USEAoDc2VxGAEgASgDUgNzZXE=');

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
    'ZBgfIAEoCzIXLmZsaXQudjEuTW9kZWxDYWxsRW5kZWRIAFIObW9kZWxDYWxsRW5kZWRCCQoHcG'
    'F5bG9hZA==');

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
    'dTb3VyY2U=');

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
    'hSCXdpbGxSZXRyeQ==');

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
      '1': 'Interrupt',
      '2': '.flit.v1.InterruptRequest',
      '3': '.flit.v1.InterruptResponse'
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
  '.flit.v1.SendRequest': SendRequest$json,
  '.flit.v1.SendResponse': SendResponse$json,
  '.flit.v1.InterruptRequest': InterruptRequest$json,
  '.flit.v1.InterruptResponse': InterruptResponse$json,
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
    'LlNlbmRSZXF1ZXN0GhUuZmxpdC52MS5TZW5kUmVzcG9uc2USQgoJSW50ZXJydXB0EhkuZmxpdC'
    '52MS5JbnRlcnJ1cHRSZXF1ZXN0GhouZmxpdC52MS5JbnRlcnJ1cHRSZXNwb25zZRJLCgxBbnN3'
    'ZXJQcm9tcHQSHC5mbGl0LnYxLkFuc3dlclByb21wdFJlcXVlc3QaHS5mbGl0LnYxLkFuc3dlcl'
    'Byb21wdFJlc3BvbnNlEj8KCFNldE1vZGVsEhguZmxpdC52MS5TZXRNb2RlbFJlcXVlc3QaGS5m'
    'bGl0LnYxLlNldE1vZGVsUmVzcG9uc2USQgoJU2V0RWZmb3J0EhkuZmxpdC52MS5TZXRFZmZvcn'
    'RSZXF1ZXN0GhouZmxpdC52MS5TZXRFZmZvcnRSZXNwb25zZRI8CgdTZXRZb2xvEhcuZmxpdC52'
    'MS5TZXRZb2xvUmVxdWVzdBoYLmZsaXQudjEuU2V0WW9sb1Jlc3BvbnNlEkgKC01vdmVTZXNzaW'
    '9uEhsuZmxpdC52MS5Nb3ZlU2Vzc2lvblJlcXVlc3QaHC5mbGl0LnYxLk1vdmVTZXNzaW9uUmVz'
    'cG9uc2USMwoEUmF0ZRIULmZsaXQudjEuUmF0ZVJlcXVlc3QaFS5mbGl0LnYxLlJhdGVSZXNwb2'
    '5zZRJWCg5MaXN0TWNwU2VydmVycxIeLmZsaXQudjEuTGlzdE1jcFNlcnZlcnNSZXF1ZXN0Gh8u'
    'ZmxpdC52MS5MaXN0TWNwU2VydmVyc1Jlc3BvbnNlIgOQAgESSwoMU2V0TWNwU2VydmVyEhwuZm'
    'xpdC52MS5TZXRNY3BTZXJ2ZXJSZXF1ZXN0Gh0uZmxpdC52MS5TZXRNY3BTZXJ2ZXJSZXNwb25z'
    'ZRJKCgpMaXN0U2tpbGxzEhouZmxpdC52MS5MaXN0U2tpbGxzUmVxdWVzdBobLmZsaXQudjEuTG'
    'lzdFNraWxsc1Jlc3BvbnNlIgOQAgE=');
