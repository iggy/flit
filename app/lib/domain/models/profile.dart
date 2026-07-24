/// One agent profile as listed by `GET /api/profiles`
/// (docs/reference/03-mvp-wire-shapes.md §14).
///
/// A profile is a whole HERMES_HOME directory — picking one writes the
/// sticky pointer FUTURE gateway launches read; it does NOT retarget the
/// running gateway (docs/roadmap.md "Known caveat baked into the MVP —
/// profiles"). This model carries no live-session meaning.
///
/// Hand-written immutable model in the `gateway_status.dart` style — the
/// wire's snake_case quirks are absorbed in the repository
/// (05-conventions.md: "DTOs translate; domain models are clean").
library;

final class Profile {
  const Profile({
    required this.name,
    this.isDefault = false,
    this.model,
    this.provider,
    this.description,
    this.skillCount,
  });

  /// Profile name, e.g. `default`, `research` — the identity used by
  /// `POST /api/profiles/active {"name": ...}`.
  final String name;

  /// Wire `is_default`: the profile new gateway launches fall back to.
  final bool isDefault;

  /// Configured model, when known (wire `model`).
  final String? model;

  /// Configured provider, when known (wire `provider`).
  final String? provider;

  /// Human description, when set (wire `description`).
  final String? description;

  /// Number of skills installed in the profile (wire `skill_count`).
  final int? skillCount;

  @override
  bool operator ==(Object other) {
    return other is Profile &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.model == model &&
        other.provider == provider &&
        other.description == description &&
        other.skillCount == skillCount;
  }

  @override
  int get hashCode =>
      Object.hash(name, isDefault, model, provider, description, skillCount);

  @override
  String toString() {
    return 'Profile(name: $name, isDefault: $isDefault, model: $model, '
        'provider: $provider, description: $description, '
        'skillCount: $skillCount)';
  }
}
