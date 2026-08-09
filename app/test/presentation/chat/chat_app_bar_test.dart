// The chat app bar adapts to the width it has.
//
// On a phone in portrait the bar carried more actions than fit, and Material
// clipped the overflowing ones — they could not be tapped at all. So narrow
// layouts keep the connection chip and the model picker and move everything
// else into an overflow menu, while wide layouts keep every action inline.

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/profiles/profile_providers.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/profile.dart';
import 'package:flit/domain/repositories/profile_repository.dart';
import 'package:flit/presentation/chat/chat_app_bar.dart';
import 'package:flit/presentation/models/model_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeProfileRepository implements ProfileRepository {
  @override
  Future<List<Profile>> list() async => const <Profile>[
    Profile(name: 'default', isDefault: true),
  ];

  @override
  Future<String?> active() async => 'default';

  @override
  Future<void> setActive(String name) async {}
}

void main() {
  Widget harness() {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        connectionStateProvider.overrideWith(
          (ref) => Stream<GatewayConnectionState>.value(
            GatewayConnectionState.ready,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(appBar: ChatAppBar(), body: SizedBox.shrink()),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness());
    await tester.pump();
  }

  testWidgets('wide layout keeps every action inline', (tester) async {
    await pumpAt(tester, const Size(1200, 800));

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Hermes'), findsOneWidget);
    expect(find.byType(ModelPickerButton), findsOneWidget);
    for (final tooltip in <String>[
      'Connected',
      'Profiles',
      'Session info',
      'Commands',
      'Plugins',
      'Agents',
      'Settings',
      'Sign out',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
  });

  testWidgets('phone portrait collapses actions into an overflow menu', (
    tester,
  ) async {
    await pumpAt(tester, const Size(411, 891));

    // Kept in the bar: connection state and the model picker (as the title).
    expect(find.byTooltip('Connected'), findsOneWidget);
    expect(find.byType(ModelPickerButton), findsOneWidget);
    // Collapsed away — these were the actions being clipped.
    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip('Sign out'), findsNothing);
    expect(find.byTooltip('Plugins'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    for (final label in <String>[
      'Session info',
      'Profiles',
      'Command palette',
      'Commands',
      'Plugins',
      'Agents',
      'Settings',
      'Sign out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a large accessibility font also collapses the bar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          connectionStateProvider.overrideWith(
            (ref) => Stream<GatewayConnectionState>.value(
              GatewayConnectionState.ready,
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: const Scaffold(appBar: ChatAppBar(), body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('no overflow is reported on a phone-width bar', (tester) async {
    await pumpAt(tester, const Size(360, 780));
    expect(tester.takeException(), isNull);
  });
}
