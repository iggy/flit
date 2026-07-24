import 'package:dio/dio.dart';

import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/dto/gateway_status_dto.dart';
import 'package:hermes/data/transport/connection_config.dart';
import 'package:hermes/domain/models/gateway_status.dart';

/// Authenticated HTTP client for the Hermes gateway REST API (ticket P0-05).
///
/// Thin `dio` wrapper that injects auth (`X-Hermes-Session-Token` header in
/// token mode — docs/reference/01-gateway-protocol.md §2.1) and the base URL.
/// Used for `/api/status` now; `/api/profiles/*`, `/api/plugins/kanban/*`,
/// `/api/auth/ws-ticket`, and downloads later (04-app-architecture.md).
///
/// Raw `DioException`s never escape this class — they are mapped to typed
/// [GatewayException]s (05-conventions.md).
final class GatewayRestClient {
  /// [dio] is injectable for tests (hand a `Dio` with a fake
  /// `HttpClientAdapter`). The client's base URL and auth interceptor are
  /// applied to whichever instance is used.
  GatewayRestClient(this._config, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = _config.baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Token mode: send the session token header. Public paths
          // (`/api/status`) need no auth, but sending the header when a token
          // exists is what the reference clients do (connection-config.ts:
          // "'token': … REST uses an X-Hermes-Session-Token header").
          final token = _config.token;
          if (_config.authMode == AuthMode.token && token != null) {
            options.headers['X-Hermes-Session-Token'] = token;
          }
          handler.next(options);
        },
      ),
    );
  }

  final ConnectionConfig _config;
  final Dio _dio;

  /// `GET {base}/api/status` (optional `?profile=<name>`) — the public,
  /// unauthenticated discovery endpoint (protocol §1).
  Future<GatewayStatus> status({String? profile}) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        '/api/status',
        queryParameters: profile == null
            ? null
            : <String, String>{'profile': profile},
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }

    final data = response.data;
    if (data == null) {
      throw GatewayParseException(
        'GET /api/status returned an empty body '
        '(${redactUrl(response.realUri.toString())}).',
      );
    }

    try {
      return GatewayStatusDto.fromJson(data).toDomain();
    } on Object catch (error) {
      throw GatewayParseException(
        'Could not parse GET /api/status response '
        '(${redactUrl(response.realUri.toString())}).',
        cause: error,
      );
    }
  }

  /// Map dio's error surface onto the shared typed errors — never leak a
  /// [DioException] above the data layer. Messages carry only redacted URLs.
  GatewayException _mapDioException(DioException error) {
    final url = redactUrl(error.requestOptions.uri.toString());
    final statusCode = error.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return GatewayAuthException(
        'Gateway rejected the request (HTTP $statusCode, $url). '
        'Check the session token.',
        cause: error,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return GatewayTimeoutException(
          'Timed out talking to the gateway ($url).',
          cause: error,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return GatewayNetworkException(
          'Could not reach the gateway ($url).',
          cause: error,
        );
      case DioExceptionType.badResponse:
        return GatewayNetworkException(
          'Gateway returned HTTP $statusCode ($url).',
          cause: error,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return GatewayNetworkException(
          'Request to the gateway failed ($url).',
          cause: error,
        );
    }
  }
}
