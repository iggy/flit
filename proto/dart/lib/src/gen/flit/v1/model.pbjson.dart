// This is a generated file - do not edit.
//
// Generated from flit/v1/model.proto.

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

@$core.Deprecated('Use providerKindDescriptor instead')
const ProviderKind$json = {
  '1': 'ProviderKind',
  '2': [
    {'1': 'PROVIDER_KIND_UNSPECIFIED', '2': 0},
    {'1': 'PROVIDER_KIND_OPENAI', '2': 1},
    {'1': 'PROVIDER_KIND_OPENROUTER', '2': 2},
    {'1': 'PROVIDER_KIND_LLAMACPP', '2': 3},
    {'1': 'PROVIDER_KIND_GOMODEL', '2': 4},
  ],
};

/// Descriptor for `ProviderKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List providerKindDescriptor = $convert.base64Decode(
    'CgxQcm92aWRlcktpbmQSHQoZUFJPVklERVJfS0lORF9VTlNQRUNJRklFRBAAEhgKFFBST1ZJRE'
    'VSX0tJTkRfT1BFTkFJEAESHAoYUFJPVklERVJfS0lORF9PUEVOUk9VVEVSEAISGgoWUFJPVklE'
    'RVJfS0lORF9MTEFNQUNQUBADEhkKFVBST1ZJREVSX0tJTkRfR09NT0RFTBAE');

@$core.Deprecated('Use modelStateDescriptor instead')
const ModelState$json = {
  '1': 'ModelState',
  '2': [
    {'1': 'MODEL_STATE_UNSPECIFIED', '2': 0},
    {'1': 'MODEL_STATE_UNLOADED', '2': 1},
    {'1': 'MODEL_STATE_LOADING', '2': 2},
    {'1': 'MODEL_STATE_LOADED', '2': 3},
    {'1': 'MODEL_STATE_SLEEPING', '2': 4},
    {'1': 'MODEL_STATE_FAILED', '2': 5},
  ],
};

/// Descriptor for `ModelState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modelStateDescriptor = $convert.base64Decode(
    'CgpNb2RlbFN0YXRlEhsKF01PREVMX1NUQVRFX1VOU1BFQ0lGSUVEEAASGAoUTU9ERUxfU1RBVE'
    'VfVU5MT0FERUQQARIXChNNT0RFTF9TVEFURV9MT0FESU5HEAISFgoSTU9ERUxfU1RBVEVfTE9B'
    'REVEEAMSGAoUTU9ERUxfU1RBVEVfU0xFRVBJTkcQBBIWChJNT0RFTF9TVEFURV9GQUlMRUQQBQ'
    '==');

@$core.Deprecated('Use providerDescriptor instead')
const Provider$json = {
  '1': 'Provider',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'base_url', '3': 2, '4': 1, '5': 9, '10': 'baseUrl'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.ProviderKind',
      '10': 'kind'
    },
    {'1': 'model_count', '3': 4, '4': 1, '5': 5, '10': 'modelCount'},
    {
      '1': 'refresh_time',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'refreshTime'
    },
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
    {'1': 'can_load_models', '3': 7, '4': 1, '5': 8, '10': 'canLoadModels'},
  ],
};

/// Descriptor for `Provider`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List providerDescriptor = $convert.base64Decode(
    'CghQcm92aWRlchISCgRuYW1lGAEgASgJUgRuYW1lEhkKCGJhc2VfdXJsGAIgASgJUgdiYXNlVX'
    'JsEikKBGtpbmQYAyABKA4yFS5mbGl0LnYxLlByb3ZpZGVyS2luZFIEa2luZBIfCgttb2RlbF9j'
    'b3VudBgEIAEoBVIKbW9kZWxDb3VudBI9CgxyZWZyZXNoX3RpbWUYBSABKAsyGi5nb29nbGUucH'
    'JvdG9idWYuVGltZXN0YW1wUgtyZWZyZXNoVGltZRIUCgVlcnJvchgGIAEoCVIFZXJyb3ISJgoP'
    'Y2FuX2xvYWRfbW9kZWxzGAcgASgIUg1jYW5Mb2FkTW9kZWxz');

