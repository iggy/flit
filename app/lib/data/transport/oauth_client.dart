/// OAuth native-app client (RFC 8252; Phase 8 tickets P8-01–P8-03).
///
/// Handles the full OAuth flow for the Hermes Agent gateway:
/// 1. PKCE (S256): generate code_verifier + code_challenge.
/// 2. Start a local loopback HTTP server on an ephemeral port.
/// 3. Open the system browser to the gateway's authorize endpoint.
/// 4. Catch the redirect on the loopback server.
/// 5. Exchange the code for tokens (`POST /auth/native/token`).
/// 6. Refresh the access token (`POST /auth/native/refresh`) — ROTATING.
/// 7. Mint WS tickets (`POST /api/auth/ws-ticket`) with Bearer auth.
///
/// Flutter-free (lives in `data/`): browser-launch and the loopback server
/// are injectable (application layer provides the real implementations).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/oauth_session.dart';

/// Type for the browser-launch callback (injected from the application layer
/// so this stays Flutter-free). Opens the system browser to the given URI.
typedef LaunchUrlFn = Future<void> Function(Uri uri);

/// Type for the loopback server factory (injectable for deterministic tests).
/// Default is `HttpServer.bind(InternetAddress.loopbackIPv4, 0)`.
typedef LoopbackServerFactory = Future<HttpServer> Function();

/// Type for the PKCE code_verifier generator (injectable for tests).
/// Default is a cryptographically secure random string (43–128 chars,
/// unreserved set `[A-Za-z0-9-._~]`).
typedef CodeVerifierGenerator = String Function();

/// Type for the state string generator (injectable for tests). Default is a
/// secure random string for CSRF protection.
typedef StateGenerator = String Function();

