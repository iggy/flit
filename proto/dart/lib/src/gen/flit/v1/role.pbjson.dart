// This is a generated file - do not edit.
//
// Generated from flit/v1/role.proto.

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

@$core.Deprecated('Use agentRoleDescriptor instead')
const AgentRole$json = {
  '1': 'AgentRole',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
    {'1': 'effort', '3': 5, '4': 1, '5': 9, '10': 'effort'},
    {'1': 'memory_file', '3': 6, '4': 1, '5': 9, '10': 'memoryFile'},
    {'1': 'error', '3': 7, '4': 1, '5': 9, '10': 'error'},
    {'1': 'builtin', '3': 8, '4': 1, '5': 8, '10': 'builtin'},
  ],
};

/// Descriptor for `AgentRole`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentRoleDescriptor = $convert.base64Decode(
    'CglBZ2VudFJvbGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIgCgtkZXNjcmlwdGlvbhgCIAEoCVILZG'
    'VzY3JpcHRpb24SGgoIcHJvdmlkZXIYAyABKAlSCHByb3ZpZGVyEhQKBW1vZGVsGAQgASgJUgVt'
    'b2RlbBIWCgZlZmZvcnQYBSABKAlSBmVmZm9ydBIfCgttZW1vcnlfZmlsZRgGIAEoCVIKbWVtb3'
    'J5RmlsZRIUCgVlcnJvchgHIAEoCVIFZXJyb3ISGAoHYnVpbHRpbhgIIAEoCFIHYnVpbHRpbg==');

@$core.Deprecated('Use listRolesRequestDescriptor instead')
const ListRolesRequest$json = {
  '1': 'ListRolesRequest',
};

/// Descriptor for `ListRolesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRolesRequestDescriptor =
    $convert.base64Decode('ChBMaXN0Um9sZXNSZXF1ZXN0');

@$core.Deprecated('Use listRolesResponseDescriptor instead')
const ListRolesResponse$json = {
  '1': 'ListRolesResponse',
  '2': [
    {
      '1': 'roles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.AgentRole',
      '10': 'roles'
    },
  ],
};

/// Descriptor for `ListRolesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRolesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Um9sZXNSZXNwb25zZRIoCgVyb2xlcxgBIAMoCzISLmZsaXQudjEuQWdlbnRSb2xlUg'
    'Vyb2xlcw==');

const $core.Map<$core.String, $core.dynamic> RoleServiceBase$json = {
  '1': 'RoleService',
  '2': [
    {
      '1': 'ListRoles',
      '2': '.flit.v1.ListRolesRequest',
      '3': '.flit.v1.ListRolesResponse',
      '4': {'34': 1},
    },
  ],
};

@$core.Deprecated('Use roleServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    RoleServiceBase$messageJson = {
  '.flit.v1.ListRolesRequest': ListRolesRequest$json,
  '.flit.v1.ListRolesResponse': ListRolesResponse$json,
  '.flit.v1.AgentRole': AgentRole$json,
};

/// Descriptor for `RoleService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List roleServiceDescriptor = $convert.base64Decode(
    'CgtSb2xlU2VydmljZRJHCglMaXN0Um9sZXMSGS5mbGl0LnYxLkxpc3RSb2xlc1JlcXVlc3QaGi'
    '5mbGl0LnYxLkxpc3RSb2xlc1Jlc3BvbnNlIgOQAgE=');
