import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/oauth_client.dart';
import 'package:flit/domain/models/oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for OAuthClient (RFC 8252 native-app flow). Drives the client
/// with a fake dio adapter and injectable PKCE/state/loopback so no real
/// network or browser is involved.
void main() {
  group('OAuthClient', () {
    late Dio dio;
    late FakeHttpClientAdapter adapter;
    final config = ConnectionConfig(baseUrl: 'https://gw.example.com');

    setUp(() {
      dio = Dio();
      adapter = FakeHttpClientAdapter();
      dio.httpClientAdapter = adapter;
    });

    test(
      'login completes the full PKCE flow and returns the session',
      () async {
        const verifier = 'test-verifier';
        const state = 'test-state';
        const code = 'auth-code-123';

        adapter.mockPost('/auth/native/token', <String, dynamic>{
          'access_token': 'at-token',
          'refresh_token': 'rt-token',
          'token_type': 'Bearer',
          'expires_at': 1700000000,
          'provider': 'nous',
          'user_id': 'u123',
        });

        final client = OAuthClient(
          config: config,
          dio: dio,
          launchUrl: (_) async {},
          loopbackServerFactory: () =>
              _fakeLoopbackServer(code: code, state: state),
          codeVerifierGenerator: () => verifier,
          stateGenerator: () => state,
        );

        final session = await client.login(provider: 'nous');

        expect(session.accessToken, 'at-token');
        expect(session.refreshToken, 'rt-token');
        expect(session.expiresAt, 1700000000);
        expect(session.provider, 'nous');
        expect(adapter.lastRequest, isNotNull);
        expect(adapter.lastRequest!.path, '/auth/native/token');
        final body = adapter.lastRequest!.data as Map<String, dynamic>;
        expect(body['code'], code);
        expect(body['code_verifier'], verifier);
      },
    );

    test('login throws GatewayAuthException on state mismatch', () async {
      final client = OAuthClient(
        config: config,
        dio: dio,
        launchUrl: (_) async {},
        loopbackServerFactory: () =>
            _fakeLoopbackServer(code: 'code', state: 'wrong-state'),
        codeVerifierGenerator: () => 'verifier',
        stateGenerator: () => 'expected-state',
      );

      expect(
        () => client.login(provider: 'nous'),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.message,
            'message',
            contains('state mismatch'),
          ),
        ),
      );
    });

    test('login throws GatewayAuthException on error redirect', () async {
      final client = OAuthClient(
        config: config,
        dio: dio,
        launchUrl: (_) async {},
        loopbackServerFactory: () =>
            _fakeLoopbackServer(error: 'access_denied', state: 'state'),
        codeVerifierGenerator: () => 'verifier',
        stateGenerator: () => 'state',
      );

      expect(
        () => client.login(provider: 'nous'),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.message,
            'message',
            contains('access_denied'),
          ),
        ),
      );
    });

    test(
      'login throws GatewayAuthException when code exchange returns 400',
      () async {
        adapter.mockPost('/auth/native/token', null, statusCode: 400);

        final client = OAuthClient(
          config: config,
          dio: dio,
          launchUrl: (_) async {},
          loopbackServerFactory: () =>
              _fakeLoopbackServer(code: 'code', state: 'state'),
          codeVerifierGenerator: () => 'verifier',
          stateGenerator: () => 'state',
        );

        expect(
          () => client.login(provider: 'nous'),
          throwsA(
            isA<GatewayAuthException>().having(
              (e) => e.message,
              'message',
              contains('authorization code is invalid'),
            ),
          ),
        );
      },
    );

    test('refresh returns a rotated session', () async {
      adapter.mockPost('/auth/native/refresh', <String, dynamic>{
        'access_token': 'new-at',
        'refresh_token': 'new-rt',
        'token_type': 'Bearer',
        'expires_at': 1700001000,
        'provider': 'nous',
        'user_id': 'u123',
      });

      final client = OAuthClient(
        config: config,
        dio: dio,
        launchUrl: (_) async {},
      );

      final session = OAuthSession(
        accessToken: 'old-at',
        refreshToken: 'old-rt',
        expiresAt: 1700000000,
        provider: 'nous',
      );

      final refreshed = await client.refresh(session: session);

      expect(refreshed.accessToken, 'new-at');
      expect(refreshed.refreshToken, 'new-rt');
      expect(refreshed.expiresAt, 1700001000);
      expect(refreshed.provider, 'nous');
      expect(adapter.lastRequest, isNotNull);
      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['refresh_token'], 'old-rt');
      expect(body['provider'], 'nous');
    });

    test('refresh throws GatewayAuthException on 401', () async {
      adapter.mockPost('/auth/native/refresh', null, statusCode: 401);

      final client = OAuthClient(
        config: config,
        dio: dio,
        launchUrl: (_) async {},
      );

      final session = OAuthSession(
        accessToken: 'old-at',
        refreshToken: 'old-rt',
        expiresAt: 1700000000,
        provider: 'nous',
      );

      expect(
        () => client.refresh(session: session),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.message,
            'message',
            contains('refresh token is invalid'),
          ),
        ),
      );
    });

    test('mintWsTicket returns the ticket with Bearer auth', () async {
      adapter.mockPost('/api/auth/ws-ticket', <String, dynamic>{
        'ticket': 'ticket-123',
        'ttl_seconds': 30,
      });

      final client = OAuthClient(
        config: config,
        dio: dio,
        launchUrl: (_) async {},
      );

      final ticket = await client.mintWsTicket(accessToken: 'at-token');

      expect(ticket, 'ticket-123');
      expect(adapter.lastRequest, isNotNull);
      expect(adapter.lastRequest!.headers['authorization'], 'Bearer at-token');
    });

    test(
      'mintWsTicket throws GatewayParseException on missing ticket',
      () async {
        adapter.mockPost('/api/auth/ws-ticket', <String, dynamic>{});

        final client = OAuthClient(
          config: config,
          dio: dio,
          launchUrl: (_) async {},
        );

        expect(
          () => client.mintWsTicket(accessToken: 'at-token'),
          throwsA(isA<GatewayParseException>()),
        );
      },
    );
  });
}

