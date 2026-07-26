import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for PKCE S256 code_challenge generation (RFC 7636).
void main() {
  group('PKCE S256', () {
    test('computes the correct challenge for a known verifier', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      // SHA256(verifier) -> base64url(bytes) without padding
      final hash = sha256.convert(utf8.encode(verifier));
      final challenge = base64UrlEncode(hash.bytes).replaceAll('=', '');

      // Known S256 challenge for the above verifier (from RFC 7636 Appendix B).
      const expectedChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';
      expect(challenge, expectedChallenge);
    });

    test('challenge is base64url-encoded without padding', () {
      const verifier = 'test-verifier-123';
      final hash = sha256.convert(utf8.encode(verifier));
      final challenge = base64UrlEncode(hash.bytes).replaceAll('=', '');

      // Should not contain padding '=' or base64 (non-url-safe) chars '+/'
      expect(challenge, isNot(contains('=')));
      expect(challenge, isNot(contains('+')));
      expect(challenge, isNot(contains('/')));
      // Should be 43 chars (256 bits / 6 bits per char, unpadded)
      expect(challenge.length, 43);
    });
  });
}
