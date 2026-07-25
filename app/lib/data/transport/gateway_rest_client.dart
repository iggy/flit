import 'package:dio/dio.dart';

import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/gateway_status_dto.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/session_cookie_jar.dart';
import 'package:flit/domain/models/auth_provider.dart';
import 'package:flit/domain/models/gateway_status.dart';

/// Authenticated HTTP client for the Hermes gateway REST API (ticket P0-05,
/// gated auth added post-MVP).
///
/// Thin `dio` wrapper that injects auth and the base URL:
/// - token mode: `X-Hermes-Session-Token` header (protocol §2.1);
/// - gated modes (user/pass now, OAuth later): the session cookies as a
///   `Cookie` header (protocol §2.2), refreshed from every response's
///   `Set-Cookie` (the gate middleware rotates the access-token cookie).
///
/// Used for `/api/status`, the auth endpoints, `/api/profiles/*`, and
/// `/api/plugins/kanban/*`.
///
/// Raw `DioException`s never escape this class — they are mapped to typed
/// [GatewayException]s (05-conventions.md).
final class GatewayRestClient {
  /// [dio] is injectable for tests (hand a `Dio` with a fake
  /// [HttpClientAdapter]). The client's base URL and auth interceptor are
  /// applied to whichever instance is used.
  ///
  /// [cookieJar] is the shared gated-mode session store (token mode ignores
  /// it). [onCookiesChanged] fires after the jar changes (persist it — it
  /// holds session tokens; secure storage only). [onAuthFailure] fires when
  /// a gated request is answered 401/403 — the session is dead, re-login is
  /// required.
  GatewayRestClient(
    this._config, {
    Dio? dio,
    this.cookieJar,
    this.onCookiesChanged,
    this.onAuthFailure,
  }) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = _config.baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          switch (_config.authMode) {
            case AuthMode.token:
              // Token mode: send the session token header. Public paths
              // (`/api/status`) need no auth, but sending the header when a
              // token exists is what the reference clients do.
              final token = _config.token;
              if (token != null) {
                options.headers['X-Hermes-Session-Token'] = token;
              }
            case AuthMode.password:
            case AuthMode.oauth:
              // Gated mode: replay the session cookies (protocol §2.2).
              final jar = cookieJar;
              if (jar != null && jar.isNotEmpty) {
                options.headers['Cookie'] = jar.cookieHeader;
              }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _captureCookies(response);
          handler.next(response);
        },
        onError: (error, handler) {
          _captureCookies(error.response);
          final statusCode = error.response?.statusCode;
          final presentedCookies =
              error.requestOptions.headers['Cookie'] != null;
          if (_config.authMode != AuthMode.token &&
              presentedCookies &&
              (statusCode == 401 || statusCode == 403)) {
            // A request that PRESENTED session cookies was rejected — the
            // session is dead (expired/revoked). The app layer clears the
            // jar and sends the user back to login. (A 401 on a cookiless
            // request — e.g. a failed login — is not a session expiry.)
            onAuthFailure?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final ConnectionConfig _config;
  final Dio _dio;
  final SessionCookieJar? cookieJar;
  final void Function()? onCookiesChanged;
  final void Function()? onAuthFailure;

  void _captureCookies(Response<dynamic>? response) {
    final jar = cookieJar;
    if (jar == null || response == null) {
      return;
    }
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      jar.captureFromHeaders(setCookie);
      onCookiesChanged?.call();
    }
  }

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

  /// `GET /api/auth/providers` (public; protocol §2.2 step 1).
  ///
  /// 503 (no providers registered) surfaces as [GatewayNetworkException].
  Future<List<AuthProviderInfo>> authProviders() async {
    final body = await getJson('/api/auth/providers');
    if (body is! Map || body['providers'] is! List) {
      throw const GatewayParseException(
        'GET /api/auth/providers returned an unexpected body.',
      );
    }
    return <AuthProviderInfo>[
      for (final p in body['providers'] as List)
        if (p is Map)
          AuthProviderInfo(
            name: p['name']?.toString() ?? '',
            displayName: p['display_name']?.toString() ?? '',
            supportsPassword: p['supports_password'] == true,
          ),
    ];
  }

  /// `POST /auth/password-login` (protocol §2.2 step 2). On success the
  /// session cookies are in the jar (captured by the interceptor).
  ///
  /// Failure copy follows the server (`dashboard_auth/routes.py:466`) —
  /// deliberately generic: 401 invalid credentials, 404 unknown or
  /// password-less provider, 429 rate limited, 503 provider unreachable.
  Future<void> passwordLogin({
    required String provider,
    required String username,
    required String password,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/password-login',
        data: <String, String>{
          'provider': provider,
          'username': username,
          'password': password,
          'next': '',
        },
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      throw switch (statusCode) {
        401 => const GatewayAuthException('Invalid username or password.'),
        404 => const GatewayAuthException(
          'This sign-in provider does not accept passwords.',
        ),
        429 => const GatewayAuthException(
          'Too many login attempts. Try again shortly.',
        ),
        503 => const GatewayNetworkException(
          'The sign-in provider is unreachable. Try again shortly.',
        ),
        _ => _mapDioException(error),
      };
    }
    final jar = cookieJar;
    if (jar == null || jar.isEmpty) {
      throw const GatewayParseException(
        'Login succeeded but the gateway set no session cookies.',
      );
    }
  }

  /// `POST /api/auth/ws-ticket` (cookie-authed; protocol §2.2 step 5).
  ///
  /// Returns the single-use ticket for one `/api/ws?ticket=` upgrade.
  /// Mint a fresh one per connect and per reconnect attempt.
  Future<String> mintWsTicket() async {
    final body = await postJson('/api/auth/ws-ticket');
    if (body is Map && body['ticket'] is String) {
      return body['ticket'] as String;
    }
    throw const GatewayParseException(
      'POST /api/auth/ws-ticket returned no ticket.',
    );
  }

  /// `GET /api/auth/me` (cookie-authed; protocol §2.2 step 6) — the current
  /// session identity. Optional probe; raw map (no domain need yet).
  Future<Map<String, dynamic>> authMe() async {
    final body = await getJson('/api/auth/me');
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw const GatewayParseException(
      'GET /api/auth/me returned an unexpected body.',
    );
  }

  /// `POST /auth/logout` — best-effort revoke + local jar clear
  /// (protocol §2.2 step 7). Never throws: logout must not trap the user.
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } on DioException {
      // Best-effort — the local clear below is what matters to the client.
    }
    cookieJar?.clear();
    onCookiesChanged?.call();
  }

  /// Authenticated GET returning the decoded JSON body (Map or List).
  ///
  /// Generic verb for feature repositories (profiles, kanban — added after
  /// P0-05 so all REST features share auth + error mapping instead of
  /// editing this class per feature). [path] is app-relative, e.g.
  /// `/api/profiles`.
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Authenticated POST with a JSON body, returning the decoded JSON body.
  Future<dynamic> postJson(String path, {Object? body}) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Authenticated PATCH with a JSON body, returning the decoded JSON body.
  Future<dynamic> patchJson(String path, {Object? body}) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: body);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Authenticated DELETE, returning the decoded JSON body (may be null).
  Future<dynamic> deleteJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapDioException(error);
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