@$core.Deprecated('Use modelDescriptor instead')
const Model$json = {
  '1': 'Model',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'context_length', '3': 4, '4': 1, '5': 3, '10': 'contextLength'},
    {'1': 'supports_tools', '3': 5, '4': 1, '5': 8, '10': 'supportsTools'},
    {
      '1': 'supports_reasoning',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'supportsReasoning'
    },
    {'1': 'supports_vision', '3': 7, '4': 1, '5': 8, '10': 'supportsVision'},
    {'1': 'efforts', '3': 8, '4': 3, '5': 9, '10': 'efforts'},
    {'1': 'loaded', '3': 9, '4': 1, '5': 8, '10': 'loaded'},
    {'1': 'discovered', '3': 10, '4': 1, '5': 8, '10': 'discovered'},
    {'1': 'overridden', '3': 11, '4': 1, '5': 8, '10': 'overridden'},
    {'1': 'favorite', '3': 12, '4': 1, '5': 8, '10': 'favorite'},
    {
      '1': 'last_used',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUsed'
    },
    {
      '1': 'state',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.ModelState',
      '10': 'state'
    },
  ],
};

/// Descriptor for `Model`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelDescriptor = $convert.base64Decode(
    'CgVNb2RlbBIaCghwcm92aWRlchgBIAEoCVIIcHJvdmlkZXISDgoCaWQYAiABKAlSAmlkEiEKDG'
    'Rpc3BsYXlfbmFtZRgDIAEoCVILZGlzcGxheU5hbWUSJQoOY29udGV4dF9sZW5ndGgYBCABKANS'
    'DWNvbnRleHRMZW5ndGgSJQoOc3VwcG9ydHNfdG9vbHMYBSABKAhSDXN1cHBvcnRzVG9vbHMSLQ'
    'oSc3VwcG9ydHNfcmVhc29uaW5nGAYgASgIUhFzdXBwb3J0c1JlYXNvbmluZxInCg9zdXBwb3J0'
    'c192aXNpb24YByABKAhSDnN1cHBvcnRzVmlzaW9uEhgKB2VmZm9ydHMYCCADKAlSB2VmZm9ydH'
    'MSFgoGbG9hZGVkGAkgASgIUgZsb2FkZWQSHgoKZGlzY292ZXJlZBgKIAEoCFIKZGlzY292ZXJl'
    'ZBIeCgpvdmVycmlkZGVuGAsgASgIUgpvdmVycmlkZGVuEhoKCGZhdm9yaXRlGAwgASgIUghmYX'
    'Zvcml0ZRI3CglsYXN0X3VzZWQYDSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUghs'
    'YXN0VXNlZBIpCgVzdGF0ZRgOIAEoDjITLmZsaXQudjEuTW9kZWxTdGF0ZVIFc3RhdGU=');

@$core.Deprecated('Use listProvidersRequestDescriptor instead')
const ListProvidersRequest$json = {
  '1': 'ListProvidersRequest',
};

/// Descriptor for `ListProvidersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProvidersRequestDescriptor =
    $convert.base64Decode('ChRMaXN0UHJvdmlkZXJzUmVxdWVzdA==');

@$core.Deprecated('Use listProvidersResponseDescriptor instead')
const ListProvidersResponse$json = {
  '1': 'ListProvidersResponse',
  '2': [
    {
      '1': 'providers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Provider',
      '10': 'providers'
    },
  ],
};

/// Descriptor for `ListProvidersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listProvidersResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0UHJvdmlkZXJzUmVzcG9uc2USLwoJcHJvdmlkZXJzGAEgAygLMhEuZmxpdC52MS5Qcm'
    '92aWRlclIJcHJvdmlkZXJz');

@$core.Deprecated('Use listModelsRequestDescriptor instead')
const ListModelsRequest$json = {
  '1': 'ListModelsRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
  ],
};

/// Descriptor for `ListModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsRequestDescriptor = $convert.base64Decode(
    'ChFMaXN0TW9kZWxzUmVxdWVzdBIaCghwcm92aWRlchgBIAEoCVIIcHJvdmlkZXI=');

@$core.Deprecated('Use listModelsResponseDescriptor instead')
const ListModelsResponse$json = {
  '1': 'ListModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Model',
      '10': 'models'
    },
  ],
};

