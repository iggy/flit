import 'package:connectrpc/connect.dart' as connect;
import 'package:flit/core/errors/gateway_error.dart';

/// Runs [call] and turns Connect and transport failures into the app's
/// [GatewayException]s, so nothing above `data/` sees a Connect type.
Future<T> flitCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on connect.ConnectException catch (error) {
    throw flitError(error);
  } on GatewayException {
    rethrow;
  } on Object catch (error) {
    throw GatewayNetworkException(
      'Could not reach the flit server: $error',
      cause: error,
    );
  }
}

/// Maps one Connect error to a [GatewayException].
GatewayException flitError(Object error) {
  if (error is! connect.ConnectException) {
    return GatewayNetworkException(
      'Could not reach the flit server: $error',
      cause: error,
    );
  }
  final message = error.message.isEmpty ? error.code.name : error.message;
  return switch (error.code) {
    connect.Code.unauthenticated || connect.Code.permissionDenied =>
      GatewayAuthException(message, cause: error),
    connect.Code.unavailable => GatewayNetworkException(message, cause: error),
    connect.Code.deadlineExceeded => GatewayTimeoutException(
      message,
      cause: error,
    ),
    _ => GatewayRpcException(error.code.value, message, cause: error),
  };
}
