// Unit tests for the gated-mode session cookie jar (protocol §2.2).

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/data/transport/session_cookie_jar.dart';

void main() {
  group('SessionCookieJar.captureFromHeaders', () {
    test('captures name=value pairs, ignoring attributes', () {
      final jar = SessionCookieJar()
        ..captureFromHeaders(<String>[
          '__Host-hermes_session_at=abc123; Path=/; HttpOnly; Secure; '
              'SameSite=Lax',
          'hermes_session_rt=rt456; Path=/; Max-Age=2592000; HttpOnly',
        ]);

      expect(jar.isNotEmpty, isTrue);
      expect(
        jar.cookieHeader,
        '__Host-hermes_session_at=abc123; hermes_session_rt=rt456',
      );
      expect(jar.names, <String>{
        '__Host-hermes_session_at',
        'hermes_session_rt',
      });
    });

    test('merges rotated cookies (name overwrite)', () {
      final jar = SessionCookieJar()
        ..captureFromHeaders(<String>['hermes_session_at=old'])
        ..captureFromHeaders(<String>['hermes_session_at=new; Path=/']);

      expect(jar.cookieHeader, 'hermes_session_at=new');
    });

    test('an empty value REMOVES the cookie (clearing cookie)', () {
      final jar = SessionCookieJar()
        ..captureFromHeaders(<String>[
          'hermes_session_at=abc',
          'hermes_session_rt=rt',
        ])
        ..captureFromHeaders(<String>['hermes_session_at=; Path=/; Max-Age=0']);

      expect(jar.cookieHeader, 'hermes_session_rt=rt');
    });

    test('tolerates null/empty/garbage input', () {
      final jar = SessionCookieJar()
        ..captureFromHeaders(null)
        ..captureFromHeaders(<String>['', 'no-equals-here', '=x']);
      expect(jar.isEmpty, isTrue);
    });
  });

  group('SessionCookieJar serialization', () {
    test('toJson / replaceFromJson round-trips', () {
      final jar = SessionCookieJar()
        ..captureFromHeaders(<String>[
          '__Secure-hermes_session_at=abc',
          'hermes_session_provider=local',
        ]);
      final json = jar.toJson();

      final restored = SessionCookieJar()..replaceFromJson(json);
      expect(restored.cookieHeader, jar.cookieHeader);
    });

    test('clear empties the jar', () {
      final jar = SessionCookieJar()
        ..captureFromHeaders(<String>['a=1'])
        ..clear();
      expect(jar.isEmpty, isTrue);
      expect(jar.cookieHeader, '');
    });
  });
}
