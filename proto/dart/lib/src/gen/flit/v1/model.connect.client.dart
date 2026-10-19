//
//  Generated code. Do not modify.
//  source: flit/v1/model.proto
//

import "package:connectrpc/connect.dart" as connect;
import "model.pb.dart" as flitv1model;
import "model.connect.spec.dart" as specs;

/// ModelService lists the models flit can use. Models are discovered from
/// each configured provider's /models endpoint (there is no built-in model
/// database) and can be corrected or filled in by a YAML override file.
/// Discovery runs when the server starts and on Refresh.
extension type ModelServiceClient (connect.Transport _transport) {
  /// ListProviders lists the configured providers and how discovery went.
  Future<flitv1model.ListProvidersResponse> listProviders(
    flitv1model.ListProvidersRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ModelService.listProviders,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// ListModels lists the discovered models, optionally for one provider.
  Future<flitv1model.ListModelsResponse> listModels(
    flitv1model.ListModelsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ModelService.listModels,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Refresh re-runs discovery (and re-reads the override file).
  Future<flitv1model.RefreshResponse> refresh(
    flitv1model.RefreshRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ModelService.refresh,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetFavorite stars or unstars a model. Favorites (and recently used
  /// models) are kept on the server, so every device sees the same ones.
  Future<flitv1model.SetFavoriteResponse> setFavorite(
    flitv1model.SetFavoriteRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ModelService.setFavorite,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// LoadModel and UnloadModel ask a llama.cpp router (Provider
  /// can_load_models) to load or unload a model, then refresh that
  /// provider. Other providers return FAILED_PRECONDITION.
  Future<flitv1model.LoadModelResponse> loadModel(
    flitv1model.LoadModelRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ModelService.loadModel,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<flitv1model.UnloadModelResponse> unloadModel(
    flitv1model.UnloadModelRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ModelService.unloadModel,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
