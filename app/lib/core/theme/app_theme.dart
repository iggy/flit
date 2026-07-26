/// Material 3 theme (docs/design/theming.md: "fresh Material 3 with dynamic
/// color now, match-Hermes-skin later").
///
/// Every widget must read colors from `Theme.of(context)` — never hard-code
/// hex — so the optional skin swap stays a single seam (theming.md).
library;

import 'package:flit/core/theme/skin_color_scheme.dart';
import 'package:flit/domain/models/gateway_skin.dart';
import 'package:flutter/material.dart';

/// App light/dark themes built from a single seed color.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF6750A4); // M3 default purple

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  /// Build a light theme from the given [skin], or fall back to M3 (P9-07).
  static ThemeData lightFor(GatewaySkin? skin) {
    return themeFromSkin(skin ?? _unusableSkin, brightness: Brightness.light) ??
        light();
  }

  /// Build a dark theme from the given [skin], or fall back to M3 (P9-07).
  static ThemeData darkFor(GatewaySkin? skin) {
    return themeFromSkin(skin ?? _unusableSkin, brightness: Brightness.dark) ??
        dark();
  }

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const GatewaySkin _unusableSkin = GatewaySkin(
    name: '',
    colors: <String, String>{},
    branding: <String, String>{},
  );
}
