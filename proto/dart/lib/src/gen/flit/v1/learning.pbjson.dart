// This is a generated file - do not edit.
//
// Generated from flit/v1/learning.proto.

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

@$core.Deprecated('Use learnActionDescriptor instead')
const LearnAction$json = {
  '1': 'LearnAction',
  '2': [
    {'1': 'LEARN_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'LEARN_ACTION_ADD', '2': 1},
    {'1': 'LEARN_ACTION_UPDATE', '2': 2},
    {'1': 'LEARN_ACTION_REMOVE', '2': 3},
  ],
};

/// Descriptor for `LearnAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List learnActionDescriptor = $convert.base64Decode(
    'CgtMZWFybkFjdGlvbhIcChhMRUFSTl9BQ1RJT05fVU5TUEVDSUZJRUQQABIUChBMRUFSTl9BQ1'
    'RJT05fQUREEAESFwoTTEVBUk5fQUNUSU9OX1VQREFURRACEhcKE0xFQVJOX0FDVElPTl9SRU1P'
    'VkUQAw==');

@$core.Deprecated('Use learnTargetDescriptor instead')
const LearnTarget$json = {
  '1': 'LearnTarget',
  '2': [
    {'1': 'LEARN_TARGET_UNSPECIFIED', '2': 0},
    {'1': 'LEARN_TARGET_USER', '2': 1},
    {'1': 'LEARN_TARGET_PROJECT', '2': 2},
    {'1': 'LEARN_TARGET_ROLE', '2': 3},
    {'1': 'LEARN_TARGET_SKILL', '2': 4},
  ],
};

/// Descriptor for `LearnTarget`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List learnTargetDescriptor = $convert.base64Decode(
    'CgtMZWFyblRhcmdldBIcChhMRUFSTl9UQVJHRVRfVU5TUEVDSUZJRUQQABIVChFMRUFSTl9UQV'
    'JHRVRfVVNFUhABEhgKFExFQVJOX1RBUkdFVF9QUk9KRUNUEAISFQoRTEVBUk5fVEFSR0VUX1JP'
    'TEUQAxIWChJMRUFSTl9UQVJHRVRfU0tJTEwQBA==');

@$core.Deprecated('Use learnStatusDescriptor instead')
const LearnStatus$json = {
  '1': 'LearnStatus',
  '2': [
    {'1': 'LEARN_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'LEARN_STATUS_PENDING', '2': 1},
    {'1': 'LEARN_STATUS_ACCEPTED', '2': 2},
    {'1': 'LEARN_STATUS_REJECTED', '2': 3},
  ],
};

/// Descriptor for `LearnStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List learnStatusDescriptor = $convert.base64Decode(
    'CgtMZWFyblN0YXR1cxIcChhMRUFSTl9TVEFUVVNfVU5TUEVDSUZJRUQQABIYChRMRUFSTl9TVE'
    'FUVVNfUEVORElORxABEhkKFUxFQVJOX1NUQVRVU19BQ0NFUFRFRBACEhkKFUxFQVJOX1NUQVRV'
    'U19SRUpFQ1RFRBAD');

@$core.Deprecated('Use learnProposalDescriptor instead')
const LearnProposal$json = {
  '1': 'LearnProposal',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'project_id', '3': 3, '4': 1, '5': 9, '10': 'projectId'},
    {
      '1': 'action',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.LearnAction',
      '10': 'action'
    },
    {
      '1': 'target',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.LearnTarget',
      '10': 'target'
    },
    {'1': 'skill', '3': 6, '4': 1, '5': 9, '10': 'skill'},
    {'1': 'cue', '3': 7, '4': 1, '5': 9, '10': 'cue'},
    {'1': 'lesson', '3': 8, '4': 1, '5': 9, '10': 'lesson'},
    {'1': 'evidence', '3': 9, '4': 1, '5': 9, '10': 'evidence'},
    {'1': 'old_text', '3': 10, '4': 1, '5': 9, '10': 'oldText'},
    {'1': 'new_text', '3': 11, '4': 1, '5': 9, '10': 'newText'},
    {'1': 'path', '3': 12, '4': 1, '5': 9, '10': 'path'},
    {'1': 'provider', '3': 13, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 14, '4': 1, '5': 9, '10': 'model'},
    {
      '1': 'status',
      '3': 15,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.LearnStatus',
      '10': 'status'
    },
    {'1': 'created_at_ms', '3': 16, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'decided_at_ms', '3': 17, '4': 1, '5': 3, '10': 'decidedAtMs'},
  ],
};

