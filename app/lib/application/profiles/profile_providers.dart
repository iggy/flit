/// Riverpod wiring for the profiles dropdown (ticket P1-13).
///
/// Profiles are REST, not RPC (docs/roadmap.md "profiles caveat"), so
/// everything here hangs off [restClientProvider] — nullable when
/// disconnected, mirroring the `application/providers.dart` pattern.
///
/// THE DEGRADE RULE (P1-13 notes): older gateways 404 `/api/profiles`, and
/// ANY [GatewayException] from the list call means "profiles unavailable" —
/// the UI renders a DISABLED menu button with a tooltip. Nothing here may
/// crash the screen or spin forever: Riverpod captures a thrown
/// [GatewayException] into the `AsyncValue` (it is never re-thrown to the
/// widget tree), and [profilesUnavailableProvider] exposes it as a flag.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/repositories/profile_repository.dart';
import 'package:hermes/domain/models/profile.dart';
import 'package:hermes/domain/repositories/profile_repository.dart';

/// The profile repository for the current connection, or null when
/// disconnected (no REST client).
final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final client = ref.watch(restClientProvider);
  if (client == null) {
    return null;
  }
  return ProfileRepositoryImpl(client);
});

/// The gateway's profiles for the dropdown. A [GatewayException] from
/// `list()` (e.g. the 404 older gateways return) is deliberately left in
/// the `AsyncValue` as an error — the UI treats that state as
/// "unavailable" (see [profilesUnavailableProvider]) and renders a
/// disabled button, never an error widget, never a forever-spinner.
///
/// `retry` is DISABLED deliberately: Riverpod's default retry would keep
/// the provider in the LOADING state for ~38s of exponential backoff on
/// any [Exception] — that IS the forever-spinner the P1-13 degrade rule
/// forbids. A profiles failure (esp. the older-gateway 404) must settle
/// into the unavailable state immediately.
final profilesProvider = FutureProvider<List<Profile>>(
  retry: (retryCount, error) => null,
  (ref) async {
    final repository = ref.watch(profileRepositoryProvider);
    if (repository == null) {
      return const <Profile>[];
    }
    return repository.list();
  },
);

/// True when profiles can't be listed on this gateway: disconnected, or
/// the last `list()` attempt failed with any [GatewayException] (the P1-13
/// degrade rule — a [GatewayNetworkException] mentioning a 404 arises on
/// older gateways that predate the profiles endpoints). The dropdown MUST
/// render disabled with the 'Profiles unavailable on this gateway' tooltip
/// whenever this is true.
final profilesUnavailableProvider = Provider<bool>((ref) {
  if (ref.watch(profileRepositoryProvider) == null) {
    return true;
  }
  return ref.watch(profilesProvider).hasError;
});

/// The active profile name (`GET /api/profiles/active`), or null. Degrades
/// silently: on any [GatewayException] the menu simply shows no check mark
/// (the list itself may still be usable).
final activeProfileProvider = FutureProvider<String?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  if (repository == null) {
    return null;
  }
  try {
    return await repository.active();
  } on GatewayException {
    return null;
  }
});

/// Profile actions (P1-13). Separated from the data providers so picking a
/// menu entry can trigger a write + refresh without rebuilding the list.
final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});

class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  /// `POST /api/profiles/active {"name": name}` and refresh
  /// [activeProfileProvider] so the check mark moves.
  ///
  /// HONEST CAVEAT (P1-13 acceptance): this sets the profile for NEW
  /// gateway launches ONLY — the running gateway is unchanged. The UI
  /// surfaces that caveat as a snackbar on success; never imply a
  /// hot-swap.
  ///
  /// Returns false (never throws) when disconnected or the POST fails —
  /// the UI shows a plain failure snackbar instead.
  Future<bool> setActive(String name) async {
    final repository = _ref.read(profileRepositoryProvider);
    if (repository == null) {
      return false;
    }
    try {
      await repository.setActive(name);
    } on GatewayException {
      return false;
    }
    _ref.invalidate(activeProfileProvider);
    return true;
  }
}
