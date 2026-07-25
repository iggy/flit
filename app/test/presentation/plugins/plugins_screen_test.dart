// P1-14 acceptance: the plugins screen renders real plugins and shows the
// kanban "Open board" affordance ONLY when kanban is present AND enabled.

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
  testWidgets('renders plugins with version and enabled state', (tester) async {
    final repository = FakePluginRepository(
      plugins: const <PluginInfo>[
        PluginInfo(name: 'kanban', version: '1.0.0', enabled: true),
        PluginInfo(name: 'spotify', version: '?', enabled: false),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('kanban'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('spotify'), findsOneWidget);
    expect(find.text('Version ?'), findsOneWidget);
    expect(find.byIcon(Icons.toggle_on), findsOneWidget);
    expect(find.byIcon(Icons.toggle_off_outlined), findsOneWidget);
  });

  testWidgets("'Open board' shows only for a present AND enabled kanban", (
    tester,
  ) async {
    // Enabled kanban → affordance.
    var repository = FakePluginRepository(
      plugins: const <PluginInfo>[
        PluginInfo(name: 'kanban', version: '1.0.0', enabled: true),
        PluginInfo(name: 'spotify', version: '?', enabled: false),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(find.text('Open board'), findsOneWidget);

    // Disabled kanban → no affordance.
    repository = FakePluginRepository(
      plugins: const <PluginInfo>[
        PluginInfo(name: 'kanban', version: '1.0.0', enabled: false),
      ],
    );
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(find.text('Open board'), findsNothing);

    // No kanban at all → no affordance.
    repository = FakePluginRepository(
      plugins: const <PluginInfo>[
        PluginInfo(name: 'spotify', version: '?', enabled: true),
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
