/// OAuth session tokens (RFC 8252 native-app flow; Phase 8 tickets P8-01–P8-03).
///
/// Immutable snapshot of an access/refresh token pair minted by the gateway
/// at `POST /auth/native/token` (code exchange) or
/// `POST /auth/native/refresh` (rotation). The session is short-lived (access
/// token ~15 min) and MUST be refreshed before `expiresAt` to keep the
/// gateway connection alive. Stored in secure storage only; never log the
/// tokens themselves (toString() redacts them).
library;

/// OAuth session holding an access token (for REST Bearer auth and WS ticket
/// minting) and a refresh token (for rotation when the access token expires).
final class OAuthSession {
  const OAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.provider,
  });

  /// The access token for `Authorization: Bearer` on REST (short-lived, ~15m).
  /// NEVER log this value — toString() redacts it.
  final String accessToken;

  /// The refresh token for rotation (`POST /auth/native/refresh`).
  /// ROTATING: the gateway returns a fresh pair on each refresh, so both
  /// must be re-stored. NEVER log this value.
  final String refreshToken;

  /// Unix epoch seconds when [accessToken] expires. Refresh proactively when
  /// within ~60s of expiry (see [expiresSoon]).
  final int expiresAt;

  /// The OAuth provider slug (e.g. `nous`, `google`) — needed for refresh.
  final String provider;

  /// True when the access token has already expired (compare wall clock to
  /// [expiresAt] in epoch seconds).
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiresAt;
  }

  /// True when the access token expires within [margin] (proactively refresh
  /// to avoid a race where a REST call happens mid-flight as the token dies).
  /// Default margin is 60 seconds.
  bool expiresSoon([Duration margin = const Duration(seconds: 60)]) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cutoff = expiresAt - margin.inSeconds;
    return now >= cutoff;
  }

  @override
  bool operator ==(Object other) {
    return other is OAuthSession &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiresAt == expiresAt &&
        other.provider == provider;
  }

  @override
  int get hashCode => Object.hash(
        accessToken,
        refreshToken,
        expiresAt,
        provider,
      );

  /// Token-redacted representation — safe for logs (never emit secrets).
  @override
  String toString() {
    return 'OAuthSession(accessToken: ***, refreshToken: ***, '
        'expiresAt: $expiresAt, provider: $provider, '
        'isExpired: $isExpired)';
  }
}