/// Fake loopback server that immediately returns a redirect with ?code= or ?error=.
Future<HttpServer> _fakeLoopbackServer({
  String? code,
  String? error,
  required String state,
}) async {
  final controller = StreamController<HttpRequest>();
  final server = FakeHttpServer(controller);

  // Immediately push a fake request with the redirect params
  unawaited(
    Future<void>.microtask(() {
      final params = <String, String>{'state': state};
      if (code != null) {
        params['code'] = code;
      }
      if (error != null) {
        params['error'] = error;
      }
      final uri = Uri(path: '/', queryParameters: params);
      final request = FakeHttpRequest(uri);
      controller.add(request);
    }),
  );

  return server;
}

/// Fake HttpServer that yields requests from a stream.
final class FakeHttpServer implements HttpServer {
  FakeHttpServer(this._controller);

  final StreamController<HttpRequest> _controller;

  @override
  Future<HttpRequest> get first => _controller.stream.first;

  @override
  Future<void> close({bool force = false}) async {
    await _controller.close();
  }

  @override
  int get port => 12345;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake HttpRequest.
final class FakeHttpRequest implements HttpRequest {
  FakeHttpRequest(this.uri);

  @override
  final Uri uri;

  @override
  final FakeHttpResponse response = FakeHttpResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake HttpResponse.
final class FakeHttpResponse implements HttpResponse {
  @override
  int statusCode = 200;

  @override
  final FakeHttpHeaders headers = FakeHttpHeaders();

  @override
  void write(Object? object) {}

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake HttpHeaders.
final class FakeHttpHeaders implements HttpHeaders {
  @override
  ContentType? contentType;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake Dio HttpClientAdapter for tests.
final class FakeHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  final Map<String, _MockResponse> _mocks = <String, _MockResponse>{};

  void mockPost(String path, dynamic data, {int statusCode = 200}) {
    _mocks[path] = _MockResponse(data, statusCode);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final mock = _mocks[options.path];
    if (mock == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        message: 'No mock for ${options.path}',
      );
    }
    if (mock.statusCode != 200) {
      throw DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: mock.statusCode,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    final json = mock.data is Map
        ? jsonEncode(mock.data)
        : (mock.data != null ? mock.data.toString() : '{}');
    return ResponseBody.fromString(
      json,
      200,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _MockResponse {
  _MockResponse(this.data, this.statusCode);

  final dynamic data;
  final int statusCode;
}
