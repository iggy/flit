/// DTO for the gateway-pushed skin payload (ticket P9-07).
///
/// Wire shape: `resolve_skin()` in tui_gateway/server.py, emitted as the
/// `payload` of `gateway.ready` and `skin.changed` events. The payload is
/// loose-typed JSON (`{}` on failure, color values may be non-string, maps may
/// be Lists or strings), so parsing is defensive — never throws.
library;

import 'package:flit/domain/models/gateway_skin.dart';

/// Parse a wire skin payload into a domain [GatewaySkin], or null when the
/// payload is unusable (empty, malformed, or has no colors).
///
/// Never throws: wrong-typed fields are dropped, non-string color values are
/// skipped, and `{}` returns null.
GatewaySkin? parseGatewaySkinPayload(Map<String, dynamic> payload) {
  try {
    final name = payload['name'];
    if (name is! String || name.trim().isEmpty) {
      return null;
    }

    final colors = _parseColorMap(payload['colors']);
    final lightColors = _parseColorMap(payload['light_colors']);
    final darkColors = _parseColorMap(payload['dark_colors']);

    // At least one color map must be usable.
    if (colors.isEmpty && lightColors.isEmpty && darkColors.isEmpty) {
      return null;
    }

    final branding = _parseStringMap(payload['branding']);

    final skin = GatewaySkin(
      name: name.trim(),
      colors: colors,
      lightColors: lightColors.isNotEmpty ? lightColors : null,
      darkColors: darkColors.isNotEmpty ? darkColors : null,
      branding: branding,
      bannerLogo: _asString(payload['banner_logo']),
      bannerHero: _asString(payload['banner_hero']),
      toolPrefix: _asString(payload['tool_prefix']),
      helpHeader: _asString(payload['help_header']),
    );

    return skin.isUsable ? skin : null;
  } on Object {
    return null;
  }
}

/// Parse a wire color map (role → hex string). Non-map values return empty;
/// non-string color values are dropped.
Map<String, String> _parseColorMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key;
    final val = entry.value;
    if (key is String && val is String && val.isNotEmpty) {
      result[key] = val;
    }
  }
  return result;
}

/// Parse a generic string map. Non-map values return empty; non-string values
/// are dropped.
Map<String, String> _parseStringMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key;
    final val = entry.value;
    if (key is String && val is String) {
      result[key] = val;
    }
  }
  return result;
}

String? _asString(Object? value) => value is String ? value : null;
