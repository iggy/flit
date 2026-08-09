// The About screen's gateway-host section
// (docs/updates/gateway-0.18-to-0.20-optional.md §8): the 0.20 status fields
// render as readouts, and a pre-0.20 gateway shows none of them.

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/desktop_contract.dart';
import 'package:flit/domain/models/desktop_contract.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/presentation/settings/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _olderGateway = GatewayStatus(
  version: '0.18.0',
  releaseDate: '2026-07-01',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 0,
  authRequired: false,
  authProviders: <String>[],
);

/// A 0.20 loopback gateway: migration pending, drainable, rebuilding its
/// search index, multiplexing two profiles.
const _currentGateway = GatewayStatus(
  version: '0.20.0',
  releaseDate: '2026.8.3',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 0,
  authRequired: false,
  authProviders: <String>[],
  authFlows: <String>[],
  profiles: <String>['default', 'research'],
  gatewayMode: 'multiplex',
  gateways: <GatewayTopologyEntry>[
    GatewayTopologyEntry(
      profile: 'default',
      servedProfiles: <String>['default', 'research'],
    ),
  ],
  configVersion: 2,
  latestConfigVersion: 3,
  canUpdateHermes: true,
  gatewayDrainable: true,
  restartDrainTimeout: 300,
  ftsRebuild: FtsRebuild(total: 5000, indexed: 1250, percent: 25),
);

/// Seeds [desktopContractProvider] with a version the gateway "reported".
final class _SeededContractNotifier extends DesktopContractNotifier {
  _SeededContractNotifier(this._version);

  final int? _version;

  @override
  DesktopContract build() => DesktopContract(version: _version);
}

/// Seeds [gatewayStatusProvider] and counts refresh calls.
final class _SeededStatusNotifier extends GatewayStatusNotifier {
  _SeededStatusNotifier(this._status, {this.refreshResult = true});

  final GatewayStatus? _status;
  final bool refreshResult;
  int refreshCalls = 0;

  @override
  GatewayStatus? build() => _status;

  @override
  Future<bool> refresh() async {
    refreshCalls++;
    return refreshResult;
  }
}

