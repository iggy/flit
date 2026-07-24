/// Session cookie jar for gated-mode auth
/// (docs/reference/01-gateway-protocol.md §2.2 steps 3–4).
///
/// The gateway's cookie names VARY by deploy (`__Host-`/`__Secure-`/bare
/// prefixes depending on HTTPS + path prefix — `cookies.py` `_resolved_name`),
/// so cookies are captured verbatim from `Set-Cookie` and replayed as a
/// `Cookie` header. The gate middleware rotates/refreshes the access-token
/// cookie and re-sets it on responses, so the jar must be updated from EVERY
/// response's `Set-Cookie`.
library;

/// A minimal, deliberate cookie store. Not RFC-complete — it stores only
/// name/value pairs (attributes are the server's concern; the gate sets
/// `Path`/`Max-Age` for browsers, a native client simply replays the pair
/// until the server rotates or expires it).
final class SessionCookieJar {
  final Map<String, String> _cookies = <String, String>{};

  /// Whether the jar holds no cookies.
  bool get isEmpty => _cookies.isEmpty;

  /// Whether the jar holds any cookies.
  bool get isNotEmpty => _cookies.isNotEmpty;

  /// The `Cookie` request-header value (`a=1; b=2`). Empty when jar is empty.
  String get cookieHeader =>
      _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  /// Names currently held (debugging only — never log values).
  Set<String> get names => Set.unmodifiable(_cookies.keys);

  /// Merge one response's `set-cookie` header lines into the jar.
  ///
  /// Each list entry is one full `Set-Cookie` string
  /// (`name=value; Attr=…; …`) — dio surfaces them pre-split. An empty value
  /// (a clearing cookie) removes the entry.
  void captureFromHeaders(List<String>? setCookieHeaders) {
    if (setCookieHeaders == null) {
      return;
    }
    for (final header in setCookieHeaders) {
      final firstSegment = header.split(';').first.trim();
      final eq = firstSegment.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final name = firstSegment.substring(0, eq).trim();
      final value = firstSegment.substring(eq + 1).trim();
      if (name.isEmpty) {
        continue;
      }
      if (value.isEmpty) {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
  }

  /// Drop all cookies (logout / session expired).
  void clear() {
    _cookies.clear();
  }

  /// Serializable view (for secure storage). Values are session tokens —
  /// persist ONLY in secure storage, never log.
  Map<String, String> toJson() => Map.unmodifiable(_cookies);

  /// Replace the jar's contents from a previously serialized map.
  void replaceFromJson(Map<String, String> json) {
    _cookies
      ..clear()
      ..addAll(json);
  }
}
