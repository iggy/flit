// This is a generated file - do not edit.
//
// Generated from flit/v1/system.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class HealthResponse_Status extends $pb.ProtobufEnum {
  static const HealthResponse_Status STATUS_UNSPECIFIED =
      HealthResponse_Status._(0, _omitEnumNames ? '' : 'STATUS_UNSPECIFIED');
  static const HealthResponse_Status STATUS_SERVING =
      HealthResponse_Status._(1, _omitEnumNames ? '' : 'STATUS_SERVING');
  static const HealthResponse_Status STATUS_NOT_SERVING =
      HealthResponse_Status._(2, _omitEnumNames ? '' : 'STATUS_NOT_SERVING');

  static const $core.List<HealthResponse_Status> values =
      <HealthResponse_Status>[
    STATUS_UNSPECIFIED,
    STATUS_SERVING,
    STATUS_NOT_SERVING,
  ];

  static final $core.List<HealthResponse_Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static HealthResponse_Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HealthResponse_Status._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
