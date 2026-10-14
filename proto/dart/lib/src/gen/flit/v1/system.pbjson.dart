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

import 'package:protobuf/well_known_types/google/protobuf/timestamp.pbjson.dart'
    as $0;

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

@$core.Deprecated('Use createPairingCodeRequestDescriptor instead')
const CreatePairingCodeRequest$json = {
  '1': 'CreatePairingCodeRequest',
};

/// Descriptor for `CreatePairingCodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPairingCodeRequestDescriptor =
    $convert.base64Decode('ChhDcmVhdGVQYWlyaW5nQ29kZVJlcXVlc3Q=');

@$core.Deprecated('Use createPairingCodeResponseDescriptor instead')
const CreatePairingCodeResponse$json = {
  '1': 'CreatePairingCodeResponse',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {
      '1': 'expire_time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expireTime'
    },
    {'1': 'server_url', '3': 3, '4': 1, '5': 9, '10': 'serverUrl'},
  ],
};

/// Descriptor for `CreatePairingCodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPairingCodeResponseDescriptor = $convert.base64Decode(
    'ChlDcmVhdGVQYWlyaW5nQ29kZVJlc3BvbnNlEhIKBGNvZGUYASABKAlSBGNvZGUSOwoLZXhwaX'
    'JlX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpleHBpcmVUaW1lEh0K'
    'CnNlcnZlcl91cmwYAyABKAlSCXNlcnZlclVybA==');

@$core.Deprecated('Use pairRequestDescriptor instead')
const PairRequest$json = {
  '1': 'PairRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'device_name', '3': 2, '4': 1, '5': 9, '10': 'deviceName'},
  ],
};

/// Descriptor for `PairRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairRequestDescriptor = $convert.base64Decode(
    'CgtQYWlyUmVxdWVzdBISCgRjb2RlGAEgASgJUgRjb2RlEh8KC2RldmljZV9uYW1lGAIgASgJUg'
    'pkZXZpY2VOYW1l');

@$core.Deprecated('Use pairResponseDescriptor instead')
const PairResponse$json = {
  '1': 'PairResponse',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Device',
      '10': 'device'
    },
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `PairResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairResponseDescriptor = $convert.base64Decode(
    'CgxQYWlyUmVzcG9uc2USJwoGZGV2aWNlGAEgASgLMg8uZmxpdC52MS5EZXZpY2VSBmRldmljZR'
    'IUCgV0b2tlbhgCIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use deviceDescriptor instead')
const Device$json = {
  '1': 'Device',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'create_time',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createTime'
    },
    {
      '1': 'last_seen_time',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSeenTime'
    },
    {
      '1': 'revoke_time',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'revokeTime'
    },
  ],
};

/// Descriptor for `Device`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceDescriptor = $convert.base64Decode(
    'CgZEZXZpY2USDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSOwoLY3JlYXRlX3'
    'RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEkAKDmxh'
    'c3Rfc2Vlbl90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMbGFzdFNlZW'
    '5UaW1lEjsKC3Jldm9rZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIK'
    'cmV2b2tlVGltZQ==');

@$core.Deprecated('Use listDevicesRequestDescriptor instead')
const ListDevicesRequest$json = {
  '1': 'ListDevicesRequest',
  '2': [
    {'1': 'include_revoked', '3': 1, '4': 1, '5': 8, '10': 'includeRevoked'},
  ],
};

/// Descriptor for `ListDevicesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDevicesRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0RGV2aWNlc1JlcXVlc3QSJwoPaW5jbHVkZV9yZXZva2VkGAEgASgIUg5pbmNsdWRlUm'
    'V2b2tlZA==');

@$core.Deprecated('Use listDevicesResponseDescriptor instead')
const ListDevicesResponse$json = {
  '1': 'ListDevicesResponse',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Device',
      '10': 'devices'
    },
  ],
};

