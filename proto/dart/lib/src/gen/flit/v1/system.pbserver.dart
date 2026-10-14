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

import 'system.pb.dart' as $1;
import 'system.pbjson.dart';

export 'system.pb.dart';

abstract class SystemServiceBase extends $pb.GeneratedService {
  $async.Future<$1.VersionResponse> version(
      $pb.ServerContext ctx, $1.VersionRequest request);
  $async.Future<$1.HealthResponse> health(
      $pb.ServerContext ctx, $1.HealthRequest request);
  $async.Future<$1.CreatePairingCodeResponse> createPairingCode(
      $pb.ServerContext ctx, $1.CreatePairingCodeRequest request);
  $async.Future<$1.PairResponse> pair(
      $pb.ServerContext ctx, $1.PairRequest request);
  $async.Future<$1.ListDevicesResponse> listDevices(
      $pb.ServerContext ctx, $1.ListDevicesRequest request);
  $async.Future<$1.RevokeDeviceResponse> revokeDevice(
      $pb.ServerContext ctx, $1.RevokeDeviceRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Version':
        return $1.VersionRequest();
      case 'Health':
        return $1.HealthRequest();
      case 'CreatePairingCode':
        return $1.CreatePairingCodeRequest();
      case 'Pair':
        return $1.PairRequest();
      case 'ListDevices':
        return $1.ListDevicesRequest();
      case 'RevokeDevice':
        return $1.RevokeDeviceRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Version':
        return version(ctx, request as $1.VersionRequest);
      case 'Health':
        return health(ctx, request as $1.HealthRequest);
      case 'CreatePairingCode':
        return createPairingCode(ctx, request as $1.CreatePairingCodeRequest);
      case 'Pair':
        return pair(ctx, request as $1.PairRequest);
      case 'ListDevices':
        return listDevices(ctx, request as $1.ListDevicesRequest);
      case 'RevokeDevice':
        return revokeDevice(ctx, request as $1.RevokeDeviceRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SystemServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SystemServiceBase$messageJson;
}
