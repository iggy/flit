/// Hermes skin → Material `ColorScheme` mapper (ticket P9-07).
///
/// Ports the desktop app's strategy from
/// `apps/desktop/src/themes/skin.ts` and `color.ts`: seed from terminal-shaped
/// keys (background, ui_text, ui_accent), bucket light/dark by luminance, and
/// derive every Material surface by mixing toward the seeded bg/fg. Small pure
/// helpers (no I/O, no Riverpod) so unit tests cover the mapping.
library;

import 'dart:math' as math;

import 'package:flit/domain/models/gateway_skin.dart';
import 'package:flutter/material.dart';

/// Parse a CSS hex color into a [Color], accepting:
/// - `#rgb` / `rgb` (3-char shorthand)
/// - `#rrggbb` / `rrggbb` (6-char)
/// - `#aarrggbb` / `aarrggbb` (8-char with alpha)
///
/// Returns null for malformed input (never throws).
Color? parseHexColor(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  var clean = value.trim().replaceFirst('#', '');

  // Expand shorthand #rgb or #rgba to full width.
  if (clean.length == 3 || clean.length == 4) {
    clean = clean.split('').map((ch) => ch + ch).join('');
  }

  if (!RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(clean)) {
    return null;
  }

  try {
    final value = int.parse(clean, radix: 16);
    if (clean.length == 6) {
      return Color(0xFF000000 | value);
    } else {
      // 8-char: aarrggbb
      return Color(value);
    }
  } on FormatException {
    return null;
  }
}

