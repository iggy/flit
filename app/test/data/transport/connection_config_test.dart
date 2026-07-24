import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/data/transport/connection_config.dart';

/// Unit tests for ConnectionConfig URL normalization, WS-URL construction,
/// and log redaction — ported from
/// `apps/desktop/electron/connection-config.test.ts` (ticket P0-04).
void main() {
  group('normalizeGatewayBaseUrl', () {
    test('strips trailing slashes, hash, and query', () {
      expect(
        normalizeGatewayBaseUrl('https://gw.example.com/'),
        'https://gw.example.com',
      );
      expect(
        normalizeGatewayBaseUrl('https://gw.example.com/hermes/'),
        'https://gw.example.com/hermes',
      );
      expect(
        normalizeGatewayBaseUrl('https://gw.example.com/hermes?x=1#frag'),
        'https://gw.example.com/hermes',
      );
    });

    test('preserves a path prefix', () {
      expect(
        normalizeGatewayBaseUrl('https://host/hermes'),
        'https://host/hermes',
      );
    });

    test('keeps a non-default port', () {
      expect(
        normalizeGatewayBaseUrl('http://127.0.0.1:9119/'),
        'http://127.0.0.1:9119',
      );
    });

    test('rejects empty input', () {
      expect(() => normalizeGatewayBaseUrl(''), throwsArgumentError);
      expect(() => normalizeGatewayBaseUrl('   '), throwsArgumentError);
    });

    test('rejects non-http(s) protocols', () {
      expect(() => normalizeGatewayBaseUrl('ftp://host'), throwsArgumentError);
      expect(
        () => normalizeGatewayBaseUrl('file:///etc/passwd'),
        throwsArgumentError,
      );
    });

    test('rejects garbage', () {
      expect(() => normalizeGatewayBaseUrl('not a url'), throwsArgumentError);
    });
  });

  group('ConnectionConfig', () {
    test('normalizes the base URL on construction', () {
      final config = ConnectionConfig(
        baseUrl: 'https://gw.example.com/hermes/',
      );
      expect(config.baseUrl, 'https://gw.example.com/hermes');
    });

    test('defaults to token auth mode', () {
      final config = ConnectionConfig(baseUrl: 'https://gw.example.com');
      expect(config.authMode, AuthMode.token);
      expect(config.token, isNull);
    });

    test('toString never contains the token', () {
      final config = ConnectionConfig(
        baseUrl: 'https://gw.example.com',
        token: 'supersecret',
      );
      expect(config.toString(), isNot(contains('supersecret')));
    });
  });

  group('wsUriFor', () {
    test('uses wss for https and bakes the token', () {
      final config = ConnectionConfig(
        baseUrl: 'https://gw.example.com',
        token: 'tok123',
      );
      expect(
        wsUriFor(config).toString(),
        'wss://gw.example.com/api/ws?token=tok123',
      );
    });

    test('wsTicketUriFor builds a gated ticket URL (URL-encoded)', () {
      final config = ConnectionConfig(
        baseUrl: 'https://gw.example.com/hermes/',
        authMode: AuthMode.password,
        username: 'iggy',
      );
      expect(
        wsTicketUriFor(config, 'tick et/1').toString(),
        'wss://gw.example.com/hermes/api/ws?ticket=tick%20et%2F1',
      );
    });

    test('uses ws for http', () {
      final config = ConnectionConfig(
        baseUrl: 'http://127.0.0.1:9119',
        token: 'abc',
      );
      expect(
        wsUriFor(config).toString(),
        'ws://127.0.0.1:9119/api/ws?token=abc',
      );
    });

    test('honors a path prefix', () {
      final config = ConnectionConfig(
        baseUrl: 'https://host/hermes',
        token: 't',
      );
      expect(wsUriFor(config).toString(), 'wss://host/hermes/api/ws?token=t');
    });

    test('url-encodes the token', () {
      final config = ConnectionConfig(
        baseUrl: 'https://host',
        token: 'a/b c+d',
      );
      expect(
        wsUriFor(config).toString(),
        'wss://host/api/ws?token=a%2Fb%20c%2Bd',
      );
    });

    test('omits the token query in oauth mode', () {
      final config = ConnectionConfig(
        baseUrl: 'https://gw.example.com',
        token: 'tok123',
        authMode: AuthMode.oauth,
      );
      final wsUrl = wsUriFor(config).toString();
      expect(wsUrl, 'wss://gw.example.com/api/ws');
      expect(wsUrl, isNot(contains('token=')));
    });

    test('omits the token query when no token is set', () {
      final config = ConnectionConfig(baseUrl: 'https://gw.example.com');
      expect(wsUriFor(config).toString(), 'wss://gw.example.com/api/ws');
    });
  });

  group('redactUrl', () {
    test('redacts the token query param — the token never shows', () {
      const url = 'wss://gw.example.com/api/ws?token=supersecret';
      final redacted = redactUrl(url);
      expect(redacted, 'wss://gw.example.com/api/ws?***');
      expect(redacted, isNot(contains('supersecret')));
    });

    test('redacts embedded user-info and keeps host/port/path', () {
      expect(
        redactUrl('https://user:pass@host:8443/hermes?token=x'),
        'https://***@host:8443/hermes?***',
      );
    });

    test('leaves a query-less URL untouched', () {
      expect(
        redactUrl('https://gw.example.com/hermes'),
        'https://gw.example.com/hermes',
      );
    });

    test('returns empty input unchanged', () {
      expect(redactUrl(''), '');
    });

    test('fallback strips the query of an unparseable URL', () {
      expect(redactUrl('not a url?token=sek'), 'not a url?***');
    });
  });
}
