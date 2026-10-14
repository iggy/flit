// This is a generated file - do not edit.
//
// Generated from flit/v1/system.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'system.pb.dart' as $0;
import 'system.pbjson.dart';

export 'system.pb.dart';

abstract class SystemServiceBase extends $pb.GeneratedService {
  $async.Future<$0.VersionResponse> version(
      $pb.ServerContext ctx, $0.VersionRequest request);
  $async.Future<$0.HealthResponse> health(
      $pb.ServerContext ctx, $0.HealthRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Version':
        return $0.VersionRequest();
      case 'Health':
        return $0.HealthRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Version':
        return version(ctx, request as $0.VersionRequest);
      case 'Health':
        return health(ctx, request as $0.HealthRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SystemServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SystemServiceBase$messageJson;
}