/// Descriptor for `ListModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0TW9kZWxzUmVzcG9uc2USJgoGbW9kZWxzGAEgAygLMg4uZmxpdC52MS5Nb2RlbFIGbW'
    '9kZWxz');

@$core.Deprecated('Use refreshRequestDescriptor instead')
const RefreshRequest$json = {
  '1': 'RefreshRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
  ],
};

/// Descriptor for `RefreshRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshRequestDescriptor = $convert.base64Decode(
    'Cg5SZWZyZXNoUmVxdWVzdBIaCghwcm92aWRlchgBIAEoCVIIcHJvdmlkZXI=');

@$core.Deprecated('Use refreshResponseDescriptor instead')
const RefreshResponse$json = {
  '1': 'RefreshResponse',
  '2': [
    {
      '1': 'providers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.Provider',
      '10': 'providers'
    },
  ],
};

/// Descriptor for `RefreshResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshResponseDescriptor = $convert.base64Decode(
    'Cg9SZWZyZXNoUmVzcG9uc2USLwoJcHJvdmlkZXJzGAEgAygLMhEuZmxpdC52MS5Qcm92aWRlcl'
    'IJcHJvdmlkZXJz');

@$core.Deprecated('Use setFavoriteRequestDescriptor instead')
const SetFavoriteRequest$json = {
  '1': 'SetFavoriteRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
    {'1': 'favorite', '3': 3, '4': 1, '5': 8, '10': 'favorite'},
  ],
};

/// Descriptor for `SetFavoriteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setFavoriteRequestDescriptor = $convert.base64Decode(
    'ChJTZXRGYXZvcml0ZVJlcXVlc3QSGgoIcHJvdmlkZXIYASABKAlSCHByb3ZpZGVyEhQKBW1vZG'
    'VsGAIgASgJUgVtb2RlbBIaCghmYXZvcml0ZRgDIAEoCFIIZmF2b3JpdGU=');

@$core.Deprecated('Use setFavoriteResponseDescriptor instead')
const SetFavoriteResponse$json = {
  '1': 'SetFavoriteResponse',
};

/// Descriptor for `SetFavoriteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setFavoriteResponseDescriptor =
    $convert.base64Decode('ChNTZXRGYXZvcml0ZVJlc3BvbnNl');

@$core.Deprecated('Use loadModelRequestDescriptor instead')
const LoadModelRequest$json = {
  '1': 'LoadModelRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `LoadModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loadModelRequestDescriptor = $convert.base64Decode(
    'ChBMb2FkTW9kZWxSZXF1ZXN0EhoKCHByb3ZpZGVyGAEgASgJUghwcm92aWRlchIUCgVtb2RlbB'
    'gCIAEoCVIFbW9kZWw=');

@$core.Deprecated('Use loadModelResponseDescriptor instead')
const LoadModelResponse$json = {
  '1': 'LoadModelResponse',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Model',
      '10': 'model'
    },
  ],
};

/// Descriptor for `LoadModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loadModelResponseDescriptor = $convert.base64Decode(
    'ChFMb2FkTW9kZWxSZXNwb25zZRIkCgVtb2RlbBgBIAEoCzIOLmZsaXQudjEuTW9kZWxSBW1vZG'
    'Vs');

