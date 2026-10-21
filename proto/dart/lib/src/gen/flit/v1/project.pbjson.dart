// This is a generated file - do not edit.
//
// Generated from flit/v1/project.proto.

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

@$core.Deprecated('Use projectDescriptor instead')
const Project$json = {
  '1': 'Project',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'team_id', '3': 2, '4': 1, '5': 9, '10': 'teamId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'directory', '3': 4, '4': 1, '5': 9, '10': 'directory'},
    {'1': 'session_count', '3': 5, '4': 1, '5': 5, '10': 'sessionCount'},
    {
      '1': 'create_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createTime'
    },
    {'1': 'export_enabled', '3': 7, '4': 1, '5': 8, '10': 'exportEnabled'},
    {
      '1': 'worktrees',
      '3': 8,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'worktrees',
      '17': true
    },
    {
      '1': 'worktrees_enabled',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'worktreesEnabled'
    },
  ],
  '8': [
    {'1': '_worktrees'},
  ],
};

/// Descriptor for `Project`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List projectDescriptor = $convert.base64Decode(
    'CgdQcm9qZWN0Eg4KAmlkGAEgASgJUgJpZBIXCgd0ZWFtX2lkGAIgASgJUgZ0ZWFtSWQSEgoEbm'
    'FtZRgDIAEoCVIEbmFtZRIcCglkaXJlY3RvcnkYBCABKAlSCWRpcmVjdG9yeRIjCg1zZXNzaW9u'
    'X2NvdW50GAUgASgFUgxzZXNzaW9uQ291bnQSOwoLY3JlYXRlX3RpbWUYBiABKAsyGi5nb29nbG'
    'UucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEiUKDmV4cG9ydF9lbmFibGVkGAcgASgI'
    'Ug1leHBvcnRFbmFibGVkEiEKCXdvcmt0cmVlcxgIIAEoCEgAUgl3b3JrdHJlZXOIAQESKwoRd2'
    '9ya3RyZWVzX2VuYWJsZWQYCSABKAhSEHdvcmt0cmVlc0VuYWJsZWRCDAoKX3dvcmt0cmVlcw==');

@$core.Deprecated('Use listProjectsRequestDescriptor instead')
const ListProjectsRequest$json = {
  '1': 'ListProjectsRequest',
};

/// Descriptor for `ListProjectsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProjectsRequestDescriptor =
    $convert.base64Decode('ChNMaXN0UHJvamVjdHNSZXF1ZXN0');

@$core.Deprecated('Use listProjectsResponseDescriptor instead')
const ListProjectsResponse$json = {
  '1': 'ListProjectsResponse',
  '2': [
    {
      '1': 'projects',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Project',
      '10': 'projects'
    },
  ],
};

/// Descriptor for `ListProjectsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProjectsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0UHJvamVjdHNSZXNwb25zZRIsCghwcm9qZWN0cxgBIAMoCzIQLmZsaXQudjEuUHJvam'
    'VjdFIIcHJvamVjdHM=');

