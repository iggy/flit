// This is a generated file - do not edit.
//
// Generated from flit/v1/cron.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'cron.pb.dart' as $1;
import 'cron.pbjson.dart';

export 'cron.pb.dart';

abstract class CronServiceBase extends $pb.GeneratedService {
  $async.Future<$1.ListCronJobsResponse> listCronJobs(
      $pb.ServerContext ctx, $1.ListCronJobsRequest request);
  $async.Future<$1.GetCronJobResponse> getCronJob(
      $pb.ServerContext ctx, $1.GetCronJobRequest request);
  $async.Future<$1.RunCronJobResponse> runCronJob(
      $pb.ServerContext ctx, $1.RunCronJobRequest request);
  $async.Future<$1.SetCronJobEnabledResponse> setCronJobEnabled(
      $pb.ServerContext ctx, $1.SetCronJobEnabledRequest request);
  $async.Future<$1.ListCronRunsResponse> listCronRuns(
      $pb.ServerContext ctx, $1.ListCronRunsRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListCronJobs':
        return $1.ListCronJobsRequest();
      case 'GetCronJob':
        return $1.GetCronJobRequest();
      case 'RunCronJob':
        return $1.RunCronJobRequest();
      case 'SetCronJobEnabled':
        return $1.SetCronJobEnabledRequest();
      case 'ListCronRuns':
        return $1.ListCronRunsRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListCronJobs':
        return listCronJobs(ctx, request as $1.ListCronJobsRequest);
      case 'GetCronJob':
        return getCronJob(ctx, request as $1.GetCronJobRequest);
      case 'RunCronJob':
        return runCronJob(ctx, request as $1.RunCronJobRequest);
      case 'SetCronJobEnabled':
        return setCronJobEnabled(ctx, request as $1.SetCronJobEnabledRequest);
      case 'ListCronRuns':
        return listCronRuns(ctx, request as $1.ListCronRunsRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => CronServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => CronServiceBase$messageJson;
}