@$core.Deprecated('Use unloadModelRequestDescriptor instead')
const UnloadModelRequest$json = {
  '1': 'UnloadModelRequest',
  '2': [
    {'1': 'provider', '3': 1, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `UnloadModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unloadModelRequestDescriptor = $convert.base64Decode(
    'ChJVbmxvYWRNb2RlbFJlcXVlc3QSGgoIcHJvdmlkZXIYASABKAlSCHByb3ZpZGVyEhQKBW1vZG'
    'VsGAIgASgJUgVtb2RlbA==');

@$core.Deprecated('Use unloadModelResponseDescriptor instead')
const UnloadModelResponse$json = {
  '1': 'UnloadModelResponse',
  '2': [
    {
      '1': 'model',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.Model',
      '10': 'model'
    },
  ],
};

/// Descriptor for `UnloadModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unloadModelResponseDescriptor = $convert.base64Decode(
    'ChNVbmxvYWRNb2RlbFJlc3BvbnNlEiQKBW1vZGVsGAEgASgLMg4uZmxpdC52MS5Nb2RlbFIFbW'
    '9kZWw=');

const $core.Map<$core.String, $core.dynamic> ModelServiceBase$json = {
  '1': 'ModelService',
  '2': [
    {
      '1': 'ListProviders',
      '2': '.flit.v1.ListProvidersRequest',
      '3': '.flit.v1.ListProvidersResponse',
      '4': {'34': 1},
    },
    {
      '1': 'ListModels',
      '2': '.flit.v1.ListModelsRequest',
      '3': '.flit.v1.ListModelsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'Refresh',
      '2': '.flit.v1.RefreshRequest',
      '3': '.flit.v1.RefreshResponse'
    },
    {
      '1': 'SetFavorite',
      '2': '.flit.v1.SetFavoriteRequest',
      '3': '.flit.v1.SetFavoriteResponse',
      '4': {'34': 2},
    },
    {
      '1': 'LoadModel',
      '2': '.flit.v1.LoadModelRequest',
      '3': '.flit.v1.LoadModelResponse'
    },
    {
      '1': 'UnloadModel',
      '2': '.flit.v1.UnloadModelRequest',
      '3': '.flit.v1.UnloadModelResponse'
    },
  ],
};

@$core.Deprecated('Use modelServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ModelServiceBase$messageJson = {
  '.flit.v1.ListProvidersRequest': ListProvidersRequest$json,
  '.flit.v1.ListProvidersResponse': ListProvidersResponse$json,
  '.flit.v1.Provider': Provider$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.flit.v1.ListModelsRequest': ListModelsRequest$json,
  '.flit.v1.ListModelsResponse': ListModelsResponse$json,
  '.flit.v1.Model': Model$json,
  '.flit.v1.RefreshRequest': RefreshRequest$json,
  '.flit.v1.RefreshResponse': RefreshResponse$json,
  '.flit.v1.SetFavoriteRequest': SetFavoriteRequest$json,
  '.flit.v1.SetFavoriteResponse': SetFavoriteResponse$json,
  '.flit.v1.LoadModelRequest': LoadModelRequest$json,
  '.flit.v1.LoadModelResponse': LoadModelResponse$json,
  '.flit.v1.UnloadModelRequest': UnloadModelRequest$json,
  '.flit.v1.UnloadModelResponse': UnloadModelResponse$json,
};

/// Descriptor for `ModelService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List modelServiceDescriptor = $convert.base64Decode(
    'CgxNb2RlbFNlcnZpY2USUwoNTGlzdFByb3ZpZGVycxIdLmZsaXQudjEuTGlzdFByb3ZpZGVyc1'
    'JlcXVlc3QaHi5mbGl0LnYxLkxpc3RQcm92aWRlcnNSZXNwb25zZSIDkAIBEkoKCkxpc3RNb2Rl'
    'bHMSGi5mbGl0LnYxLkxpc3RNb2RlbHNSZXF1ZXN0GhsuZmxpdC52MS5MaXN0TW9kZWxzUmVzcG'
    '9uc2UiA5ACARI8CgdSZWZyZXNoEhcuZmxpdC52MS5SZWZyZXNoUmVxdWVzdBoYLmZsaXQudjEu'
    'UmVmcmVzaFJlc3BvbnNlEk0KC1NldEZhdm9yaXRlEhsuZmxpdC52MS5TZXRGYXZvcml0ZVJlcX'
    'Vlc3QaHC5mbGl0LnYxLlNldEZhdm9yaXRlUmVzcG9uc2UiA5ACAhJCCglMb2FkTW9kZWwSGS5m'
    'bGl0LnYxLkxvYWRNb2RlbFJlcXVlc3QaGi5mbGl0LnYxLkxvYWRNb2RlbFJlc3BvbnNlEkgKC1'
    'VubG9hZE1vZGVsEhsuZmxpdC52MS5VbmxvYWRNb2RlbFJlcXVlc3QaHC5mbGl0LnYxLlVubG9h'
    'ZE1vZGVsUmVzcG9uc2U=');
