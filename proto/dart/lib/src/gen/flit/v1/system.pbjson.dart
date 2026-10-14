// This is a generated file - do not edit.
//
// Generated from flit/v1/system.proto.

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

@$core.Deprecated('Use versionRequestDescriptor instead')
const VersionRequest$json = {
  '1': 'VersionRequest',
};

/// Descriptor for `VersionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionRequestDescriptor =
    $convert.base64Decode('Cg5WZXJzaW9uUmVxdWVzdA==');

@$core.Deprecated('Use versionResponseDescriptor instead')
const VersionResponse$json = {
  '1': 'VersionResponse',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'commit', '3': 2, '4': 1, '5': 9, '10': 'commit'},
    {'1': 'build_time', '3': 3, '4': 1, '5': 9, '10': 'buildTime'},
    {'1': 'go_version', '3': 4, '4': 1, '5': 9, '10': 'goVersion'},
    {'1': 'os', '3': 5, '4': 1, '5': 9, '10': 'os'},
    {'1': 'arch', '3': 6, '4': 1, '5': 9, '10': 'arch'},
    {'1': 'api_version', '3': 7, '4': 1, '5': 9, '10': 'apiVersion'},
  ],
};

/// Descriptor for `VersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionResponseDescriptor = $convert.base64Decode(
    'Cg9WZXJzaW9uUmVzcG9uc2USGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhIWCgZjb21taXQYAi'
    'ABKAlSBmNvbW1pdBIdCgpidWlsZF90aW1lGAMgASgJUglidWlsZFRpbWUSHQoKZ29fdmVyc2lv'
    'bhgEIAEoCVIJZ29WZXJzaW9uEg4KAm9zGAUgASgJUgJvcxISCgRhcmNoGAYgASgJUgRhcmNoEh'
    '8KC2FwaV92ZXJzaW9uGAcgASgJUgphcGlWZXJzaW9u');

@$core.Deprecated('Use healthRequestDescriptor instead')
const HealthRequest$json = {
  '1': 'HealthRequest',
};

/// Descriptor for `HealthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthRequestDescriptor =
    $convert.base64Decode('Cg1IZWFsdGhSZXF1ZXN0');

@$core.Deprecated('Use healthResponseDescriptor instead')
const HealthResponse$json = {
  '1': 'HealthResponse',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.HealthResponse.Status',
      '10': 'status'
    },
  ],
  '4': [HealthResponse_Status$json],
};

@$core.Deprecated('Use healthResponseDescriptor instead')
const HealthResponse_Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'STATUS_UNSPECIFIED', '2': 0},
    {'1': 'STATUS_SERVING', '2': 1},
    {'1': 'STATUS_NOT_SERVING', '2': 2},
  ],
};

/// Descriptor for `HealthResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthResponseDescriptor = $convert.base64Decode(
    'Cg5IZWFsdGhSZXNwb25zZRI2CgZzdGF0dXMYASABKA4yHi5mbGl0LnYxLkhlYWx0aFJlc3Bvbn'
    'NlLlN0YXR1c1IGc3RhdHVzIkwKBlN0YXR1cxIWChJTVEFUVVNfVU5TUEVDSUZJRUQQABISCg5T'
    'VEFUVVNfU0VSVklORxABEhYKElNUQVRVU19OT1RfU0VSVklORxAC');

const $core.Map<$core.String, $core.dynamic> SystemServiceBase$json = {
  '1': 'SystemService',
  '2': [
    {
      '1': 'Version',
      '2': '.flit.v1.VersionRequest',
      '3': '.flit.v1.VersionResponse',
      '4': {'34': 1},
    },
    {
      '1': 'Health',
      '2': '.flit.v1.HealthRequest',
      '3': '.flit.v1.HealthResponse',
      '4': {'34': 1},
    },
  ],
};

@$core.Deprecated('Use systemServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SystemServiceBase$messageJson = {
  '.flit.v1.VersionRequest': VersionRequest$json,
  '.flit.v1.VersionResponse': VersionResponse$json,
  '.flit.v1.HealthRequest': HealthRequest$json,
  '.flit.v1.HealthResponse': HealthResponse$json,
};

/// Descriptor for `SystemService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List systemServiceDescriptor = $convert.base64Decode(
    'Cg1TeXN0ZW1TZXJ2aWNlEkEKB1ZlcnNpb24SFy5mbGl0LnYxLlZlcnNpb25SZXF1ZXN0GhguZm'
    'xpdC52MS5WZXJzaW9uUmVzcG9uc2UiA5ACARI+CgZIZWFsdGgSFi5mbGl0LnYxLkhlYWx0aFJl'
    'cXVlc3QaFy5mbGl0LnYxLkhlYWx0aFJlc3BvbnNlIgOQAgE=');