void main() {
  Widget wrap(_SeededStatusNotifier notifier, {int? contract}) {
    return ProviderScope(
      // Deterministic: no backoff retries left pending on a failing provider.
      retry: (retryCount, error) => null,
      overrides: [
        gatewayStatusProvider.overrideWith(() => notifier),
        desktopContractProvider.overrideWith(
          () => _SeededContractNotifier(contract),
        ),
      ],
      child: const MaterialApp(home: AboutScreen()),
    );
  }

  /// Pump on a tall surface: the screen is a lazy [ListView] longer than the
  /// default 800px test window, so the gateway section would never be built
  /// (and `findsNothing` would pass for the wrong reason).
  Future<void> pumpAbout(
    WidgetTester tester,
    _SeededStatusNotifier notifier, {
    int? contract,
  }) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(notifier, contract: contract));
    await tester.pump();
  }

  testWidgets('renders the gateway-host readouts for a 0.20 gateway', (
    tester,
  ) async {
    await pumpAbout(tester, _SeededStatusNotifier(_currentGateway));

    expect(find.text('Gateway host'), findsOneWidget);

    // Config schema behind the gateway's own → name the host-side command.
    expect(find.textContaining('this gateway ships 3'), findsOneWidget);
    expect(find.textContaining('hermes config migrate'), findsOneWidget);

    expect(find.textContaining('can run `hermes update`'), findsOneWidget);

    // Drain: state and the resolved timeout, in minutes.
    expect(find.textContaining('Ready to drain'), findsOneWidget);
    expect(find.textContaining('5 minutes'), findsOneWidget);

    // Rebuild: percent, counts, and the "search is degraded" warning.
    expect(find.textContaining('Rebuilding — 25%'), findsOneWidget);
    expect(find.textContaining('1250 of 5000 messages'), findsOneWidget);
    expect(find.textContaining('slower and incomplete'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.25,
    );

    // Topology: mode in words, and the multiplexed profile marked live too.
    expect(find.text('One gateway serving several profiles'), findsOneWidget);
    expect(find.text('default (live), research (live)'), findsOneWidget);
  });

  testWidgets('shows no gateway-host section for a pre-0.20 gateway', (
    tester,
  ) async {
    await pumpAbout(tester, _SeededStatusNotifier(_olderGateway));

    // Every field of the section is absent, so the header goes with them.
    expect(find.text('Gateway host'), findsNothing);
    expect(find.text('Config Schema'), findsNothing);
    expect(find.text('Restart Drain'), findsNothing);
    expect(find.text('Search Index'), findsNothing);
    // The pre-existing rows still render.
    expect(find.text('Gateway Version'), findsOneWidget);
    expect(find.text('0.18.0'), findsOneWidget);
  });

  testWidgets('omits the search-index row when no rebuild is pending', (
    tester,
  ) async {
    // A 0.20 gateway with a healthy index sends no `fts_rebuild` at all.
    const healthy = GatewayStatus(
      version: '0.20.0',
      gatewayRunning: true,
      gatewayState: 'ready',
      gatewayBusy: false,
      activeSessions: 0,
      activeAgents: 0,
      authRequired: false,
      authProviders: <String>[],
      configVersion: 3,
      latestConfigVersion: 3,
      gatewayDrainable: true,
    );

    await pumpAbout(tester, _SeededStatusNotifier(healthy));

    expect(find.text('Gateway host'), findsOneWidget);
    expect(find.text('Search Index'), findsNothing);
    // Up-to-date config states the version without nagging about a migration.
    expect(find.text('Version 3 (current)'), findsOneWidget);
    expect(find.textContaining('hermes config migrate'), findsNothing);
    // can_update_hermes was not sent, so that row is absent as well.
    expect(find.text('Host Updates'), findsNothing);
  });

  testWidgets('the refresh action re-probes the status', (tester) async {
    final notifier = _SeededStatusNotifier(_currentGateway);
    await pumpAbout(tester, notifier);

    await tester.tap(find.byKey(aboutRefreshStatusKey));
    await tester.pumpAndSettle();

    expect(notifier.refreshCalls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed refresh reports it and keeps the readout', (
    tester,
  ) async {
    final notifier = _SeededStatusNotifier(
      _currentGateway,
      refreshResult: false,
    );
    await pumpAbout(tester, notifier);

    await tester.tap(find.byKey(aboutRefreshStatusKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not reach the gateway'), findsOneWidget);
    // A failed refresh must never blank a readout that was fine.
    expect(find.textContaining('Rebuilding — 25%'), findsOneWidget);
  });

  testWidgets('the refresh action is disabled while disconnected', (
    tester,
  ) async {
    await pumpAbout(tester, _SeededStatusNotifier(null));

    final button = tester.widget<IconButton>(find.byKey(aboutRefreshStatusKey));
    expect(button.onPressed, isNull);
    expect(find.text('Not connected'), findsOneWidget);
  });

  group('desktop contract (optional-doc §3)', () {
    testWidgets('states the version when the gateway is current', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        _SeededStatusNotifier(_currentGateway),
        contract: DesktopContract.minimum,
      );

      expect(find.byKey(aboutDesktopContractKey), findsOneWidget);
      expect(find.text('v${DesktopContract.minimum}'), findsOneWidget);
      expect(find.textContaining('Update your Hermes gateway'), findsNothing);
    });

    testWidgets('tells the user to update when the gateway is behind', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        _SeededStatusNotifier(_olderGateway),
        contract: DesktopContract.minimum - 1,
      );

      expect(find.textContaining('Update your Hermes gateway'), findsOneWidget);
      expect(
        find.textContaining('flit expects v${DesktopContract.minimum}'),
        findsOneWidget,
      );
      expect(
        find.textContaining('large attachments will fail'),
        findsOneWidget,
      );
    });

    testWidgets('renders nothing before a session has reported one', (
      tester,
    ) async {
      // Unknown is "not told", not "old" — no row, and above all no warning.
      await pumpAbout(tester, _SeededStatusNotifier(_currentGateway));

      expect(find.byKey(aboutDesktopContractKey), findsNothing);
      expect(find.text('Client Contract'), findsNothing);
      expect(find.textContaining('Update your Hermes gateway'), findsNothing);
    });
  });
}
