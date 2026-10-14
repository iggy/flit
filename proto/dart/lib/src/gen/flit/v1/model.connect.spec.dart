//
//  Generated code. Do not modify.
//  source: flit/v1/model.proto
//

import "package:connectrpc/connect.dart" as connect;
import "model.pb.dart" as flitv1model;

/// ModelService lists the models flit can use. Models are discovered from
/// each configured provider's /models endpoint (there is no built-in model
/// database) and can be corrected or filled in by a YAML override file.
/// Discovery runs when the server starts and on Refresh.
abstract final class ModelService {
  /// Fully-qualified name of the ModelService service.
  static const name = 'flit.v1.ModelService';

  /// ListProviders lists the configured providers and how discovery went.
  static const listProviders = connect.Spec(
    '/$name/ListProviders',
    connect.StreamType.unary,
    flitv1model.ListProvidersRequest.new,
    flitv1model.ListProvidersResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// ListModels lists the discovered models, optionally for one provider.
  static const listModels = connect.Spec(
    '/$name/ListModels',
    connect.StreamType.unary,
    flitv1model.ListModelsRequest.new,
    flitv1model.ListModelsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// Refresh re-runs discovery (and re-reads the override file).
  static const refresh = connect.Spec(
    '/$name/Refresh',
    connect.StreamType.unary,
    flitv1model.RefreshRequest.new,
    flitv1model.RefreshResponse.new,
  );
}