/// OAuth client for the Hermes gateway native-app flow (RFC 8252 loopback).
///
/// The gateway ONLY accepts loopback IP redirect URIs (`http://127.0.0.1:<port>/`)
/// — custom URL schemes and `localhost` are REJECTED.
final class OAuthClient {
  OAuthClient({
    required this._config,
    Dio? dio,
    required this.launchUrl,
    this.loopbackServerFactory = _defaultLoopbackServerFactory,
    this.codeVerifierGenerator = _defaultCodeVerifierGenerator,
    this.stateGenerator = _defaultStateGenerator,
  }) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = _config.baseUrl;
  }

  final ConnectionConfig _config;
  final Dio _dio;
  final LaunchUrlFn launchUrl;
  final LoopbackServerFactory loopbackServerFactory;
  final CodeVerifierGenerator codeVerifierGenerator;
  final StateGenerator stateGenerator;

  /// The full OAuth login flow: PKCE → loopback server → browser → redirect
  /// → code exchange. Returns the session tokens. Times out after 5 minutes
  /// (the user must complete the browser flow within that window).
  ///
  /// Throws [GatewayAuthException] on auth failures (invalid provider, code
  /// exchange rejected), [GatewayTimeoutException] on timeout,
  /// [GatewayNetworkException] on network errors.
  Future<OAuthSession> login({required String provider}) async {
    final codeVerifier = codeVerifierGenerator();
    final codeChallenge = _computeCodeChallenge(codeVerifier);
    final state = stateGenerator();

    final server = await loopbackServerFactory();
    final redirectUri = 'http://127.0.0.1:${server.port}/';

    final authorizeUrl = Uri.parse('${_config.baseUrl}/auth/native/authorize')
        .replace(
          queryParameters: <String, String>{
            'provider': provider,
            'code_challenge': codeChallenge,
            'code_challenge_method': 'S256',
            'redirect_uri': redirectUri,
            'state': state,
          },
        );

    try {
      await launchUrl(authorizeUrl);
    } on Object catch (error) {
      await server.close(force: true);
      throw GatewayNetworkException(
        'Could not open the system browser for OAuth login.',
        cause: error,
      );
    }

    final redirectParams = await _waitForRedirect(server, state).timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        throw const GatewayTimeoutException(
          'OAuth login timed out (5 minutes). '
          'Complete the sign-in in the browser.',
        );
      },
    );

    final code = redirectParams['code'];
    if (code == null || code.isEmpty) {
      final error = redirectParams['error'];
      throw GatewayAuthException(
        'OAuth login failed${error != null ? ': $error' : ''}.',
      );
    }

    return _exchangeCode(code: code, codeVerifier: codeVerifier);
  }

  /// Refresh the access token (rotating: returns a NEW access+refresh pair).
  /// Throws [GatewayAuthException] when the refresh token is dead (401) —
  /// the session is expired, force re-login.
  Future<OAuthSession> refresh({required OAuthSession session}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/native/refresh',
        data: <String, String>{
          'refresh_token': session.refreshToken,
          'provider': session.provider,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const GatewayParseException(
          'POST /auth/native/refresh returned an empty body.',
        );
      }
      return _parseTokenResponse(data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        throw const GatewayAuthException(
          'The refresh token is invalid or expired. Sign in again.',
        );
      }
      throw _mapDioException(error);
    }
  }

  /// Mint a single-use WebSocket ticket (Bearer-authed via [accessToken]).
  /// The ticket is consumed on the WS upgrade — mint a fresh one per connect
  /// and per reconnect attempt.
  Future<String> mintWsTicket({required String accessToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/ws-ticket',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      final data = response.data;
      if (data == null || data['ticket'] is! String) {
        throw const GatewayParseException(
          'POST /api/auth/ws-ticket returned no ticket.',
        );
      }
      return data['ticket'] as String;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Wait for the browser to redirect to the loopback server with `?code=` or
  /// `?error=`. Responds to the HTTP request with a "you can close this
  /// window" page, then closes the server. Verifies the state matches (CSRF).
  Future<Map<String, String>> _waitForRedirect(
    HttpServer server,
    String expectedState,
  ) async {
    try {
      final request = await server.first;
      final uri = request.uri;
      final params = uri.queryParameters;

      final receivedState = params['state'];
      if (receivedState != expectedState) {
        throw const GatewayAuthException(
          'OAuth state mismatch (possible CSRF). Sign in again.',
        );
      }

      final responseHtml = '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Sign-in complete</title></head>
<body style="font-family: system-ui, sans-serif; text-align: center; padding: 2rem;">
  <h1>Sign-in complete</h1>
  <p>You can close this window and return to the app.</p>
</body>
</html>
''';
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(responseHtml);
      await request.response.close();

      return params;
    } finally {
      await server.close(force: true);
    }
  }

  /// Exchange the authorization code for tokens (`POST /auth/native/token`).
  Future<OAuthSession> _exchangeCode({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/native/token',
        data: <String, String>{'code': code, 'code_verifier': codeVerifier},
      );
      final data = response.data;
      if (data == null) {
        throw const GatewayParseException(
          'POST /auth/native/token returned an empty body.',
        );
      }
      return _parseTokenResponse(data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400) {
        throw const GatewayAuthException(
          'The authorization code is invalid or expired. Sign in again.',
        );
      }
      throw _mapDioException(error);
    }
  }

  /// Parse the token response shape (same for /token and /refresh):
  /// `{access_token, refresh_token, token_type, expires_at, provider, user_id}`.
  OAuthSession _parseTokenResponse(Map<String, dynamic> data) {
    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    final expiresAt = data['expires_at'];
    final provider = data['provider'];

    if (accessToken is! String ||
        refreshToken is! String ||
        expiresAt is! int ||
        provider is! String) {
      throw const GatewayParseException(
        'OAuth token response is missing required fields.',
      );
    }

    return OAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      provider: provider,
    );
  }

  /// Map dio's error surface onto the shared typed errors — never leak a
  /// [DioException] above the data layer. Messages carry only redacted URLs.
  GatewayException _mapDioException(DioException error) {
    final url = redactUrl(error.requestOptions.uri.toString());
    final statusCode = error.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return GatewayAuthException(
        'Gateway rejected the request (HTTP $statusCode, $url). '
        'Check the session.',
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

  /// Compute the PKCE S256 code challenge: base64url(SHA256(verifier)) unpadded.
  static String _computeCodeChallenge(String verifier) {
    final hash = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  /// Default loopback server factory: bind to ephemeral port on 127.0.0.1.
  static Future<HttpServer> _defaultLoopbackServerFactory() {
    return HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  }

  /// Default code_verifier generator: secure random 128-char string from the
  /// unreserved set `[A-Za-z0-9-._~]` (RFC 7636 allows 43–128 chars).
  static String _defaultCodeVerifierGenerator() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List<String>.generate(
      128,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Default state generator: secure random 32-char string for CSRF protection.
  static String _defaultStateGenerator() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
