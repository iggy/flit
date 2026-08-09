// docs/updates/gateway-0.18-to-0.20-optional.md §3: the desktop-contract
// notifier learns `info.desktop_contract` from the session bootstrap and keeps
// it current from `session.info` events.

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/desktop_contract.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/desktop_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late StreamController<GatewayEvent> eventsController;

  setUp(() {
    eventsController = StreamController<GatewayEvent>.broadcast();
    container = ProviderContainer(
      // Deterministic tests: Riverpod 3 retries failing providers by default.
      retry: (retryCount, error) => null,
      overrides: [
        gatewayEventsProvider.overrideWith((ref) => eventsController.stream),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await eventsController.close();
  });

  /// Riverpod 3 pauses `ref.listen` while nothing listens to the provider.
  void keepAlive() {
    final sub = container.listen(desktopContractProvider, (_, _) {});
    addTearDown(sub.close);
  }

  Future<void> emitInfo(Map<String, dynamic> payload) async {
    eventsController.add(
      GatewayEvent(
        type: 'session.info',
        sessionId: 'a1b2c3d4',
        payload: payload,
      ),
    );
    await Future<void>.delayed(Duration.zero);
  }

  test('starts unknown — nothing has reported a contract yet', () {
    expect(container.read(desktopContractProvider).isKnown, isFalse);
  });

  test('recordInfo reads the version out of a bootstrap info dict', () {
    container.read(desktopContractProvider.notifier).recordInfo(
      <String, dynamic>{'model': 'hermes-4-405b', 'desktop_contract': 5},
    );

    expect(
      container.read(desktopContractProvider),
      const DesktopContract(version: 5),
    );
  });

  test('recordInfo tolerates a null or key-less info dict', () {
    final notifier = container.read(desktopContractProvider.notifier);

    notifier.recordInfo(null);
    notifier.recordInfo(<String, dynamic>{'lazy': true});

    expect(container.read(desktopContractProvider).isKnown, isFalse);
  });

  test('a key-less info dict does NOT forget a known version', () {
    final notifier = container.read(desktopContractProvider.notifier);
    notifier.set(5);

    // A lazy resume answers with a minimal info dict — dropping the version
    // here would flip the warning state mid-connection.
    notifier.recordInfo(<String, dynamic>{'lazy': true});

    expect(container.read(desktopContractProvider).version, 5);
  });

  test('a non-int desktop_contract is ignored', () {
    container.read(desktopContractProvider.notifier).recordInfo(
      <String, dynamic>{'desktop_contract': '5'},
    );

    expect(container.read(desktopContractProvider).isKnown, isFalse);
  });

  test('session.info events set the version', () async {
    keepAlive();

    await emitInfo(<String, dynamic>{'desktop_contract': 4});

    expect(container.read(desktopContractProvider).version, 4);
    expect(container.read(desktopContractProvider).isBehind, isTrue);
  });

  test('a later session.info replaces an earlier version', () async {
    keepAlive();

    await emitInfo(<String, dynamic>{'desktop_contract': 4});
    await emitInfo(<String, dynamic>{'desktop_contract': 5});

    expect(container.read(desktopContractProvider).version, 5);
    expect(container.read(desktopContractProvider).isBehind, isFalse);
  });

  test('other events leave the state alone', () async {
    keepAlive();

    eventsController.add(
      const GatewayEvent(
        type: 'message.delta',
        sessionId: 'a1b2c3d4',
        payload: <String, dynamic>{'text': 'hi'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(desktopContractProvider).isKnown, isFalse);
  });

  test('clear forgets the version (the next gateway may differ)', () {
    final notifier = container.read(desktopContractProvider.notifier);
    notifier.set(5);

    notifier.clear();

    expect(container.read(desktopContractProvider).isKnown, isFalse);
  });
}
