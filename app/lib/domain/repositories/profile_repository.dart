import 'package:hermes/domain/models/profile.dart';

/// Intent-level profile operations (ticket P1-13) — REST, NOT RPC (there is
/// no `profile.*` method; docs/roadmap.md "profiles caveat").
///
/// HONEST SEMANTICS: a profile is a whole HERMES_HOME. [setActive] writes
/// the sticky pointer FUTURE gateway launches read; it does NOT retarget
/// the running gateway. Callers must never present this as a hot-swap.
abstract interface class ProfileRepository {
  /// `GET /api/profiles` → the gateway's profiles (wire §14).
  Future<List<Profile>> list();

  /// `GET /api/profiles/active` → the active profile name, or null when
  /// the gateway reports none.
  Future<String?> active();

  /// `POST /api/profiles/active {"name": name}` — sets the sticky pointer
  /// for NEW gateway launches only.
  Future<void> setActive(String name);
}
