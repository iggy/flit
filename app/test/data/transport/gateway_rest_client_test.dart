import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/transport/connection_config.dart';
import 'package:hermes/data/transport/gateway_rest_client.dart';

/// Unit tests for GatewayRestClient (ticket P0-05), run against a
/// hand-written fake [HttpClientAdapter] — no new deps, no mockito.
void main() {
  group('GatewayRestClient.status', () {
    test('parses the canned /api/status body (token mode)', () async {
      // Wire shape: docs/reference/03-mvp-wire-shapes.md §0, completed with
      // the always-present fields from 01-gateway-protocol.md §1
      // (release_date / gateway_busy / active_agents). Recon field *values*
      // are illustrative; the *names* are from protocol §1.
      final requests = <RequestOptions>[];
      final client = _clientWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'version': '0.17.0',
          'release_date': '2026-06-30',
          'gateway_running': true,
          'gateway_state': 'ready',
          'gateway_busy': false,
          'active_sessions': 1,
          'active_agents': 1,
          'auth_required': false,
          'auth_providers': <String>[],
          'hermes_home': '/home/dev/.hermes',
          'config_path': '/home/dev/.hermes/config.yaml',
          'env_path': '/home/dev/.hermes/.env',
          'gateway_pid': 4242,
          'gateway_health_url': 'http://127.0.0.1:8765/api/health',
        });
      });

      final status = await client.status();

      expect(status.version, '0.17.0');
      expect(status.releaseDate, '2026-06-30');
      expect(status.gatewayRunning, isTrue);
      expect(status.gatewayState, 'ready');
      expect(status.gatewayBusy, isFalse);
      expect(status.activeSessions, 1);
      expect(status.activeAgents, 1);
      expect(status.authRequired, isFalse);
      expect(status.authProviders, isEmpty);
      expect(status.hermesHome, '/home/dev/.hermes');
      expect(status.configPath, '/home/dev/.hermes/config.yaml');
      expect(status.envPath, '/home/dev/.hermes/.env');
      expect(status.gatewayPid, 4242);
      expect(status.gatewayHealthUrl, 'http://127.0.0.1:8765/api/health');

      // auth_required: false → token mode (mirrors authModeFromStatus).
      expect(status.inferredAuthMode, AuthMode.token);

      // Hit the public status path on the configured base URL.
      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/status');
      expect(
        requests.single.uri.toString(),
        'http://127.0.0.1:8765/api/status',
      );
    });

    test('parses the oauth variant — recon fields absent stay null', () async {
      final client = _clientWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'version': '0.17.0',
          'release_date': '2026-06-30',
          'gateway_running': true,
          'gateway_state': 'ready',
          'gateway_busy': false,
          'active_sessions': 2,
          'active_agents': 1,
          'auth_required': true,
          'auth_providers': <String>['nous'],
        });
      });

      final status = await client.status();

      expect(status.authRequired, isTrue);
      expect(status.authProviders, <String>['nous']);
      expect(status.inferredAuthMode, AuthMode.oauth);
      expect(status.hermesHome, isNull);
      expect(status.configPath, isNull);
      expect(status.envPath, isNull);
      expect(status.gatewayPid, isNull);
      expect(status.gatewayHealthUrl, isNull);
    });

    test('tolerates a null gateway_state', () async {
      final client = _clientWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'version': '0.17.0',
          'gateway_running': true,
          'gateway_state': null,
          'gateway_busy': false,
          'active_sessions': 0,
          'active_agents': 0,
          'auth_required': false,
          'auth_providers': <String>[],
        });
      });

      final status = await client.status();
      expect(status.gatewayState, isNull);
    });

    test('injects X-Hermes-Session-Token in token mode', () async {
      final requests = <RequestOptions>[];
      final client = _clientWith((options) async {
        requests.add(options);
        return _jsonResponse(200, _minimalStatusBody);
      });

      await client.status();

      expect(requests.single.headers['X-Hermes-Session-Token'], 'test-token');
    });

    test('sends no token header in oauth mode', () async {
      final requests = <RequestOptions>[];
      final client = _clientWith(
        (options) async {
          requests.add(options);
          return _jsonResponse(200, _minimalStatusBody);
        },
        config: ConnectionConfig(
          baseUrl: 'https://gw.example.com',
          token: 'test-token',
          authMode: AuthMode.oauth,
        ),
      );

      await client.status();

      expect(
        requests.single.headers.containsKey('X-Hermes-Session-Token'),
        isFalse,
      );
    });

    test('forwards ?profile= when given', () async {
      final requests = <RequestOptions>[];
      final client = _clientWith((options) async {
        requests.add(options);
        return _jsonResponse(200, _minimalStatusBody);
      });

      await client.status(profile: 'coder');

      expect(requests.single.uri.queryParameters['profile'], 'coder');
    });

    test('maps HTTP 401 to GatewayAuthException', () async {
      final client = _clientWith((options) async {
        return _jsonResponse(401, <String, Object?>{'detail': 'unauthorized'});
      });

      await expectLater(client.status(), throwsA(isA<GatewayAuthException>()));
    });

    test('maps HTTP 403 to GatewayAuthException', () async {
      final client = _clientWith((options) async {
        return _jsonResponse(403, <String, Object?>{'detail': 'forbidden'});
      });

      await expectLater(client.status(), throwsA(isA<GatewayAuthException>()));
    });

    test('maps an unreachable host to GatewayNetworkException', () async {
      final client = _clientWith((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Connection refused',
        );
      });

      await expectLater(
        client.status(),
        throwsA(isA<GatewayNetworkException>()),
      );
    });

    test('maps a timeout to GatewayTimeoutException', () async {
      final client = _clientWith((options) {
        throw DioException.connectionTimeout(
          requestOptions: options,
          timeout: const Duration(seconds: 5),
        );
      });

      await expectLater(
        client.status(),
        throwsA(isA<GatewayTimeoutException>()),
      );
    });

    test('maps an unexpected body to GatewayParseException', () async {
      final client = _clientWith((options) async {
        return _jsonResponse(200, <String, Object?>{'unexpected': true});
      });

      await expectLater(client.status(), throwsA(isA<GatewayParseException>()));
    });
  });
}

/// Minimal always-present field set (protocol §1) reused across tests.
const _minimalStatusBody = <String, Object?>{
  'version': '0.17.0',
  'gateway_running': true,
  'gateway_state': 'ready',
  'gateway_busy': false,
  'active_sessions': 1,
  'active_agents': 1,
  'auth_required': false,
  'auth_providers': <String>[],
};

GatewayRestClient _clientWith(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  ConnectionConfig? config,
}) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
  return GatewayRestClient(
    config ??
        ConnectionConfig(baseUrl: 'http://127.0.0.1:8765', token: 'test-token'),
    dio: dio,
  );
}

ResponseBody _jsonResponse(int statusCode, Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// Hand-written fake adapter: dispatches to [handler], captures nothing on
/// its own. Implements the full [HttpClientAdapter] interface.
final class _FakeAdapter implements HttpClientAdapter {
  const _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