@$core.Deprecated('Use createProjectRequestDescriptor instead')
const CreateProjectRequest$json = {
  '1': 'CreateProjectRequest',
  '2': [
    {'1': 'directory', '3': 1, '4': 1, '5': 9, '10': 'directory'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreateProjectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createProjectRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVQcm9qZWN0UmVxdWVzdBIcCglkaXJlY3RvcnkYASABKAlSCWRpcmVjdG9yeRISCg'
    'RuYW1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use createProjectResponseDescriptor instead')
const CreateProjectResponse$json = {
  '1': 'CreateProjectResponse',
  '2': [
    {
      '1': 'project',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Project',
      '10': 'project'
    },
  ],
};

/// Descriptor for `CreateProjectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createProjectResponseDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVQcm9qZWN0UmVzcG9uc2USKgoHcHJvamVjdBgBIAEoCzIQLmZsaXQudjEuUHJvam'
    'VjdFIHcHJvamVjdA==');

@$core.Deprecated('Use setProjectExportRequestDescriptor instead')
const SetProjectExportRequest$json = {
  '1': 'SetProjectExportRequest',
  '2': [
    {'1': 'project_id', '3': 1, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SetProjectExportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setProjectExportRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXRQcm9qZWN0RXhwb3J0UmVxdWVzdBIdCgpwcm9qZWN0X2lkGAEgASgJUglwcm9qZWN0SW'
        'QSGAoHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZA==');

@$core.Deprecated('Use setProjectExportResponseDescriptor instead')
const SetProjectExportResponse$json = {
  '1': 'SetProjectExportResponse',
  '2': [
    {
      '1': 'project',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Project',
      '10': 'project'
    },
  ],
};

/// Descriptor for `SetProjectExportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setProjectExportResponseDescriptor =
    $convert.base64Decode(
        'ChhTZXRQcm9qZWN0RXhwb3J0UmVzcG9uc2USKgoHcHJvamVjdBgBIAEoCzIQLmZsaXQudjEuUH'
        'JvamVjdFIHcHJvamVjdA==');

@$core.Deprecated('Use setProjectWorktreesRequestDescriptor instead')
const SetProjectWorktreesRequest$json = {
  '1': 'SetProjectWorktreesRequest',
  '2': [
    {'1': 'project_id', '3': 1, '4': 1, '5': 9, '10': 'projectId'},
    {
      '1': 'enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enabled',
      '17': true
    },
  ],
  '8': [
    {'1': '_enabled'},
  ],
};

/// Descriptor for `SetProjectWorktreesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setProjectWorktreesRequestDescriptor =
    $convert.base64Decode(
        'ChpTZXRQcm9qZWN0V29ya3RyZWVzUmVxdWVzdBIdCgpwcm9qZWN0X2lkGAEgASgJUglwcm9qZW'
        'N0SWQSHQoHZW5hYmxlZBgCIAEoCEgAUgdlbmFibGVkiAEBQgoKCF9lbmFibGVk');

@$core.Deprecated('Use setProjectWorktreesResponseDescriptor instead')
const SetProjectWorktreesResponse$json = {
  '1': 'SetProjectWorktreesResponse',
  '2': [
    {
      '1': 'project',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Project',
      '10': 'project'
    },
  ],
};

/// Descriptor for `SetProjectWorktreesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setProjectWorktreesResponseDescriptor =
    $convert.base64Decode(
        'ChtTZXRQcm9qZWN0V29ya3RyZWVzUmVzcG9uc2USKgoHcHJvamVjdBgBIAEoCzIQLmZsaXQudj'
        'EuUHJvamVjdFIHcHJvamVjdA==');

const $core.Map<$core.String, $core.dynamic> ProjectServiceBase$json = {
  '1': 'ProjectService',
  '2': [
    {
      '1': 'ListProjects',
      '2': '.flit.v1.ListProjectsRequest',
      '3': '.flit.v1.ListProjectsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'CreateProject',
      '2': '.flit.v1.CreateProjectRequest',
      '3': '.flit.v1.CreateProjectResponse'
    },
    {
      '1': 'SetProjectExport',
      '2': '.flit.v1.SetProjectExportRequest',
      '3': '.flit.v1.SetProjectExportResponse'
    },
    {
      '1': 'SetProjectWorktrees',
      '2': '.flit.v1.SetProjectWorktreesRequest',
      '3': '.flit.v1.SetProjectWorktreesResponse'
    },
  ],
};

@$core.Deprecated('Use projectServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ProjectServiceBase$messageJson = {
  '.flit.v1.ListProjectsRequest': ListProjectsRequest$json,
  '.flit.v1.ListProjectsResponse': ListProjectsResponse$json,
  '.flit.v1.Project': Project$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.flit.v1.CreateProjectRequest': CreateProjectRequest$json,
  '.flit.v1.CreateProjectResponse': CreateProjectResponse$json,
  '.flit.v1.SetProjectExportRequest': SetProjectExportRequest$json,
  '.flit.v1.SetProjectExportResponse': SetProjectExportResponse$json,
  '.flit.v1.SetProjectWorktreesRequest': SetProjectWorktreesRequest$json,
  '.flit.v1.SetProjectWorktreesResponse': SetProjectWorktreesResponse$json,
};

/// Descriptor for `ProjectService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List projectServiceDescriptor = $convert.base64Decode(
    'Cg5Qcm9qZWN0U2VydmljZRJQCgxMaXN0UHJvamVjdHMSHC5mbGl0LnYxLkxpc3RQcm9qZWN0c1'
    'JlcXVlc3QaHS5mbGl0LnYxLkxpc3RQcm9qZWN0c1Jlc3BvbnNlIgOQAgESTgoNQ3JlYXRlUHJv'
    'amVjdBIdLmZsaXQudjEuQ3JlYXRlUHJvamVjdFJlcXVlc3QaHi5mbGl0LnYxLkNyZWF0ZVByb2'
    'plY3RSZXNwb25zZRJXChBTZXRQcm9qZWN0RXhwb3J0EiAuZmxpdC52MS5TZXRQcm9qZWN0RXhw'
    'b3J0UmVxdWVzdBohLmZsaXQudjEuU2V0UHJvamVjdEV4cG9ydFJlc3BvbnNlEmAKE1NldFByb2'
    'plY3RXb3JrdHJlZXMSIy5mbGl0LnYxLlNldFByb2plY3RXb3JrdHJlZXNSZXF1ZXN0GiQuZmxp'
    'dC52MS5TZXRQcm9qZWN0V29ya3RyZWVzUmVzcG9uc2U=');
