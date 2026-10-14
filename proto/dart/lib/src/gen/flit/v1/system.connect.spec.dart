//
//  Generated code. Do not modify.
//  source: flit/v1/system.proto
//

import "package:connectrpc/connect.dart" as connect;
import "system.pb.dart" as flitv1system;

/// SystemService reports on the flit server itself. Like every flit RPC it
/// requires the server's auth token, even on localhost.
abstract final class SystemService {
  /// Fully-qualified name of the SystemService service.
  static const name = 'flit.v1.SystemService';

  /// Version returns build and API version information for the server.
  static const version = connect.Spec(
    '/$name/Version',
    connect.StreamType.unary,
    flitv1system.VersionRequest.new,
    flitv1system.VersionResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// Health reports whether the server is able to serve requests.
  static const health = connect.Spec(
    '/$name/Health',
    connect.StreamType.unary,
    flitv1system.HealthRequest.new,
    flitv1system.HealthResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );
}
