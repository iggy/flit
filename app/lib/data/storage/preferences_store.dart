/// Non-secret UI preferences persistence (Phase 9).
///
/// [ConnectionStore] owns everything auth-shaped; this store owns the local
/// look-and-feel/platform preferences that Phase 9 introduces (skin opt-in,
/// window geometry, notification opt-in). It reuses the same [KeyValueStore]
/// abstraction so it is testable without a platform channel, and the app wires
/// it to the same secure backend — one storage dependency, not two.
///
/// Every getter is failure-tolerant: a missing, corrupt, or non-parsable value
/// reads back as null/false rather than throwing, so a bad write can never
/// brick app start.
library;

import 'dart:convert';

import 'package:flit/data/storage/connection_store.dart';

/// Persisted desktop window geometry (ticket P9-01).
final class WindowGeometry {
  const WindowGeometry({
    required this.width,
    required this.height,
    this.x,
    this.y,
    this.maximized = false,
  });

  /// Parse from the persisted JSON map; returns null when unusable.
  static WindowGeometry? fromJson(Map<String, dynamic> json) {
    final width = json['width'];
    final height = json['height'];
    if (width is! num || height is! num) {
      return null;
    }
    final x = json['x'];
    final y = json['y'];
    return WindowGeometry(
      width: width.toDouble(),
      height: height.toDouble(),
      x: x is num ? x.toDouble() : null,
      y: y is num ? y.toDouble() : null,
      maximized: json['maximized'] == true,
    );
  }

  final double width;
  final double height;
  final double? x;
  final double? y;
  final bool maximized;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'width': width,
    'height': height,
    if (x != null) 'x': x,
    if (y != null) 'y': y,
    'maximized': maximized,
  };

  @override
  bool operator ==(Object other) {
    return other is WindowGeometry &&
        other.width == width &&
        other.height == height &&
        other.x == x &&
        other.y == y &&
        other.maximized == maximized;
  }

  @override
  int get hashCode => Object.hash(width, height, x, y, maximized);

  @override
  String toString() =>
      'WindowGeometry(width: $width, height: $height, x: $x, y: $y, '
      'maximized: $maximized)';
}

/// Reads/writes the Phase 9 UI preferences.
final class PreferencesStore {
  const PreferencesStore(this._store);

  final KeyValueStore _store;

  /// P9-07: apply the gateway-pushed Hermes skin instead of the Material 3
  /// seed theme. Off by default (docs/design/theming.md ships M3 first).
  static const String skinEnabledKey = 'prefs.skin_enabled';

  /// P9-01: last desktop window geometry, JSON-encoded.
  static const String windowGeometryKey = 'prefs.window_geometry';

  /// P9-03: local notifications opt-in. Off until the user enables it (the
  /// platform permission prompt is only raised on enable).
  static const String notificationsEnabledKey = 'prefs.notifications_enabled';

  Future<bool> loadSkinEnabled() => _loadBool(skinEnabledKey);

  Future<void> saveSkinEnabled(bool enabled) =>
      _store.write(skinEnabledKey, enabled ? 'true' : 'false');

  Future<bool> loadNotificationsEnabled() => _loadBool(notificationsEnabledKey);

  Future<void> saveNotificationsEnabled(bool enabled) =>
      _store.write(notificationsEnabledKey, enabled ? 'true' : 'false');

  /// The stored geometry, or null when absent/corrupt.
  Future<WindowGeometry?> loadWindowGeometry() async {
    final raw = await _read(windowGeometryKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return WindowGeometry.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> saveWindowGeometry(WindowGeometry geometry) =>
      _store.write(windowGeometryKey, jsonEncode(geometry.toJson()));

  Future<bool> _loadBool(String key) async {
    final raw = await _read(key);
    return raw == 'true';
  }

  /// A read that never throws — a failing storage backend reads as absent.
  Future<String?> _read(String key) async {
    try {
      return await _store.read(key);
    } on Object {
      return null;
    }
  }
}
