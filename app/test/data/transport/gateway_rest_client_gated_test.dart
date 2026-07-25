// Unit tests for the gated-mode (user/pass) surface of GatewayRestClient —
// protocol §2.2: providers, password-login, cookie replay/rotation,
// ws-ticket, session-expiry hook.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/data/transport/session_cookie_jar.dart';

void main() {
  final gatedConfig = ConnectionConfig(
    baseUrl: 'https://gw.example.com',
    authMode: AuthMode.password,
    username: 'iggy',
  );

  group('authProviders', () {
    test('parses the providers list (wire §0.1)', () async {
      final client = _clientWith(gatedConfig, (options) async {
        expect(options.path, '/api/auth/providers');
        return _jsonResponse(200, <String, Object?>{
          'providers': <Map<String, Object?>>[
            <String, Object?>{
              'name': 'local',
              'display_name': 'Username & password',
              'supports_password': true,
            },
            <String, Object?>{
              'name': 'nous',
              'display_name': 'Nous Research',
              'supports_password': false,
            },
          ],
        });
      });

      final providers = await client.authProviders();
      expect(providers, hasLength(2));
      expect(providers[0].name, 'local');
      expect(providers[0].supportsPassword, isTrue);
      expect(providers[1].name, 'nous');
      expect(providers[1].supportsPassword, isFalse);
    });
  });

  group('passwordLogin', () {
    test(
      'posts {provider, username, password, next} and captures cookies',
      () async {
        final jar = SessionCookieJar();
        final client = _clientWith(gatedConfig, (options) async {
          expect(options.path, '/auth/password-login');
          // A fake adapter sees the raw data object (Map), not the encoded
          // JSON string the real HTTP client would send.
          final raw = options.data;
          final body = raw is String
              ? jsonDecode(raw) as Map<String, dynamic>
              : raw as Map<String, dynamic>;
          expect(body['provider'], 'local');
          expect(body['username'], 'iggy');
          expect(body['password'], 's3cret');
          expect(body, contains('next'));
          return _jsonResponse(
            200,
            <String, Object?>{'ok': true, 'next': '/'},
            setCookie: <String>[
              '__Host-hermes_session_at=at-token; Path=/; HttpOnly; Secure',
              '__Host-hermes_session_rt=rt-token; Path=/; HttpOnly; Secure',
              '__Host-hermes_session_provider=local; Path=/',
            ],
          );
        }, jar: jar);

        await client.passwordLogin(
          provider: 'local',
          username: 'iggy',
          password: 's3cret',
        );

        expect(jar.names, contains('__Host-hermes_session_at'));
        expect(jar.names, contains('__Host-hermes_session_rt'));
      },
    );

    test('401 → GatewayAuthException with generic message', () async {
      final client = _clientWith(gatedConfig, (options) async {
        return _jsonResponse(401, <String, Object?>{
          'detail': 'Invalid credentials',
        });
      });

      await expectLater(
        client.passwordLogin(
          provider: 'local',
          username: 'iggy',
          password: 'wrong',
        ),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.message,
            'message',
            'Invalid username or password.',
          ),
        ),
      );
    });

    test(
      '429 → rate-limit message; 404 → no-password-provider message',
      () async {
        final client429 = _clientWith(gatedConfig, (options) async {
          return _jsonResponse(429, <String, Object?>{'detail': 'slow down'});
        });
        await expectLater(
          client429.passwordLogin(provider: 'l', username: 'u', password: 'p'),
          throwsA(
            isA<GatewayAuthException>().having(
              (e) => e.message,
              'message',
              contains('Too many login attempts'),
            ),
          ),
        );

        final client404 = _clientWith(gatedConfig, (options) async {
          return _jsonResponse(404, <String, Object?>{'detail': 'Unknown'});
        });
        await expectLater(
          client404.passwordLogin(provider: 'l', username: 'u', password: 'p'),
          throwsA(
            isA<GatewayAuthException>().having(
              (e) => e.message,
              'message',
              contains('does not accept passwords'),
            ),
          ),
        );
      },
    );

    test(
      'a 200 with NO cookies is a parse error (login must set the session)',
      () async {
        final jar = SessionCookieJar();
        final client = _clientWith(gatedConfig, (options) async {
          return _jsonResponse(200, <String, Object?>{'ok': true, 'next': '/'});
        }, jar: jar);

        await expectLater(
          client.passwordLogin(provider: 'l', username: 'u', password: 'p'),
          throwsA(isA<GatewayParseException>()),
        );
      },
    );
  });

  group('cookie replay + rotation', () {
    test(
      'gated requests carry the Cookie header; rotation is recaptured',
      () async {
        final jar = SessionCookieJar()
          ..captureFromHeaders(<String>['__Host-hermes_session_at=at-1']);
        var call = 0;
        final client = _clientWith(gatedConfig, (options) async {
          call++;
          expect(options.headers['Cookie'], '__Host-hermes_session_at=at-1');
          // The gate rotates the AT on the response (middleware refresh).
          return _jsonResponse(
            200,
            <String, Object?>{'user_id': 'u1'},
            setCookie: <String>['__Host-hermes_session_at=at-2; Path=/'],
          );
        }, jar: jar);

        await client.authMe();
        expect(jar.cookieHeader, '__Host-hermes_session_at=at-2');
        expect(call, 1);
      },
    );

    test('token-mode requests do NOT send cookies', () async {
      final jar = SessionCookieJar()
        ..captureFromHeaders(<String>['leftover=1']);
      final client = _clientWith(
        ConnectionConfig(baseUrl: 'http://127.0.0.1:8765', token: 'tok'),
        (options) async {
          expect(options.headers['Cookie'], isNull);
          expect(options.headers['X-Hermes-Session-Token'], 'tok');
          return _jsonResponse(200, <String, Object?>{});
        },
        jar: jar,
      );

      await client.getJson('/api/profiles');
    });
  });

  group('session expiry hook', () {
    test('a 401 on a cookie-PRESENTING request fires onAuthFailure', () async {
      final jar = SessionCookieJar()..captureFromHeaders(<String>['at=old']);
      var authFailures = 0;
      final client = _clientWith(
        gatedConfig,
        (options) async => _jsonResponse(401, <String, Object?>{}),
        jar: jar,
        onAuthFailure: () => authFailures++,
      );

      await expectLater(
        client.getJson('/api/profiles'),
        throwsA(isA<GatewayAuthException>()),
      );
      expect(authFailures, 1);
    });

    test(
      'a 401 on a COOKIELESS request (login) does NOT fire onAuthFailure',
      () async {
        var authFailures = 0;
        final client = _clientWith(
          gatedConfig,
          (options) async => _jsonResponse(401, <String, Object?>{}),
          jar: SessionCookieJar(), // empty → no Cookie header sent
          onAuthFailure: () => authFailures++,
        );

        await expectLater(
          client.passwordLogin(provider: 'l', username: 'u', password: 'p'),
          throwsA(isA<GatewayAuthException>()),
        );
        expect(authFailures, 0);
      },
    );
  });

  group('mintWsTicket', () {
    test('parses {ticket, ttl_seconds} (wire §0.1)', () async {
      final client = _clientWith(gatedConfig, (options) async {
        expect(options.path, '/api/auth/ws-ticket');
        expect(options.method, 'POST');
        return _jsonResponse(200, <String, Object?>{
          'ticket': 'single-use-ticket',
          'ttl_seconds': 30,
        });
      });

      expect(await client.mintWsTicket(), 'single-use-ticket');
    });

    test('a body without a ticket is a parse error', () async {
      final client = _clientWith(gatedConfig, (options) async {
        return _jsonResponse(200, <String, Object?>{'nope': true});
      });
      await expectLater(
        client.mintWsTicket(),
        throwsA(isA<GatewayParseException>()),
      );
    });
  });
}

GatewayRestClient _clientWith(
  ConnectionConfig config,
  Future<ResponseBody> Function(RequestOptions options) handler, {
  SessionCookieJar? jar,
  void Function()? onAuthFailure,
}) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
  return GatewayRestClient(
    config,
    dio: dio,
    cookieJar: jar,
    onAuthFailure: onAuthFailure,
  );
}

ResponseBody _jsonResponse(
  int statusCode,
  Map<String, Object?> body, {
  List<String>? setCookie,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      'set-cookie': ?setCookie,
    },
  );
}

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
