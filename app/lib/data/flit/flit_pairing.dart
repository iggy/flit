/// Pairing a device with a flit server: parse what `flit pair` shows (QR or
/// typed), then trade the one-time code for a device token.
library;

import 'package:connectrpc/connect.dart' as connect;
import 'package:flit/data/flit/flit_errors.dart';
import 'package:flit/data/flit/flit_transport.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit_api/flit_api.dart' as pb;

/// What a pairing QR code holds: `flit://pair?server=<url>&code=<code>`.
final class PairingInfo {
  const PairingInfo({required this.serverUrl, required this.code});

  final String serverUrl;
  final String code;

  @override
  bool operator ==(Object other) =>
      other is PairingInfo &&
      other.serverUrl == serverUrl &&
      other.code == code;

  @override
  int get hashCode => Object.hash(serverUrl, code);

  @override
  String toString() =>
      'PairingInfo(serverUrl: ${redactUrl(serverUrl)}, code: ***)';
}

/// Parses a scanned pairing QR payload; null if it isn't one.
PairingInfo? parsePairingUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'flit' || uri.host != 'pair') {
    return null;
  }
  final server = uri.queryParameters['server'] ?? '';
  final code = uri.queryParameters['code'] ?? '';
  if (server.isEmpty || code.isEmpty) {
    return null;
  }
  return PairingInfo(serverUrl: server, code: code);
}

/// The result of a successful pairing.
typedef PairedDevice = ({String deviceId, String deviceName, String token});

/// Trades [code] for a device token at [serverUrl] (normalized like a
/// gateway URL). Throws a GatewayException on failure.
Future<PairedDevice> pairWithServer({
  required String serverUrl,
  required String code,
  required String deviceName,
  connect.HttpClient? httpClient,
}) {
  final baseUrl = normalizeGatewayBaseUrl(serverUrl);
  final client = pb.SystemServiceClient(
    createFlitTransport(baseUrl: baseUrl, httpClient: httpClient),
  );
  return flitCall(() async {
    final res = await client.pair(
      pb.PairRequest(code: code.trim(), deviceName: deviceName),
    );
    return (
      deviceId: res.device.id,
      deviceName: res.device.name,
      token: res.token,
    );
  });
}

/// Checks a stored device token still works (SystemService.Version) and
/// returns the server's version.
Future<String> checkFlitServer({
  required String baseUrl,
  required String token,
  connect.HttpClient? httpClient,
}) {
  final client = pb.SystemServiceClient(
    createFlitTransport(baseUrl: baseUrl, token: token, httpClient: httpClient),
  );
  return flitCall(() async {
    final res = await client.version(pb.VersionRequest());
    return res.version;
  });
}
