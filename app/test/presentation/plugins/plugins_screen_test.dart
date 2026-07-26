// P1-14, P5-08 acceptance: the plugins screen renders rich plugins with
// description, source, and a Switch for toggling. The kanban "Open board"
// affordance shows ONLY when kanban is present AND enabled.

import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flit/presentation/plugins/plugins_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/plugins/plugin_providers_test.dart'
    show FakePluginRepository;

Widget _wrap(FakePluginRepository repository) {
  return ProviderScope(
    overrides: [pluginRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: PluginsScreen()),
  );
}

void main() {
  testWidgets('renders plugins with version, description, and source', (
    tester,
  ) async {
    final repository = FakePluginRepository(
      details: const <PluginDetail>[
        PluginDetail(
          name: 'kanban',
          version: '1.0.0',
          description: 'Kanban board plugin',
          source: 'bundled',
          status: 'enabled',
        ),
        PluginDetail(
          name: 'spotify',
          version: '0.5.0',
          description: 'Spotify integration',
          source: 'user',
          status: 'disabled',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('kanban'), findsOneWidget);
    expect(find.text('Kanban board plugin'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('bundled'), findsOneWidget);
    expect(find.text('spotify'), findsOneWidget);
    expect(find.text('Spotify integration'), findsOneWidget);
    expect(find.text('Version 0.5.0'), findsOneWidget);
    expect(find.text('user'), findsOneWidget);
    // Two switches: one on, one off.
    expect(find.byType(Switch), findsNWidgets(2));
  });

  testWidgets("'Open board' shows only for a present AND enabled kanban", (
    tester,
  ) async {
    // Enabled kanban → affordance.
    var repository = FakePluginRepository(
      details: const <PluginDetail>[
        PluginDetail(
          name: 'kanban',
          version: '1.0.0',
          description: 'Kanban board',
          source: 'bundled',
          status: 'enabled',
        ),
        PluginDetail(
          name: 'spotify',
          version: '0.5.0',
          description: 'Spotify',
          source: 'user',
          status: 'disabled',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(find.text('Open board'), findsOneWidget);

    // Disabled kanban → no affordance.
    repository = FakePluginRepository(
      details: const <PluginDetail>[
        PluginDetail(
          name: 'kanban',
          version: '1.0.0',
          description: 'Kanban board',
          source: 'bundled',
          status: 'disabled',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(find.text('Open board'), findsNothing);

    // No kanban at all → no affordance.
    repository = FakePluginRepository(
      details: const <PluginDetail>[
        PluginDetail(
          name: 'spotify',
          version: '0.5.0',
          description: 'Spotify',
          source: 'user',
          status: 'enabled',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(find.text('Open board'), findsNothing);
  });

  testWidgets('empty state when no plugins are reported', (tester) async {
    await tester.pumpWidget(_wrap(FakePluginRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No plugins reported by the gateway.'), findsOneWidget);
  });

  testWidgets('error state with retry', (tester) async {
    final repository = FakePluginRepository()
      ..error = const GatewayNetworkException('unreachable');
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Could not load plugins'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
