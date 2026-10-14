//
//  Generated code. Do not modify.
//  source: flit/v1/system.proto
//

import "package:connectrpc/connect.dart" as connect;
import "system.pb.dart" as flitv1system;

/// SystemService reports on the flit server itself and manages the devices
/// allowed to use it. Every RPC requires a token, even on localhost, except
/// Pair, which takes a pairing code instead.
/// There are two kinds of token. The admin token is generated on the
/// server's first run (see "flit token"). Device tokens are issued by Pair,
/// one per device, and can be listed and revoked. Device management RPCs
/// need the admin token; everything else accepts either.
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

  /// CreatePairingCode returns a short-lived, single-use code a new device
  /// can trade for its own token with Pair. Admin only. "flit pair" calls
  /// this and shows the code as text and as a QR code.
  static const createPairingCode = connect.Spec(
    '/$name/CreatePairingCode',
    connect.StreamType.unary,
    flitv1system.CreatePairingCodeRequest.new,
    flitv1system.CreatePairingCodeResponse.new,
  );

  /// Pair trades a pairing code for a device token. Needs no token. A code
  /// works once; too many wrong codes invalidate all outstanding codes.
  static const pair = connect.Spec(
    '/$name/Pair',
    connect.StreamType.unary,
    flitv1system.PairRequest.new,
    flitv1system.PairResponse.new,
  );

  /// ListDevices lists paired devices. Admin only.
  static const listDevices = connect.Spec(
    '/$name/ListDevices',
    connect.StreamType.unary,
    flitv1system.ListDevicesRequest.new,
    flitv1system.ListDevicesResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// RevokeDevice revokes a device's token immediately. Admin only.
  static const revokeDevice = connect.Spec(
    '/$name/RevokeDevice',
    connect.StreamType.unary,
    flitv1system.RevokeDeviceRequest.new,
    flitv1system.RevokeDeviceResponse.new,
  );
}
