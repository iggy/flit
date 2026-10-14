//
//  Generated code. Do not modify.
//  source: flit/v1/system.proto
//

import "package:connectrpc/connect.dart" as connect;
import "system.pb.dart" as flitv1system;
import "system.connect.spec.dart" as specs;

/// SystemService reports on the flit server itself. Like every flit RPC it
/// requires the server's auth token, even on localhost.
extension type SystemServiceClient (connect.Transport _transport) {
  /// Version returns build and API version information for the server.
  Future<flitv1system.VersionResponse> version(
    flitv1system.VersionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.version,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Health reports whether the server is able to serve requests.
  Future<flitv1system.HealthResponse> health(
    flitv1system.HealthRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.health,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
