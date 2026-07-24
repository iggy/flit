/// Typed errors for the Hermes gateway transport layer.
///
/// Per docs/reference/05-conventions.md: raw `DioException`s and socket
/// errors must never leak into providers; map them to one of these.
library;

/// Base type for every error the data layer surfaces.
sealed class GatewayException implements Exception {
  const GatewayException(this.message, {this.cause});

  /// Human-readable, **token-redacted** description.
  final String message;

  /// The underlying error, if any (never logged with secrets).
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The host could not be reached, or the socket/HTTP request failed at the
/// transport level (DNS, TCP, TLS, WS upgrade refused for network reasons).
class GatewayNetworkException extends GatewayException {
  const GatewayNetworkException(super.message, {super.cause});
}

/// Authentication failed: HTTP 401/403 on REST, or a WS close code 4401/4403
/// on connect. Bad token, or host/origin not allowed.
class GatewayAuthException extends GatewayException {
  const GatewayAuthException(super.message, {this.closeCode, super.cause});

  /// WS close code when applicable (4401 bad credential, 4403 forbidden).
  final int? closeCode;
}

/// The gateway returned a JSON-RPC error frame `{code, message}`.
class GatewayRpcException extends GatewayException {
  const GatewayRpcException(this.code, super.message, {super.cause});

  /// JSON-RPC error code (e.g. -32601 unknown method, 4009 no pending
  /// answer request, -32700 parse error).
  final int code;
}

/// A request exceeded its timeout (default 120s; long handlers exist —
/// see docs/reference/01-gateway-protocol.md §11).
class GatewayTimeoutException extends GatewayException {
  const GatewayTimeoutException(super.message, {super.cause});
}

/// A frame or HTTP body could not be parsed as the expected shape.
class GatewayParseException extends GatewayException {
  const GatewayParseException(super.message, {super.cause});
}

/// The WebSocket closed while requests were in flight, or a request was
/// attempted against a closed/connecting client.
class GatewayClosedException extends GatewayException {
  const GatewayClosedException(super.message, {super.cause});
}
