// This is a generated file - do not edit.
//
// Generated from flit/v1/model.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ProviderKind is how flit reads a provider's /models response. AUTO
/// detects it from the URL and the response.
class ProviderKind extends $pb.ProtobufEnum {
  static const ProviderKind PROVIDER_KIND_UNSPECIFIED =
      ProviderKind._(0, _omitEnumNames ? '' : 'PROVIDER_KIND_UNSPECIFIED');
  static const ProviderKind PROVIDER_KIND_OPENAI =
      ProviderKind._(1, _omitEnumNames ? '' : 'PROVIDER_KIND_OPENAI');
  static const ProviderKind PROVIDER_KIND_OPENROUTER =
      ProviderKind._(2, _omitEnumNames ? '' : 'PROVIDER_KIND_OPENROUTER');
  static const ProviderKind PROVIDER_KIND_LLAMACPP =
      ProviderKind._(3, _omitEnumNames ? '' : 'PROVIDER_KIND_LLAMACPP');
  static const ProviderKind PROVIDER_KIND_GOMODEL =
      ProviderKind._(4, _omitEnumNames ? '' : 'PROVIDER_KIND_GOMODEL');

  static const $core.List<ProviderKind> values = <ProviderKind>[
    PROVIDER_KIND_UNSPECIFIED,
    PROVIDER_KIND_OPENAI,
    PROVIDER_KIND_OPENROUTER,
    PROVIDER_KIND_LLAMACPP,
    PROVIDER_KIND_GOMODEL,
  ];

  static final $core.List<ProviderKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ProviderKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProviderKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
