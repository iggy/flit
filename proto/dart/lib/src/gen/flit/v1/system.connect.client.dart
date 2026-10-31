//
//  Generated code. Do not modify.
//  source: flit/v1/system.proto
//

import "package:connectrpc/connect.dart" as connect;
import "system.pb.dart" as flitv1system;
import "system.connect.spec.dart" as specs;

/// SystemService reports on the flit server itself and manages the devices
/// allowed to use it. Every RPC requires a token, even on localhost, except
/// Pair, which takes a pairing code instead.
/// There are two kinds of token. The admin token is generated on the
/// server's first run (see "flit token"). Device tokens are issued by Pair,
/// one per device, and can be listed and revoked. Device management RPCs
/// need the admin token; everything else accepts either.
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

  /// CreatePairingCode returns a short-lived, single-use code a new device
  /// can trade for its own token with Pair. Admin only. "flit pair" calls
  /// this and shows the code as text and as a QR code.
  Future<flitv1system.CreatePairingCodeResponse> createPairingCode(
    flitv1system.CreatePairingCodeRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.createPairingCode,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Pair trades a pairing code for a device token. Needs no token. A code
  /// works once; too many wrong codes invalidate all outstanding codes.
  Future<flitv1system.PairResponse> pair(
    flitv1system.PairRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.pair,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// ListDevices lists paired devices. Admin only.
  Future<flitv1system.ListDevicesResponse> listDevices(
    flitv1system.ListDevicesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.listDevices,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// RevokeDevice revokes a device's token immediately. Admin only.
  Future<flitv1system.RevokeDeviceResponse> revokeDevice(
    flitv1system.RevokeDeviceRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.revokeDevice,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// DebugDump reports what the server is doing right now, for working out
  /// where a frozen turn is stuck: each loaded session's turn, lock and
  /// model call in flight, the model concurrency limits in use, and
  /// optionally every goroutine's stack. Admin only. "flit debug dump"
  /// calls this.
  Future<flitv1system.DebugDumpResponse> debugDump(
    flitv1system.DebugDumpRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SystemService.debugDump,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
