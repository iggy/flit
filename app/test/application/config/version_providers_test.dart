import 'package:flit/application/config/version_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/domain/models/app_version.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/domain/models/update_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('updateCheckProvider', () {
    test('returns gatewayNewer when gateway version is higher', () async {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWith(
            (ref) => Future.value(
              const AppVersion(version: '1.0.0', buildNumber: '1'),
            ),
          ),
          gatewayStatusProvider.overrideWith(
            () => _TestGatewayStatusNotifier(
              const GatewayStatus(
                version: '1.2.0',
                gatewayRunning: true,
                gatewayState: 'ready',
                gatewayBusy: false,
                activeSessions: 0,
                activeAgents: 0,
                authRequired: false,
                authProviders: [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(updateCheckProvider.future);

      expect(result.localVersion, equals('1.0.0'));
      expect(result.gatewayVersion, equals('1.2.0'));
      expect(result.status, equals(UpdateCheckStatus.gatewayNewer));
    });

    test('returns upToDate when versions match', () async {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWith(
            (ref) => Future.value(
              const AppVersion(version: '1.5.3', buildNumber: '42'),
            ),
          ),
          gatewayStatusProvider.overrideWith(
            () => _TestGatewayStatusNotifier(
              const GatewayStatus(
                version: '1.5.3',
                gatewayRunning: true,
                gatewayState: 'ready',
                gatewayBusy: false,
                activeSessions: 1,
                activeAgents: 2,
                authRequired: false,
                authProviders: [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(updateCheckProvider.future);

      expect(result.localVersion, equals('1.5.3'));
      expect(result.gatewayVersion, equals('1.5.3'));
      expect(result.status, equals(UpdateCheckStatus.upToDate));
    });

    test('returns clientNewer when local version is higher', () async {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWith(
            (ref) => Future.value(
              const AppVersion(version: '2.0.0', buildNumber: '100'),
            ),
          ),
          gatewayStatusProvider.overrideWith(
            () => _TestGatewayStatusNotifier(
              const GatewayStatus(
                version: '1.9.5',
                gatewayRunning: true,
                gatewayState: 'ready',
                gatewayBusy: false,
                activeSessions: 0,
                activeAgents: 0,
                authRequired: false,
                authProviders: [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(updateCheckProvider.future);

      expect(result.localVersion, equals('2.0.0'));
      expect(result.gatewayVersion, equals('1.9.5'));
      expect(result.status, equals(UpdateCheckStatus.clientNewer));
    });

    test('returns unknown when gateway status is null', () async {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWith(
            (ref) => Future.value(
              const AppVersion(version: '1.0.0', buildNumber: '1'),
            ),
          ),
          gatewayStatusProvider.overrideWith(
            () => _TestGatewayStatusNotifier(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(updateCheckProvider.future);

      expect(result.localVersion, equals('1.0.0'));
      expect(result.gatewayVersion, isEmpty);
      expect(result.status, equals(UpdateCheckStatus.unknown));
    });

    test('returns unknown when app version is unknown', () async {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWith(
            (ref) => Future.value(
              const AppVersion(version: 'unknown', buildNumber: 'unknown'),
            ),
          ),
          gatewayStatusProvider.overrideWith(
            () => _TestGatewayStatusNotifier(
              const GatewayStatus(
                version: '1.0.0',
                gatewayRunning: true,
                gatewayState: 'ready',
                gatewayBusy: false,
                activeSessions: 0,
                activeAgents: 0,
                authRequired: false,
                authProviders: [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(updateCheckProvider.future);

      expect(result.localVersion, equals('unknown'));
      expect(result.gatewayVersion, equals('1.0.0'));
      expect(result.status, equals(UpdateCheckStatus.unknown));
    });

    test('compares versions numerically', () async {
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWith(
            (ref) => Future.value(
              const AppVersion(version: '1.9.0', buildNumber: '50'),
            ),
          ),
          gatewayStatusProvider.overrideWith(
            () => _TestGatewayStatusNotifier(
              const GatewayStatus(
                version: '1.10.0',
                gatewayRunning: true,
                gatewayState: 'ready',
                gatewayBusy: false,
                activeSessions: 0,
                activeAgents: 0,
                authRequired: false,
                authProviders: [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(updateCheckProvider.future);

      expect(result.localVersion, equals('1.9.0'));
      expect(result.gatewayVersion, equals('1.10.0'));
      expect(result.status, equals(UpdateCheckStatus.gatewayNewer));
    });
  });
}

/// Test notifier that provides a fixed [GatewayStatus] or null.
class _TestGatewayStatusNotifier extends GatewayStatusNotifier {
  _TestGatewayStatusNotifier(this._status);

  final GatewayStatus? _status;

  @override
  GatewayStatus? build() => _status;
}
