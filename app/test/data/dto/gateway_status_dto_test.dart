// Wire → domain translation for `GET /api/status`, with the gateway-0.20
// informational fields (docs/updates/gateway-0.18-to-0.20-optional.md §8).
//
// The whole point of these fields is that they are OPTIONAL: an older gateway
// omits every one, and for several of them "absent" carries a meaning of its
// own (no rebuild pending; recon withheld in gated mode). So the cases below
// pin absence as carefully as presence.

import 'package:flit/data/dto/gateway_status_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The always-present fields, as a pre-0.20 gateway would send them.
Map<String, dynamic> baseJson() => <String, dynamic>{
  'version': '0.20.0',
  'release_date': '2026.8.3',
  'gateway_running': true,
  'gateway_state': 'ready',
  'gateway_busy': false,
  'active_sessions': 2,
  'active_agents': 1,
  'auth_required': false,
  'auth_providers': <String>[],
};

void main() {
  group('GatewayStatusDto 0.20 status fields', () {
    test('parses the full loopback payload', () {
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 2,
        'latest_config_version': 3,
        'can_update_hermes': true,
        'gateway_drainable': true,
        'restart_drain_timeout': 300.0,
        'fts_rebuild': <String, dynamic>{
          'pending': true,
          'total': 5000,
          'indexed': 1250,
          'percent': 25,
        },
        'profiles': <String>['default', 'research'],
        'gateway_mode': 'multiplex',
        'gateways': <dynamic>[
          <String, dynamic>{
            'profile': 'default',
            'ports': <String, dynamic>{'webhook': 8788},
            'served_profiles': <String>['default', 'research'],
          },
        ],
      }).toDomain();

      expect(status.configVersion, 2);
      expect(status.latestConfigVersion, 3);
      expect(status.canUpdateHermes, isTrue);
      expect(status.gatewayDrainable, isTrue);
      expect(status.restartDrainTimeout, 300.0);
      expect(status.ftsRebuild!.total, 5000);
      expect(status.ftsRebuild!.indexed, 1250);
      expect(status.ftsRebuild!.percent, 25);
      expect(status.gatewayMode, 'multiplex');
      expect(status.gateways, hasLength(1));
      expect(status.gateways!.single.profile, 'default');
      expect(status.gateways!.single.ports, <String, int>{'webhook': 8788});
      expect(status.gateways!.single.servedProfiles, <String>[
        'default',
        'research',
      ]);
    });

    test('leaves every 0.20 field null on a pre-0.20 payload', () {
      final status = GatewayStatusDto.fromJson(baseJson()).toDomain();

      expect(status.configVersion, isNull);
      expect(status.latestConfigVersion, isNull);
      expect(status.canUpdateHermes, isNull);
      expect(status.gatewayDrainable, isNull);
      expect(status.restartDrainTimeout, isNull);
      expect(status.ftsRebuild, isNull);
      expect(status.gateways, isNull);
      // …and the always-present fields still parse.
      expect(status.version, '0.20.0');
      expect(status.activeSessions, 2);
    });

    test('restart_drain_timeout survives an int on the wire', () {
      // The gateway computes a float, but a config of `300` round-trips
      // through YAML/JSON as an int on some hosts.
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'restart_drain_timeout': 300,
      }).toDomain();

      expect(status.restartDrainTimeout, 300.0);
    });

    test('config_version 0 is a legacy config, not a missing field', () {
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 0,
        'latest_config_version': 3,
      }).toDomain();

      expect(status.configVersion, 0);
      expect(status.configMigrationNeeded, isTrue);
    });

    test('gateways omitted in gated mode stays null, not empty', () {
      // A gated gateway withholds `gateways` (it carries host ports) while
      // still sending `profiles` and `gateway_mode`.
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'auth_required': true,
        'auth_providers': <String>['nous'],
        'profiles': <String>['default'],
        'gateway_mode': 'single',
      }).toDomain();

      expect(status.gateways, isNull);
      expect(status.profiles, <String>['default']);
      expect(status.liveGatewayProfiles, isEmpty);
    });

    test('an empty gateways list means nothing is running', () {
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'gateway_mode': 'none',
        'gateways': <dynamic>[],
      }).toDomain();

      expect(status.gateways, isEmpty);
      expect(status.liveGatewayProfiles, isEmpty);
    });

    test('an fts_rebuild block with only pending still parses', () {
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'fts_rebuild': <String, dynamic>{'pending': true},
      }).toDomain();

      expect(status.ftsRebuildPending, isTrue);
      expect(status.ftsRebuild!.percent, 0);
      expect(status.ftsRebuild!.total, 0);
    });
  });

  group('GatewayStatus derived fields', () {
    test('configMigrationNeeded is false when a version is unknown', () {
      // A pre-0.20 gateway must never provoke a migration banner.
      final older = GatewayStatusDto.fromJson(baseJson()).toDomain();
      expect(older.configMigrationNeeded, isFalse);

      final halfKnown = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 2,
      }).toDomain();
      expect(halfKnown.configMigrationNeeded, isFalse);
    });

    test('configMigrationNeeded is false when up to date or ahead', () {
      final current = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 3,
        'latest_config_version': 3,
      }).toDomain();
      expect(current.configMigrationNeeded, isFalse);

      // A config from a NEWER Hermes than the running one: not a migration.
      final ahead = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 4,
        'latest_config_version': 3,
      }).toDomain();
      expect(ahead.configMigrationNeeded, isFalse);
    });

    test('liveGatewayProfiles folds in the multiplexed served profiles', () {
      // `research` has no gateway entry of its own — the default gateway
      // serves it, so it IS live.
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'profiles': <String>['default', 'research', 'archive'],
        'gateway_mode': 'multiplex',
        'gateways': <dynamic>[
          <String, dynamic>{
            'profile': 'default',
            'ports': <String, dynamic>{},
            'served_profiles': <String>['default', 'research'],
          },
        ],
      }).toDomain();

      expect(status.liveGatewayProfiles, <String>{'default', 'research'});
    });

    test('FtsRebuild.fraction clamps a nonsense percent', () {
      final status = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'fts_rebuild': <String, dynamic>{'pending': true, 'percent': 140},
      }).toDomain();

      expect(status.ftsRebuild!.fraction, 1.0);
    });

    test('value equality covers the new fields', () {
      final a = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 2,
        'latest_config_version': 3,
        'gateways': <dynamic>[
          <String, dynamic>{
            'profile': 'default',
            'ports': <String, dynamic>{'webhook': 8788},
          },
        ],
      }).toDomain();
      final same = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 2,
        'latest_config_version': 3,
        'gateways': <dynamic>[
          <String, dynamic>{
            'profile': 'default',
            'ports': <String, dynamic>{'webhook': 8788},
          },
        ],
      }).toDomain();
      final differentPort = GatewayStatusDto.fromJson(<String, dynamic>{
        ...baseJson(),
        'config_version': 2,
        'latest_config_version': 3,
        'gateways': <dynamic>[
          <String, dynamic>{
            'profile': 'default',
            'ports': <String, dynamic>{'webhook': 9999},
          },
        ],
      }).toDomain();

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(differentPort));
    });
  });
}
