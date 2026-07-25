// P1-13 acceptance: the profile providers.
//
// - profilesProvider lists via the repository; ANY GatewayException (the
//   degrade rule — incl. a GatewayNetworkException whose message indicates
//   a 404 from an older gateway) flips profilesUnavailableProvider to true
//   and settles the AsyncValue (never a crash, never a forever-spinner).
// - activeProfileProvider degrades to null on failure.
// - ProfileActions.setActive posts via the repository, refreshes
//   activeProfileProvider, and never throws (false on failure).

import 'package:flit/application/profiles/profile_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/profile.dart';
import 'package:flit/domain/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake (established pattern — see
/// test/application/sessions/active_session_test.dart).
final class FakeProfileRepository implements ProfileRepository {
  List<Profile> listResult = const <Profile>[];
  Exception? listError;
  String? activeResult;
  Exception? activeError;
  Exception? setActiveError;

  /// Every name passed to setActive, in order.
  final List<String> setActiveCalls = <String>[];

  @override
  Future<List<Profile>> list() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    return listResult;
  }

  @override
  Future<String?> active() async {
    final error = activeError;
    if (error != null) {
      throw error;
    }
    return activeResult;
  }

  @override
  Future<void> setActive(String name) async {
    setActiveCalls.add(name);
    final error = setActiveError;
    if (error != null) {
      throw error;
    }
    // Mirror the real gateway: the sticky pointer moves.
    activeResult = name;
  }
}

const cannedProfiles = <Profile>[
  Profile(
    name: 'default',
    isDefault: true,
    model: 'hermes-4-405b',
    provider: 'nous',
    description: 'Default profile',
    skillCount: 12,
  ),
  Profile(name: 'research', model: 'hermes-4-70b'),
];

void main() {
  late FakeProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeProfileRepository();
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  group('profilesProvider', () {
    test('lists the repository profiles', () async {
      repository.listResult = cannedProfiles;

      expect(await container.read(profilesProvider.future), cannedProfiles);
      expect(container.read(profilesUnavailableProvider), isFalse);
    });

    test('degrade path: a 404 GatewayNetworkException marks profiles '
        'unavailable and settles (no crash, no forever-spinner)', () async {
      // What GatewayRestClient produces for an older gateway missing
      // /api/profiles (P1-13 notes).
      repository.listError = const GatewayNetworkException(
        'Gateway returned HTTP 404 (http://127.0.0.1:8765/api/profiles).',
      );

      // The error stays inside the AsyncValue — never rethrown to the UI.
      await expectLater(
        container.read(profilesProvider.future),
        throwsA(isA<GatewayNetworkException>()),
      );

      final state = container.read(profilesProvider);
      expect(state.hasError, isTrue);
      expect(state.isLoading, isFalse); // settled — no forever-spinner
      expect(container.read(profilesUnavailableProvider), isTrue);
    });

    test(
      'degrade path: ANY GatewayException marks profiles unavailable',
      () async {
        repository.listError = const GatewayAuthException('bad token');

        await expectLater(
          container.read(profilesProvider.future),
          throwsA(isA<GatewayAuthException>()),
        );
        expect(container.read(profilesUnavailableProvider), isTrue);
      },
    );

    test(
      'degrade path: disconnected (null repository) is unavailable',
      () async {
        final disconnected = ProviderContainer(
          overrides: [profileRepositoryProvider.overrideWithValue(null)],
        );
        addTearDown(disconnected.dispose);

        expect(await disconnected.read(profilesProvider.future), isEmpty);
        expect(disconnected.read(profilesUnavailableProvider), isTrue);
      },
    );
  });

  group('activeProfileProvider', () {
    test('returns the active profile name', () async {
      repository.activeResult = 'default';

      expect(await container.read(activeProfileProvider.future), 'default');
    });

    test('degrades to null when active() fails', () async {
      repository.activeError = const GatewayNetworkException('boom');

      expect(await container.read(activeProfileProvider.future), isNull);
    });
  });

  group('ProfileActions.setActive', () {
    test(
      'posts via the repository and refreshes activeProfileProvider',
      () async {
        repository.activeResult = 'default';
        expect(await container.read(activeProfileProvider.future), 'default');

        final ok = await container
            .read(profileActionsProvider)
            .setActive('research');

        expect(ok, isTrue);
        expect(repository.setActiveCalls, <String>['research']);
        // The check mark moves: activeProfileProvider was invalidated and
        // re-fetches from the (fake) gateway.
        expect(await container.read(activeProfileProvider.future), 'research');
      },
    );

    test('returns false (never throws) when the POST fails', () async {
      repository.setActiveError = const GatewayNetworkException('boom');

      final ok = await container
          .read(profileActionsProvider)
          .setActive('research');

      expect(ok, isFalse);
    });

    test('returns false when disconnected', () async {
      final disconnected = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(disconnected.dispose);

      final ok = await disconnected
          .read(profileActionsProvider)
          .setActive('research');

      expect(ok, isFalse);
    });
  });
}
