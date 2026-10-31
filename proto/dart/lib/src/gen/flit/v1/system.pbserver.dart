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

import 'system.pb.dart' as $2;
import 'system.pbjson.dart';

export 'system.pb.dart';

abstract class SystemServiceBase extends $pb.GeneratedService {
  $async.Future<$2.VersionResponse> version(
      $pb.ServerContext ctx, $2.VersionRequest request);
  $async.Future<$2.HealthResponse> health(
      $pb.ServerContext ctx, $2.HealthRequest request);
  $async.Future<$2.CreatePairingCodeResponse> createPairingCode(
      $pb.ServerContext ctx, $2.CreatePairingCodeRequest request);
  $async.Future<$2.PairResponse> pair(
      $pb.ServerContext ctx, $2.PairRequest request);
  $async.Future<$2.ListDevicesResponse> listDevices(
      $pb.ServerContext ctx, $2.ListDevicesRequest request);
  $async.Future<$2.RevokeDeviceResponse> revokeDevice(
      $pb.ServerContext ctx, $2.RevokeDeviceRequest request);
  $async.Future<$2.DebugDumpResponse> debugDump(
      $pb.ServerContext ctx, $2.DebugDumpRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Version':
        return $2.VersionRequest();
      case 'Health':
        return $2.HealthRequest();
      case 'CreatePairingCode':
        return $2.CreatePairingCodeRequest();
      case 'Pair':
        return $2.PairRequest();
      case 'ListDevices':
        return $2.ListDevicesRequest();
      case 'RevokeDevice':
        return $2.RevokeDeviceRequest();
      case 'DebugDump':
        return $2.DebugDumpRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Version':
        return version(ctx, request as $2.VersionRequest);
      case 'Health':
        return health(ctx, request as $2.HealthRequest);
      case 'CreatePairingCode':
        return createPairingCode(ctx, request as $2.CreatePairingCodeRequest);
      case 'Pair':
        return pair(ctx, request as $2.PairRequest);
      case 'ListDevices':
        return listDevices(ctx, request as $2.ListDevicesRequest);
      case 'RevokeDevice':
        return revokeDevice(ctx, request as $2.RevokeDeviceRequest);
      case 'DebugDump':
        return debugDump(ctx, request as $2.DebugDumpRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SystemServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SystemServiceBase$messageJson;
}