/// WCAG relative luminance (0..1) for a color.
double relativeLuminance(Color color) {
  final r = _linearize((color.r * 255.0).round().clamp(0, 255) / 255);
  final g = _linearize((color.g * 255.0).round().clamp(0, 255) / 255);
  final b = _linearize((color.b * 255.0).round().clamp(0, 255) / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _linearize(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG contrast ratio (1..21) between two colors.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  return la >= lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// Perceptual-ish luminance (0..1) for light/dark bucketing. Naive formula,
/// not gamma-corrected like [relativeLuminance].
double luminance(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255) / 255;
  final g = (color.g * 255.0).round().clamp(0, 255) / 255;
  final b = (color.b * 255.0).round().clamp(0, 255) / 255;
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Mix two colors linearly by [t] ∈ [0, 1].
Color mixColors(Color a, Color b, double t) {
  final aRed = (a.r * 255.0).round().clamp(0, 255);
  final aGreen = (a.g * 255.0).round().clamp(0, 255);
  final aBlue = (a.b * 255.0).round().clamp(0, 255);
  final bRed = (b.r * 255.0).round().clamp(0, 255);
  final bGreen = (b.g * 255.0).round().clamp(0, 255);
  final bBlue = (b.b * 255.0).round().clamp(0, 255);
  return Color.fromARGB(
    255,
    (aRed + (bRed - aRed) * t).round().clamp(0, 255),
    (aGreen + (bGreen - aGreen) * t).round().clamp(0, 255),
    (aBlue + (bBlue - aBlue) * t).round().clamp(0, 255),
  );
}

/// Returns a readable foreground (#161616 or #ffffff) for a background color.
Color readableOn(Color bg) {
  return luminance(bg) > 0.58
      ? const Color(0xFF161616)
      : const Color(0xFFFFFFFF);
}

/// Guarantee [fg] reads against [bg]: if it's below [minRatio] contrast, mix
/// it toward white (on dark bg) or black (on light bg) until it clears.
Color ensureContrast(Color fg, Color bg, double minRatio) {
  if (contrastRatio(fg, bg) >= minRatio) {
    return fg;
  }
  final towards = luminance(bg) < 0.5
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
  var best = fg;
  for (double amount = 0.2; amount <= 1.0001; amount += 0.2) {
    best = mixColors(fg, towards, math.min(amount, 1));
    if (contrastRatio(best, bg) >= minRatio) {
      return best;
    }
  }
  return best;
}

/// Pick the first parsable hex color from [keys] in [colors], or null.
Color? _pickColor(Map<String, String> colors, List<String> keys) {
  for (final key in keys) {
    final hex = colors[key];
    if (hex != null) {
      final color = parseHexColor(hex);
      if (color != null) {
        return color;
      }
    }
  }
  return null;
}

/// Build a Material [ColorScheme] from a [GatewaySkin], or null when the skin
/// has no usable colors.
///
/// For [Brightness.light] prefers [GatewaySkin.lightColors] when present; for
/// [Brightness.dark] prefers [GatewaySkin.darkColors]. Falls back to
/// [GatewaySkin.colors] when the preferred map is absent/empty.
///
/// The produced scheme's [ColorScheme.brightness] ALWAYS matches the requested
/// [brightness] — the surface colors are derived to be consistent with the
/// requested mode even if the skin's palette reads as the opposite mode.
ColorScheme? colorSchemeFromSkin(
  GatewaySkin skin, {
  required Brightness brightness,
}) {
  if (!skin.isUsable) {
    return null;
  }

  // Pick the color map: prefer lightColors for light, darkColors for dark,
  // fall back to colors.
  final Map<String, String> palette;
  if (brightness == Brightness.light &&
      skin.lightColors != null &&
      skin.lightColors!.isNotEmpty) {
    palette = skin.lightColors!;
  } else if (brightness == Brightness.dark &&
      skin.darkColors != null &&
      skin.darkColors!.isNotEmpty) {
    palette = skin.darkColors!;
  } else {
    palette = skin.colors;
  }

  if (palette.isEmpty) {
    return null;
  }

  // Seed background from terminal keys: background > status_bar_bg.
  final backgroundSeed = _pickColor(palette, ['background', 'status_bar_bg']);

  // Seed foreground from text keys: ui_text > banner_text > status_bar_text.
  final foregroundSeed = _pickColor(palette, [
    'ui_text',
    'banner_text',
    'status_bar_text',
  ]);

  // No background given: bucket by foreground luminance (light text ⇒ dark app).
  final Color background;
  if (backgroundSeed != null) {
    background = backgroundSeed;
  } else if (foregroundSeed != null && luminance(foregroundSeed) > 0.5) {
    // Light foreground → dark background.
    background = const Color(0xFF141414);
  } else {
    // Dark foreground or no foreground → light background.
    background = const Color(0xFFF7F7F8);
  }

  // Determine if the palette is dark-mode by luminance.
  final isDark = luminance(background) < 0.4;

  // Foreground: use seed or infer from background.
  final foreground =
      foregroundSeed ??
      (isDark ? const Color(0xFFE6E6E6) : const Color(0xFF161616));

  // Accent seed: ui_accent > banner_accent > banner_title, fall back to a mix.
  final accentSeed =
      _pickColor(palette, ['ui_accent', 'banner_accent', 'banner_title']) ??
      mixColors(foreground, background, 0.55);

  // Accent with contrast guarantee for small text (WCAG AA normal text).
  final accent = ensureContrast(accentSeed, background, 4.5);

  // Border: ui_border > banner_border, or a derived tint.
  final border =
      _pickColor(palette, ['ui_border', 'banner_border']) ??
      mixColors(background, foreground, isDark ? 0.16 : 0.14);

  // Muted foreground: banner_dim > session_border, or a mix.
  final mutedForeground =
      _pickColor(palette, ['banner_dim', 'session_border']) ??
      mixColors(foreground, background, 0.45);

  // Error/destructive: ui_error, or a fallback red.
  final destructive =
      _pickColor(palette, ['ui_error']) ?? const Color(0xFFE25563);

  // Now derive surfaces by mixing toward background/foreground. If the requested
  // brightness is opposite to the palette's mode, we still emit consistent values.
  // For example, if the palette is dark but light was requested, we derive lighter
  // surfaces so the scheme reads as light-mode.

  final Color surface;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  if (brightness == Brightness.light) {
    // Light mode: surfaces are lightened from background.
    if (isDark) {
      // Palette is dark but we need light: lighten aggressively.
      surface = mixColors(background, const Color(0xFFFFFFFF), 0.85);
      surfaceContainerLow = mixColors(surface, const Color(0xFFFFFFFF), 0.05);
      surfaceContainer = mixColors(surface, const Color(0xFF000000), 0.04);
      surfaceContainerHigh = mixColors(surface, const Color(0xFF000000), 0.08);
      surfaceContainerHighest = mixColors(
        surface,
        const Color(0xFF000000),
        0.12,
      );
    } else {
      // Palette is already light.
      surface = background;
      surfaceContainerLow = mixColors(background, foreground, 0.02);
      surfaceContainer = mixColors(background, foreground, 0.04);
      surfaceContainerHigh = mixColors(background, foreground, 0.08);
      surfaceContainerHighest = mixColors(background, foreground, 0.12);
    }
  } else {
    // Dark mode: surfaces are darkened from background.
    if (!isDark) {
      // Palette is light but we need dark: darken aggressively.
      surface = mixColors(background, const Color(0xFF000000), 0.85);
      surfaceContainerLow = mixColors(surface, const Color(0xFF000000), 0.05);
      surfaceContainer = mixColors(surface, const Color(0xFFFFFFFF), 0.04);
      surfaceContainerHigh = mixColors(surface, const Color(0xFFFFFFFF), 0.08);
      surfaceContainerHighest = mixColors(
        surface,
        const Color(0xFFFFFFFF),
        0.12,
      );
    } else {
      // Palette is already dark.
      surface = background;
      surfaceContainerLow = mixColors(background, foreground, 0.02);
      surfaceContainer = mixColors(background, foreground, 0.04);
      surfaceContainerHigh = mixColors(background, foreground, 0.08);
      surfaceContainerHighest = mixColors(background, foreground, 0.12);
    }
  }

  // Build the scheme with the requested brightness.
  return ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: readableOn(accent),
    primaryContainer: mixColors(accent, background, isDark ? 0.72 : 0.86),
    onPrimaryContainer: foreground,
    secondary: mixColors(accent, background, isDark ? 0.82 : 0.88),
    onSecondary: foreground,
    secondaryContainer: mixColors(accent, background, isDark ? 0.88 : 0.92),
    onSecondaryContainer: foreground,
    tertiary: accent,
    onTertiary: readableOn(accent),
    tertiaryContainer: mixColors(accent, background, isDark ? 0.75 : 0.88),
    onTertiaryContainer: foreground,
    error: destructive,
    onError: readableOn(destructive),
    errorContainer: mixColors(destructive, background, isDark ? 0.8 : 0.9),
    onErrorContainer: foreground,
    surface: surface,
    onSurface: foreground,
    onSurfaceVariant: mutedForeground,
    outline: border,
    outlineVariant: mixColors(border, background, 0.5),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: isDark ? const Color(0xFFE6E6E6) : const Color(0xFF303030),
    onInverseSurface: isDark
        ? const Color(0xFF303030)
        : const Color(0xFFE6E6E6),
    inversePrimary: mixColors(
      accent,
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      0.3,
    ),
    surfaceTint: accent,
    surfaceContainerLowest: surfaceContainerLow,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
  );
}

/// Build a Material [ThemeData] from a [GatewaySkin], or null when the skin
/// has no usable colors. Uses the same [InputDecorationTheme] and
/// [SnackBarTheme] as the M3 fallback (`AppTheme._base`).
ThemeData? themeFromSkin(GatewaySkin skin, {required Brightness brightness}) {
  final scheme = colorSchemeFromSkin(skin, brightness: brightness);
  if (scheme == null) {
    return null;
  }
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