/// Descriptor for `ListDevicesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDevicesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0RGV2aWNlc1Jlc3BvbnNlEikKB2RldmljZXMYASADKAsyDy5mbGl0LnYxLkRldmljZV'
    'IHZGV2aWNlcw==');

@$core.Deprecated('Use revokeDeviceRequestDescriptor instead')
const RevokeDeviceRequest$json = {
  '1': 'RevokeDeviceRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `RevokeDeviceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeDeviceRequestDescriptor =
    $convert.base64Decode(
        'ChNSZXZva2VEZXZpY2VSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQ=');

@$core.Deprecated('Use revokeDeviceResponseDescriptor instead')
const RevokeDeviceResponse$json = {
  '1': 'RevokeDeviceResponse',
};

/// Descriptor for `RevokeDeviceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeDeviceResponseDescriptor =
    $convert.base64Decode('ChRSZXZva2VEZXZpY2VSZXNwb25zZQ==');

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
    {
      '1': 'CreatePairingCode',
      '2': '.flit.v1.CreatePairingCodeRequest',
      '3': '.flit.v1.CreatePairingCodeResponse'
    },
    {'1': 'Pair', '2': '.flit.v1.PairRequest', '3': '.flit.v1.PairResponse'},
    {
      '1': 'ListDevices',
      '2': '.flit.v1.ListDevicesRequest',
      '3': '.flit.v1.ListDevicesResponse',
      '4': {'34': 1},
    },
    {
      '1': 'RevokeDevice',
      '2': '.flit.v1.RevokeDeviceRequest',
      '3': '.flit.v1.RevokeDeviceResponse'
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
  '.flit.v1.CreatePairingCodeRequest': CreatePairingCodeRequest$json,
  '.flit.v1.CreatePairingCodeResponse': CreatePairingCodeResponse$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.flit.v1.PairRequest': PairRequest$json,
  '.flit.v1.PairResponse': PairResponse$json,
  '.flit.v1.Device': Device$json,
  '.flit.v1.ListDevicesRequest': ListDevicesRequest$json,
  '.flit.v1.ListDevicesResponse': ListDevicesResponse$json,
  '.flit.v1.RevokeDeviceRequest': RevokeDeviceRequest$json,
  '.flit.v1.RevokeDeviceResponse': RevokeDeviceResponse$json,
};

/// Descriptor for `SystemService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List systemServiceDescriptor = $convert.base64Decode(
    'Cg1TeXN0ZW1TZXJ2aWNlEkEKB1ZlcnNpb24SFy5mbGl0LnYxLlZlcnNpb25SZXF1ZXN0GhguZm'
    'xpdC52MS5WZXJzaW9uUmVzcG9uc2UiA5ACARI+CgZIZWFsdGgSFi5mbGl0LnYxLkhlYWx0aFJl'
    'cXVlc3QaFy5mbGl0LnYxLkhlYWx0aFJlc3BvbnNlIgOQAgESWgoRQ3JlYXRlUGFpcmluZ0NvZG'
    'USIS5mbGl0LnYxLkNyZWF0ZVBhaXJpbmdDb2RlUmVxdWVzdBoiLmZsaXQudjEuQ3JlYXRlUGFp'
    'cmluZ0NvZGVSZXNwb25zZRIzCgRQYWlyEhQuZmxpdC52MS5QYWlyUmVxdWVzdBoVLmZsaXQudj'
    'EuUGFpclJlc3BvbnNlEk0KC0xpc3REZXZpY2VzEhsuZmxpdC52MS5MaXN0RGV2aWNlc1JlcXVl'
    'c3QaHC5mbGl0LnYxLkxpc3REZXZpY2VzUmVzcG9uc2UiA5ACARJLCgxSZXZva2VEZXZpY2USHC'
    '5mbGl0LnYxLlJldm9rZURldmljZVJlcXVlc3QaHS5mbGl0LnYxLlJldm9rZURldmljZVJlc3Bv'
    'bnNl');
