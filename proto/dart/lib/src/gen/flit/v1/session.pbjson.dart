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
  ],
};

/// Descriptor for `PromptDecision`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List promptDecisionDescriptor = $convert.base64Decode(
    'Cg5Qcm9tcHREZWNpc2lvbhIfChtQUk9NUFRfREVDSVNJT05fVU5TUEVDSUZJRUQQABIZChVQUk'
    '9NUFRfREVDSVNJT05fQUxMT1cQARIYChRQUk9NUFRfREVDSVNJT05fREVOWRAC');

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
    'IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnVwZGF0ZVRpbWU=');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'working_dir', '3': 1, '4': 1, '5': 9, '10': 'workingDir'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBIfCgt3b3JraW5nX2RpchgBIAEoCVIKd29ya2luZ0Rpch'
    'IUCgV0aXRsZRgCIAEoCVIFdGl0bGUSGgoIcHJvdmlkZXIYAyABKAlSCHByb3ZpZGVyEhQKBW1v'
    'ZGVsGAQgASgJUgVtb2RlbA==');

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
  ],
};

/// Descriptor for `ListSessionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSessionsRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0U2Vzc2lvbnNSZXF1ZXN0EhsKCXBhZ2Vfc2l6ZRgBIAEoBVIIcGFnZVNpemUSHQoKcG'
    'FnZV90b2tlbhgCIAEoCVIJcGFnZVRva2Vu');

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
    'bkVycm9ySABSBWVycm9yQgkKB3BheWxvYWQ=');

@$core.Deprecated('Use messageStartedDescriptor instead')
const MessageStarted$json = {
  '1': 'MessageStarted',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'role', '3': 2, '4': 1, '5': 14, '6': '.flit.v1.Role', '10': 'role'},
  ],
};

/// Descriptor for `MessageStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageStartedDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdlU3RhcnRlZBIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSIQoEcm9sZR'
    'gCIAEoDjINLmZsaXQudjEuUm9sZVIEcm9sZQ==');

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
  ],
};

/// Descriptor for `PromptRequested`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptRequestedDescriptor = $convert.base64Decode(
    'Cg9Qcm9tcHRSZXF1ZXN0ZWQSGwoJcHJvbXB0X2lkGAEgASgJUghwcm9tcHRJZBIgCgx0b29sX2'
    'NhbGxfaWQYAiABKAlSCnRvb2xDYWxsSWQSFAoFdGl0bGUYAyABKAlSBXRpdGxlEhYKBmRldGFp'
    'bBgEIAEoCVIGZGV0YWls');

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
  ],
};

/// Descriptor for `PromptResolved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptResolvedDescriptor = $convert.base64Decode(
    'Cg5Qcm9tcHRSZXNvbHZlZBIbCglwcm9tcHRfaWQYASABKAlSCHByb21wdElkEjMKCGRlY2lzaW'
    '9uGAIgASgOMhcuZmxpdC52MS5Qcm9tcHREZWNpc2lvblIIZGVjaXNpb24SFgoGY2xpZW50GAMg'
    'ASgJUgZjbGllbnQSFgoGcmVhc29uGAQgASgJUgZyZWFzb24=');

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
  ],
};

/// Descriptor for `ModelChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelChangedDescriptor = $convert.base64Decode(
    'CgxNb2RlbENoYW5nZWQSGgoIcHJvdmlkZXIYASABKAlSCHByb3ZpZGVyEhQKBW1vZGVsGAIgAS'
    'gJUgVtb2RlbA==');

@$core.Deprecated('Use usageDescriptor instead')
const Usage$json = {
  '1': 'Usage',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'input_tokens', '3': 2, '4': 1, '5': 3, '10': 'inputTokens'},
    {'1': 'output_tokens', '3': 3, '4': 1, '5': 3, '10': 'outputTokens'},
    {'1': 'total_tokens', '3': 4, '4': 1, '5': 3, '10': 'totalTokens'},
  ],
};

/// Descriptor for `Usage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List usageDescriptor = $convert.base64Decode(
    'CgVVc2FnZRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSIQoMaW5wdXRfdG9rZW5zGA'
    'IgASgDUgtpbnB1dFRva2VucxIjCg1vdXRwdXRfdG9rZW5zGAMgASgDUgxvdXRwdXRUb2tlbnMS'
    'IQoMdG90YWxfdG9rZW5zGAQgASgDUgt0b3RhbFRva2Vucw==');

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
  '.flit.v1.SendRequest': SendRequest$json,
  '.flit.v1.SendResponse': SendResponse$json,
  '.flit.v1.InterruptRequest': InterruptRequest$json,
  '.flit.v1.InterruptResponse': InterruptResponse$json,
  '.flit.v1.AnswerPromptRequest': AnswerPromptRequest$json,
  '.flit.v1.AnswerPromptResponse': AnswerPromptResponse$json,
  '.flit.v1.SetModelRequest': SetModelRequest$json,
  '.flit.v1.SetModelResponse': SetModelResponse$json,
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
    'bGl0LnYxLlNldE1vZGVsUmVzcG9uc2U=');