/// Descriptor for `LearnProposal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List learnProposalDescriptor = $convert.base64Decode(
    'Cg1MZWFyblByb3Bvc2FsEg4KAmlkGAEgASgJUgJpZBIdCgpzZXNzaW9uX2lkGAIgASgJUglzZX'
    'NzaW9uSWQSHQoKcHJvamVjdF9pZBgDIAEoCVIJcHJvamVjdElkEiwKBmFjdGlvbhgEIAEoDjIU'
    'LmZsaXQudjEuTGVhcm5BY3Rpb25SBmFjdGlvbhIsCgZ0YXJnZXQYBSABKA4yFC5mbGl0LnYxLk'
    'xlYXJuVGFyZ2V0UgZ0YXJnZXQSFAoFc2tpbGwYBiABKAlSBXNraWxsEhAKA2N1ZRgHIAEoCVID'
    'Y3VlEhYKBmxlc3NvbhgIIAEoCVIGbGVzc29uEhoKCGV2aWRlbmNlGAkgASgJUghldmlkZW5jZR'
    'IZCghvbGRfdGV4dBgKIAEoCVIHb2xkVGV4dBIZCghuZXdfdGV4dBgLIAEoCVIHbmV3VGV4dBIS'
    'CgRwYXRoGAwgASgJUgRwYXRoEhoKCHByb3ZpZGVyGA0gASgJUghwcm92aWRlchIUCgVtb2RlbB'
    'gOIAEoCVIFbW9kZWwSLAoGc3RhdHVzGA8gASgOMhQuZmxpdC52MS5MZWFyblN0YXR1c1IGc3Rh'
    'dHVzEiIKDWNyZWF0ZWRfYXRfbXMYECABKANSC2NyZWF0ZWRBdE1zEiIKDWRlY2lkZWRfYXRfbX'
    'MYESABKANSC2RlY2lkZWRBdE1z');

@$core.Deprecated('Use learnRequestDescriptor instead')
const LearnRequest$json = {
  '1': 'LearnRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `LearnRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List learnRequestDescriptor = $convert.base64Decode(
    'CgxMZWFyblJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use learnResponseDescriptor instead')
