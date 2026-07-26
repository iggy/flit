/// Domain model for a gateway-pushed Hermes skin (ticket P9-07).
///
/// The gateway pushes a skin on `gateway.ready` and `skin.changed` events per
/// docs/reference/01-gateway-protocol.md §4. The color-role keys and branding
/// strings are TUI-oriented; presentation maps them to Material `ColorScheme`.
library;

/// A Hermes skin resolved by the gateway and pushed to the client.
///
/// Wire spec: `resolve_skin()` in tui_gateway/server.py (~line 1896); emitted
/// on `gateway.ready` and `skin.changed` events. An empty payload (`{}`) means
/// the gateway-side resolution failed — the client must fall back to M3.
final class GatewaySkin {
  const GatewaySkin({
    required this.name,
    required this.colors,
    this.lightColors,
    this.darkColors,
    required this.branding,
    this.bannerLogo,
    this.bannerHero,
    this.toolPrefix,
    this.helpHeader,
  });

  /// The skin name (e.g. 'hermes', 'dracula'). Empty when the gateway sent `{}`.
  final String name;

  /// Color role → hex string (e.g. `#rrggbb`). TUI-oriented keys: `background`,
  /// `status_bar_bg`, `ui_text`, `banner_text`, `ui_accent`, `ui_border`, etc.
  final Map<String, String> colors;

  /// Optional hand-tuned light-terminal variant of [colors]. May be absent.
  final Map<String, String>? lightColors;

  /// Optional hand-tuned dark-terminal variant of [colors]. May be absent.
  final Map<String, String>? darkColors;

  /// Branding strings: `agent_name`, `welcome`, `goodbye`, `response_label`,
  /// `prompt_symbol`, `help_header`. All optional on the wire.
  final Map<String, String> branding;

  /// Base64 banner logo, or null.
  final String? bannerLogo;

  /// Base64 banner hero image, or null.
  final String? bannerHero;

  /// Tool prefix string (e.g. '┊'), or null.
  final String? toolPrefix;

  /// Help header string, or null.
  final String? helpHeader;

  /// Whether this skin is usable: name is non-empty AND at least one color
  /// map (colors / lightColors / darkColors) has entries.
  bool get isUsable {
    if (name.trim().isEmpty) {
      return false;
    }
    return colors.isNotEmpty ||
        (lightColors?.isNotEmpty ?? false) ||
        (darkColors?.isNotEmpty ?? false);
  }

  @override
  bool operator ==(Object other) {
    return other is GatewaySkin &&
        other.name == name &&
        _mapEquals(other.colors, colors) &&
        _mapEquals(other.lightColors, lightColors) &&
        _mapEquals(other.darkColors, darkColors) &&
        _mapEquals(other.branding, branding) &&
        other.bannerLogo == bannerLogo &&
        other.bannerHero == bannerHero &&
        other.toolPrefix == toolPrefix &&
        other.helpHeader == helpHeader;
  }

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAll(colors.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(
      lightColors?.entries.map((e) => Object.hash(e.key, e.value)) ?? [],
    ),
    Object.hashAll(
      darkColors?.entries.map((e) => Object.hash(e.key, e.value)) ?? [],
    ),
    Object.hashAll(branding.entries.map((e) => Object.hash(e.key, e.value))),
    bannerLogo,
    bannerHero,
    toolPrefix,
    helpHeader,
  );

  @override
  String toString() {
    return 'GatewaySkin(name: $name, colors: ${colors.length} keys, '
        'lightColors: ${lightColors?.length ?? 0} keys, '
        'darkColors: ${darkColors?.length ?? 0} keys, '
        'branding: ${branding.length} keys)';
  }
}

bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
  if (a == null && b == null) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
