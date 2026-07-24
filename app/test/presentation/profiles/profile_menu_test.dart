// P1-13 acceptance: the profiles dropdown.
//
// - The menu lists the canned §14 profiles with the active one checked and
//   a '(default)' tag, and states the honest caveat copy.
// - Picking a profile calls setActive and shows the honest snackbar:
//   NEW gateway launches only — the running gateway is unchanged.
// - The unavailable state (older gateway 404) disables the app-bar button
//   with the 'Profiles unavailable on this gateway' tooltip.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/profiles/profile_providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/domain/models/profile.dart';
import 'package:hermes/domain/repositories/profile_repository.dart';
import 'package:hermes/presentation/profiles/profile_menu.dart';

/// Hand-rolled fake (same shape as the provider test's).
final class FakeProfileRepository implements ProfileRepository {
  List<Profile> listResult = const <Profile>[];
  Exception? listError;
  String? activeResult;
  Completer<List<Profile>>? listGate;

  final List<String> setActiveCalls = <String>[];

  @override
  Future<List<Profile>> list() {
    final gate = listGate;
    if (gate != null) {
      return gate.future;
    }
    final error = listError;
    if (error != null) {
      return Future<List<Profile>>.error(error);
    }
    return Future<List<Profile>>.value(listResult);
  }

  @override
  Future<String?> active() => Future<String?>.value(activeResult);

  @override
  Future<void> setActive(String name) async {
    setActiveCalls.add(name);
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
  Profile(name: 'research', model: 'hermes-4-70b', description: 'Research'),
];

void main() {
  late FakeProfileRepository repository;

  setUp(() => repository = FakeProfileRepository());

  Widget harness() {
    return ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: Scaffold(body: ProfileMenuButton())),
    );
  }

  Finder menuButton() => find.byIcon(Icons.person_outline);

  IconButton appBarButton(WidgetTester tester) {
    return tester.widget<IconButton>(
      find.ancestor(of: menuButton(), matching: find.byType(IconButton)),
    );
  }

  testWidgets('menu lists canned profiles with the active one checked', (
    tester,
  ) async {
    repository.listResult = cannedProfiles;
    repository.activeResult = 'default';

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle(); // profiles + active load

    await tester.tap(menuButton());
    await tester.pumpAndSettle(); // menu opens

    // The honest caveat copy, stated in the dropdown itself (roadmap).
    expect(
      find.text('Active profile for new gateway launches'),
      findsOneWidget,
    );
    // Both canned profiles, with model + default tag.
    expect(find.text('default'), findsOneWidget);
    expect(find.text(' (default)'), findsOneWidget);
    expect(find.text('hermes-4-405b'), findsOneWidget);
    expect(find.text('research'), findsOneWidget);
    // Exactly one check mark — on the active profile.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets(
    'picking a profile calls setActive and shows the honest snackbar',
    (tester) async {
      repository.listResult = cannedProfiles;
      repository.activeResult = 'default';

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.tap(menuButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('research'));
      await tester.pumpAndSettle(); // menu closes, POST completes, snackbar

      expect(repository.setActiveCalls, <String>['research']);
      // The EXACT honest caveat (P1-13 acceptance): NEW launches only.
      expect(
        find.text(
          'Profile "research" will be used for NEW gateway launches — '
          'the running gateway is unchanged.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('unavailable state disables the button with the tooltip', (
    tester,
  ) async {
    // Older gateway: /api/profiles 404s (mapped by GatewayRestClient).
    repository.listError = const GatewayNetworkException(
      'Gateway returned HTTP 404 (http://127.0.0.1:8765/api/profiles).',
    );

    await tester.pumpWidget(harness());
    await tester.pump(); // the failed list settles into AsyncError
    await tester.pump(); // unavailable flag rebuilds the button

    final button = appBarButton(tester);
    expect(button.onPressed, isNull); // disabled — no crash, no spinner
    expect(button.tooltip, 'Profiles unavailable on this gateway');
  });

  testWidgets('loading shows a subtle spinner inside the menu', (tester) async {
    repository.listGate = Completer<List<Profile>>();
    repository.activeResult = 'default';

    await tester.pumpWidget(harness());
    await tester.pump();

    // The button stays tappable while loading…
    expect(appBarButton(tester).onPressed, isNotNull);
    await tester.tap(menuButton());
    await tester.pump();
    await tester.pump();

    // …and the menu shows the subtle spinner, not an error.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading profiles…'), findsOneWidget);

    // Unblock the fake so no future dangles past the test.
    repository.listGate!.complete(cannedProfiles);
    await tester.pump();
  });
}
