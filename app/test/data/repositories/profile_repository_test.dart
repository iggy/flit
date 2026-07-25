// P1-13 acceptance: ProfileRepositoryImpl against a fake Dio
// HttpClientAdapter serving the canned bodies of
// docs/reference/03-mvp-wire-shapes.md §14 — asserts the EXACT REST paths,
// the {"name": ...} POST body, snake_case parsing (is_default,
// skill_count), tolerance for missing optional fields, and GatewayException
// passthrough (incl. the older-gateway 404).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/profile_repository.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/domain/models/profile.dart';

void main() {
  group('ProfileRepositoryImpl.list (GET /api/profiles, wire §14)', () {
    test('parses the canned §14 body; missing optionals tolerated', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'profiles': <Map<String, Object?>>[
            <String, Object?>{
              'name': 'default',
              'is_default': true,
              'model': 'hermes-4-405b',
              'provider': 'nous',
              'description': 'Default profile',
              'skill_count': 12,
            },
            // §14's second entry: no provider, no skill_count.
            <String, Object?>{
              'name': 'research',
              'is_default': false,
              'model': 'hermes-4-70b',
              'description': 'Research profile',
            },
          ],
        });
      });

      final profiles = await repository.list();

      expect(profiles, <Profile>[
        const Profile(
          name: 'default',
          isDefault: true,
          model: 'hermes-4-405b',
          provider: 'nous',
          description: 'Default profile',
          skillCount: 12,
        ),
        const Profile(
          name: 'research',
          model: 'hermes-4-70b',
          description: 'Research profile',
        ),
      ]);
      expect(profiles[1].provider, isNull);
      expect(profiles[1].skillCount, isNull);
      expect(profiles[1].isDefault, isFalse);

      // EXACT documented path + REST auth header (protocol §2.1).
      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/profiles');
      expect(requests.single.headers['X-Hermes-Session-Token'], 'test-token');
    });

    test('maps a profile entry without a name to GatewayParseException', () {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'profiles': <Map<String, Object?>>[
            <String, Object?>{'is_default': true},
          ],
        });
      });

      expect(repository.list(), throwsA(isA<GatewayParseException>()));
    });

    test('maps a non-object body to GatewayParseException', () {
      final repository = _repositoryWith((options) async {
        return ResponseBody.fromString(
          jsonEncode(<String>['not', 'a', 'map']),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );
      });

      expect(repository.list(), throwsA(isA<GatewayParseException>()));
    });

    test('passes through a 404 as GatewayNetworkException (older gateway)', () {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(404, <String, Object?>{'detail': 'Not Found'});
      });

      expect(
        repository.list(),
        throwsA(
          isA<GatewayNetworkException>().having(
            (e) => e.message,
            'message',
            contains('404'),
          ),
        ),
      );
    });

    test('passes through a 401 as GatewayAuthException', () {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(401, <String, Object?>{'detail': 'unauthorized'});
      });

      expect(repository.list(), throwsA(isA<GatewayAuthException>()));
    });
  });

  group('ProfileRepositoryImpl.active (GET /api/profiles/active)', () {
    test('returns the active profile name', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'active': 'default'});
      });

      expect(await repository.active(), 'default');
      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/profiles/active');
    });

    test('returns null when the gateway reports none', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{'active': null});
      });

      expect(await repository.active(), isNull);
    });
  });

  group('ProfileRepositoryImpl.setActive (POST /api/profiles/active)', () {
    test('posts EXACTLY {"name": "research"} to the documented path', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.setActive('research');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/profiles/active');
      expect(requests.single.data, <String, dynamic>{'name': 'research'});
      expect(requests.single.headers['X-Hermes-Session-Token'], 'test-token');
    });

    test('passes through a failure as a GatewayException', () {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(500, <String, Object?>{'detail': 'boom'});
      });

      expect(
        repository.setActive('research'),
        throwsA(isA<GatewayNetworkException>()),
      );
    });
  });
}

ProfileRepositoryImpl _repositoryWith(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
  final client = GatewayRestClient(
    ConnectionConfig(baseUrl: 'http://127.0.0.1:8765', token: 'test-token'),
    dio: dio,
  );
  return ProfileRepositoryImpl(client);
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

/// Hand-written fake adapter (same pattern as
/// test/data/transport/gateway_rest_client_test.dart) — dispatches to
/// [handler], records nothing on its own.
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