const LearnResponse$json = {
  '1': 'LearnResponse',
  '2': [
    {
      '1': 'proposals',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.LearnProposal',
      '10': 'proposals'
    },
    {'1': 'dropped', '3': 2, '4': 3, '5': 9, '10': 'dropped'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `LearnResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List learnResponseDescriptor = $convert.base64Decode(
    'Cg1MZWFyblJlc3BvbnNlEjQKCXByb3Bvc2FscxgBIAMoCzIWLmZsaXQudjEuTGVhcm5Qcm9wb3'
    'NhbFIJcHJvcG9zYWxzEhgKB2Ryb3BwZWQYAiADKAlSB2Ryb3BwZWQSGgoIcHJvdmlkZXIYAyAB'
    'KAlSCHByb3ZpZGVyEhQKBW1vZGVsGAQgASgJUgVtb2RlbA==');

@$core.Deprecated('Use listLearnProposalsRequestDescriptor instead')
const ListLearnProposalsRequest$json = {
  '1': 'ListLearnProposalsRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'include_decided', '3': 2, '4': 1, '5': 8, '10': 'includeDecided'},
  ],
};

/// Descriptor for `ListLearnProposalsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listLearnProposalsRequestDescriptor =
    $convert.base64Decode(
        'ChlMaXN0TGVhcm5Qcm9wb3NhbHNSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb2'
        '5JZBInCg9pbmNsdWRlX2RlY2lkZWQYAiABKAhSDmluY2x1ZGVEZWNpZGVk');

@$core.Deprecated('Use listLearnProposalsResponseDescriptor instead')
const ListLearnProposalsResponse$json = {
  '1': 'ListLearnProposalsResponse',
  '2': [
    {
      '1': 'proposals',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.LearnProposal',
      '10': 'proposals'
    },
  ],
};

/// Descriptor for `ListLearnProposalsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listLearnProposalsResponseDescriptor =
    $convert.base64Decode(
        'ChpMaXN0TGVhcm5Qcm9wb3NhbHNSZXNwb25zZRI0Cglwcm9wb3NhbHMYASADKAsyFi5mbGl0Ln'
        'YxLkxlYXJuUHJvcG9zYWxSCXByb3Bvc2Fscw==');

@$core.Deprecated('Use acceptLearnProposalRequestDescriptor instead')
const AcceptLearnProposalRequest$json = {
  '1': 'AcceptLearnProposalRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'text', '17': true},
  ],
  '8': [
    {'1': '_text'},
  ],
};

/// Descriptor for `AcceptLearnProposalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acceptLearnProposalRequestDescriptor =
    $convert.base64Decode(
        'ChpBY2NlcHRMZWFyblByb3Bvc2FsUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSFwoEdGV4dBgCIA'
        'EoCUgAUgR0ZXh0iAEBQgcKBV90ZXh0');

@$core.Deprecated('Use acceptLearnProposalResponseDescriptor instead')
const AcceptLearnProposalResponse$json = {
  '1': 'AcceptLearnProposalResponse',
  '2': [
    {
      '1': 'proposal',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.LearnProposal',
      '10': 'proposal'
    },
  ],
};

/// Descriptor for `AcceptLearnProposalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acceptLearnProposalResponseDescriptor =
    $convert.base64Decode(
        'ChtBY2NlcHRMZWFyblByb3Bvc2FsUmVzcG9uc2USMgoIcHJvcG9zYWwYASABKAsyFi5mbGl0Ln'
        'YxLkxlYXJuUHJvcG9zYWxSCHByb3Bvc2Fs');

@$core.Deprecated('Use rejectLearnProposalRequestDescriptor instead')
const RejectLearnProposalRequest$json = {
  '1': 'RejectLearnProposalRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `RejectLearnProposalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rejectLearnProposalRequestDescriptor =
    $convert.base64Decode(
        'ChpSZWplY3RMZWFyblByb3Bvc2FsUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use rejectLearnProposalResponseDescriptor instead')
const RejectLearnProposalResponse$json = {
  '1': 'RejectLearnProposalResponse',
  '2': [
    {
      '1': 'proposal',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.LearnProposal',
      '10': 'proposal'
    },
  ],
};

/// Descriptor for `RejectLearnProposalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rejectLearnProposalResponseDescriptor =
    $convert.base64Decode(
        'ChtSZWplY3RMZWFyblByb3Bvc2FsUmVzcG9uc2USMgoIcHJvcG9zYWwYASABKAsyFi5mbGl0Ln'
        'YxLkxlYXJuUHJvcG9zYWxSCHByb3Bvc2Fs');

const $core.Map<$core.String, $core.dynamic> LearningServiceBase$json = {
  '1': 'LearningService',
  '2': [
    {'1': 'Learn', '2': '.flit.v1.LearnRequest', '3': '.flit.v1.LearnResponse'},
    {
      '1': 'ListLearnProposals',
      '2': '.flit.v1.ListLearnProposalsRequest',
      '3': '.flit.v1.ListLearnProposalsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'AcceptLearnProposal',
      '2': '.flit.v1.AcceptLearnProposalRequest',
      '3': '.flit.v1.AcceptLearnProposalResponse'
    },
    {
      '1': 'RejectLearnProposal',
      '2': '.flit.v1.RejectLearnProposalRequest',
      '3': '.flit.v1.RejectLearnProposalResponse'
    },
  ],
};

@$core.Deprecated('Use learningServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    LearningServiceBase$messageJson = {
  '.flit.v1.LearnRequest': LearnRequest$json,
  '.flit.v1.LearnResponse': LearnResponse$json,
  '.flit.v1.LearnProposal': LearnProposal$json,
  '.flit.v1.ListLearnProposalsRequest': ListLearnProposalsRequest$json,
  '.flit.v1.ListLearnProposalsResponse': ListLearnProposalsResponse$json,
  '.flit.v1.AcceptLearnProposalRequest': AcceptLearnProposalRequest$json,
  '.flit.v1.AcceptLearnProposalResponse': AcceptLearnProposalResponse$json,
  '.flit.v1.RejectLearnProposalRequest': RejectLearnProposalRequest$json,
  '.flit.v1.RejectLearnProposalResponse': RejectLearnProposalResponse$json,
};

/// Descriptor for `LearningService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List learningServiceDescriptor = $convert.base64Decode(
    'Cg9MZWFybmluZ1NlcnZpY2USNgoFTGVhcm4SFS5mbGl0LnYxLkxlYXJuUmVxdWVzdBoWLmZsaX'
    'QudjEuTGVhcm5SZXNwb25zZRJiChJMaXN0TGVhcm5Qcm9wb3NhbHMSIi5mbGl0LnYxLkxpc3RM'
    'ZWFyblByb3Bvc2Fsc1JlcXVlc3QaIy5mbGl0LnYxLkxpc3RMZWFyblByb3Bvc2Fsc1Jlc3Bvbn'
    'NlIgOQAgESYAoTQWNjZXB0TGVhcm5Qcm9wb3NhbBIjLmZsaXQudjEuQWNjZXB0TGVhcm5Qcm9w'
    'b3NhbFJlcXVlc3QaJC5mbGl0LnYxLkFjY2VwdExlYXJuUHJvcG9zYWxSZXNwb25zZRJgChNSZW'
    'plY3RMZWFyblByb3Bvc2FsEiMuZmxpdC52MS5SZWplY3RMZWFyblByb3Bvc2FsUmVxdWVzdBok'
    'LmZsaXQudjEuUmVqZWN0TGVhcm5Qcm9wb3NhbFJlc3BvbnNl');
