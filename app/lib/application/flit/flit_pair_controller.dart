/// Pairing this app with a flit server: trade the code from `flit pair` for
/// a device token and save the connection.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/flit/flit_device_name_io.dart'
    if (dart.library.js_interop) 'package:flit/data/flit/flit_device_name_web.dart';
import 'package:flit/data/flit/flit_pairing.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:flit/data/flit/flit_pairing.dart'
    show PairingInfo, parsePairingUri;

/// The pairing call. Overridden in tests.
typedef FlitPairFn =
    Future<PairedDevice> Function({
      required String serverUrl,
      required String code,
      required String deviceName,
    });

final flitPairFnProvider = Provider<FlitPairFn>((ref) => pairWithServer);

/// This device's suggested name.
final flitDefaultDeviceNameProvider = Provider<String>(
  (ref) => defaultFlitDeviceName(),
);

final class FlitPairState {
  const FlitPairState({this.busy = false, this.error, this.paired = false});

  final bool busy;
  final String? error;

  /// True once pairing succeeded and the connection was saved.
  final bool paired;
}

final flitPairControllerProvider =
    NotifierProvider<FlitPairController, FlitPairState>(FlitPairController.new);

class FlitPairController extends Notifier<FlitPairState> {
  @override
  FlitPairState build() => const FlitPairState();

  /// Pairs with [serverUrl] using [code] and saves the connection.
  Future<void> pair({
    required String serverUrl,
    required String code,
    required String deviceName,
  }) async {
    if (state.busy) {
      return;
    }
    state = const FlitPairState(busy: true);
    try {
      final baseUrl = normalizeGatewayBaseUrl(serverUrl);
      final device = await ref.read(flitPairFnProvider)(
        serverUrl: baseUrl,
        code: code,
        deviceName: deviceName.trim(),
      );
      await ref
          .read(connectionConfigProvider.notifier)
          .setConfig(
            ConnectionConfig(
              baseUrl: baseUrl,
              token: device.token,
              backend: BackendKind.flit,
              deviceName: device.deviceName,
            ),
          );
      state = const FlitPairState(paired: true);
    } on ArgumentError catch (error) {
      state = FlitPairState(error: '${error.message}');
    } on GatewayException catch (error) {
      state = FlitPairState(error: error.message);
    } on Object catch (error) {
      state = FlitPairState(error: error.toString());
    }
  }

  /// Forgets the flit connection (this device's token is dropped locally;
  /// revoke it on the server with `flit devices revoke`).
  Future<void> disconnect() async {
    await ref.read(connectionConfigProvider.notifier).clear();
    state = const FlitPairState();
  }
}
