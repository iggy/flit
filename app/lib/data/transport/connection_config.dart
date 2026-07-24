/// Connection configuration for a Hermes Agent gateway, shared by the REST
/// and WebSocket (JSON-RPC) clients.
///
/// Pure helpers — URL normalization, WS-URL construction, and log-safe URL
/// redaction — ported from `apps/desktop/electron/connection-config.ts` and
/// `ui-tui/src/gatewayClient.ts` (`redactUrl`) in the hermes-agent repo.
/// See docs/reference/01-gateway-protocol.md §1–§2.
library;

/// How the gateway authenticates clients (advertised by `GET /api/status`
/// via `auth_required`; docs/reference/01-gateway-protocol.md §1).
enum AuthMode {
  /// Legacy static dashboard session token. REST uses an
  /// `X-Hermes-Session-Token` header; WS uses `?token=` (protocol §2.1).
  token,

  /// Hosted gateway behind an OAuth provider. REST uses an HttpOnly session
  /// cookie; WS upgrades use a single-use `?ticket=` minted at
  /// `POST /api/auth/ws-ticket` (protocol §2.2 — Phase 8).
  oauth,
}

/// Immutable description of one gateway connection.
///
/// [baseUrl] is normalized on construction (see [normalizeGatewayBaseUrl]):
/// http/https only, no trailing slashes, no query string, no hash fragment,
/// path prefix preserved.
final class ConnectionConfig {
  factory ConnectionConfig({
    required String baseUrl,
    String? token,
    AuthMode authMode = AuthMode.token,
  }) {
    return ConnectionConfig._(
      normalizeGatewayBaseUrl(baseUrl),
      token,
      authMode,
    );
  }

  const ConnectionConfig._(this.baseUrl, this.token, this.authMode);

  /// Normalized gateway base URL, e.g. `https://gw.example.com/hermes`.
  final String baseUrl;

  /// The session token (token mode only). Never log this value.
  final String? token;

  /// The auth mode the gateway uses.
  final AuthMode authMode;

  @override
  bool operator ==(Object other) {
    return other is ConnectionConfig &&
        other.baseUrl == baseUrl &&
        other.token == token &&
        other.authMode == authMode;
  }

  @override
  int get hashCode => Object.hash(baseUrl, token, authMode);

  /// Token-redacted representation — safe for logs (05-conventions.md:
  /// "No secrets in logs").
  @override
  String toString() {
    return 'ConnectionConfig(baseUrl: ${redactUrl(baseUrl)}, '
        'authMode: ${authMode.name}, token: ${token == null ? 'null' : '***'})';
  }
}

/// Normalize a user-supplied gateway base URL.
///
/// Mirrors `normalizeRemoteBaseUrl` in
/// `apps/desktop/electron/connection-config.ts`:
/// - rejects empty input and non-http(s) schemes with [ArgumentError];
/// - strips the hash fragment and query string;
/// - strips trailing slash(es);
/// - preserves any path prefix (`https://host/hermes/` → `https://host/hermes`).
String normalizeGatewayBaseUrl(String rawUrl) {
  final value = rawUrl.trim();

  if (value.isEmpty) {
    throw ArgumentError('Remote gateway URL is required.');
  }

  final Uri parsed;
  try {
    parsed = Uri.parse(value);
  } on FormatException catch (error) {
    throw ArgumentError('Remote gateway URL is not valid: ${error.message}');
  }

  // Dart's Uri.parse is lenient (a bare word parses as a path), so treat a
  // missing scheme or host as "not valid" — WHATWG `new URL()` throws there.
  if (parsed.scheme.isEmpty || (parsed.hasAuthority && parsed.host.isEmpty)) {
    throw ArgumentError('Remote gateway URL is not valid: $value');
  }

  if (parsed.scheme != 'http' && parsed.scheme != 'https') {
    throw ArgumentError(
      'Remote gateway URL must be http:// or https://, got ${parsed.scheme}:',
    );
  }

  if (parsed.host.isEmpty) {
    throw ArgumentError('Remote gateway URL is not valid: $value');
  }

  final path = parsed.path.replaceAll(RegExp(r'/+$'), '');

  final normalized = Uri(
    scheme: parsed.scheme,
    userInfo: parsed.userInfo,
    host: parsed.host,
    port: parsed.hasPort ? parsed.port : null,
    path: path,
  );

  // Parity with the JS `.replace(/\/+$/, '')` on the stringified URL —
  // a no-op for the empty path (Dart omits the lone `/`), kept as a safety net.
  return normalized.toString().replaceAll(RegExp(r'/+$'), '');
}

/// Build the WebSocket URL for `/api/ws` (docs/reference/01-gateway-protocol.md
/// §2.1), mirroring `buildGatewayWsUrl`:
/// `ws` for `http:`, `wss` for `https:`, any path prefix preserved.
///
/// The `?token=` query is appended **only in token mode** when a token is set
/// (WS auth is query-string only — browsers/clients cannot set headers on the
/// upgrade). OAuth mode uses a `?ticket=` flow deferred to Phase 8, so this
/// returns the bare WS URL there.
Uri wsUriFor(ConnectionConfig config) {
  final parsed = Uri.parse(config.baseUrl);
  final wsScheme = parsed.scheme == 'https' ? 'wss' : 'ws';
  final prefix = parsed.path.replaceAll(RegExp(r'/+$'), '');

  final buffer = StringBuffer()
    ..write(wsScheme)
    ..write('://')
    ..write(parsed.host);
  if (parsed.hasPort) {
    buffer
      ..write(':')
      ..write(parsed.port);
  }
  buffer
    ..write(prefix)
    ..write('/api/ws');

  final token = config.token;
  if (config.authMode == AuthMode.token && token != null) {
    buffer
      ..write('?token=')
      ..write(Uri.encodeComponent(token));
  }

  return Uri.parse(buffer.toString());
}

/// Matches `<scheme>://user:pass@host…` style user-info segments in
/// otherwise-unparseable URLs. Used by the [redactUrl] fallback so embedded
/// credentials are scrubbed from log lines even when the URL is malformed.
final RegExp _userInfoFallbackRe = RegExp(
  '^([a-z][a-z0-9+.-]*://)[^/?#@]*@',
  caseSensitive: false,
);

/// Redact a connection URL for logging — never emit a token or embedded
/// credential. Port of `redactUrl` in `ui-tui/src/gatewayClient.ts`:
/// user-info becomes `***@` and any query string becomes `?***`.
String redactUrl(String raw) {
  if (raw.isEmpty) {
    return raw;
  }

  final parsed = Uri.tryParse(raw);
  if (parsed != null && parsed.scheme.isNotEmpty && parsed.host.isNotEmpty) {
    final userInfo = parsed.userInfo.isNotEmpty ? '***@' : '';
    final port = parsed.hasPort ? ':${parsed.port}' : '';
    final query = parsed.query.isNotEmpty ? '?***' : '';

    return '${parsed.scheme}://$userInfo${parsed.host}$port'
        '${parsed.path}$query';
  }

  // Fallback for unparseable input: strip an embedded `user:pass@` segment
  // AND the query string so a malformed token bearer can never escape into
  // the log tail.
  final noUserInfo = raw.replaceFirstMapped(
    _userInfoFallbackRe,
    (match) => '${match[1]}***@',
  );
  final queryIndex = noUserInfo.indexOf('?');

  return queryIndex >= 0
      ? '${noUserInfo.substring(0, queryIndex)}?***'
      : noUserInfo;
}
