// This is a generated file - do not edit.
//
// Generated from flit/v1/model.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'model.pb.dart' as $1;
import 'model.pbjson.dart';

export 'model.pb.dart';

abstract class ModelServiceBase extends $pb.GeneratedService {
  $async.Future<$1.ListProvidersResponse> listProviders(
      $pb.ServerContext ctx, $1.ListProvidersRequest request);
  $async.Future<$1.ListModelsResponse> listModels(
      $pb.ServerContext ctx, $1.ListModelsRequest request);
  $async.Future<$1.RefreshResponse> refresh(
      $pb.ServerContext ctx, $1.RefreshRequest request);
  $async.Future<$1.SetFavoriteResponse> setFavorite(
      $pb.ServerContext ctx, $1.SetFavoriteRequest request);
  $async.Future<$1.LoadModelResponse> loadModel(
      $pb.ServerContext ctx, $1.LoadModelRequest request);
  $async.Future<$1.UnloadModelResponse> unloadModel(
      $pb.ServerContext ctx, $1.UnloadModelRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListProviders':
        return $1.ListProvidersRequest();
      case 'ListModels':
        return $1.ListModelsRequest();
      case 'Refresh':
        return $1.RefreshRequest();
      case 'SetFavorite':
        return $1.SetFavoriteRequest();
      case 'LoadModel':
        return $1.LoadModelRequest();
      case 'UnloadModel':
        return $1.UnloadModelRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListProviders':
        return listProviders(ctx, request as $1.ListProvidersRequest);
      case 'ListModels':
        return listModels(ctx, request as $1.ListModelsRequest);
      case 'Refresh':
        return refresh(ctx, request as $1.RefreshRequest);
      case 'SetFavorite':
        return setFavorite(ctx, request as $1.SetFavoriteRequest);
      case 'LoadModel':
        return loadModel(ctx, request as $1.LoadModelRequest);
      case 'UnloadModel':
        return unloadModel(ctx, request as $1.UnloadModelRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ModelServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => ModelServiceBase$messageJson;
}
