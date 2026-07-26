// P8-04, P8-05 acceptance: BillingRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from the wire protocol, plus the
// DTO→domain mapping including envelope-based error handling (ok:false is a
// normal result, not thrown).

import 'package:flit/data/repositories/billing_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call and
/// answers from [handler].
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  /// Answers a request; defaults to an empty result map.
  final Map<String, dynamic> Function(
    String method,
    Map<String, dynamic> params,
  )?
  handler;

  /// Every (method, params) call, in order.
  final List<({String method, Map<String, dynamic> params})> calls =
      <({String method, Map<String, dynamic> params})>[];

  @override
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const <String, dynamic>{},
  ]) async {
    calls.add((method: method, params: params));
    final answer = handler;
    return answer == null ? const <String, dynamic>{} : answer(method, params);
  }
}

const stateResultOk = <String, dynamic>{
  'ok': true,
  'logged_in': true,
  'org_name': 'Test Org',
  'org_slug': 'test-org',
  'role': 'admin',
  'is_admin': true,
  'can_change_plan': true,
  'can_charge': true,
  'balance_usd': '52.50',
  'balance_display': r'$52.50',
  'cli_billing_enabled': true,
  'charge_presets': <String>['5', '10', '20'],
  'charge_presets_display': <String>[r'$5', r'$10', r'$20'],
  'min_usd': '5',
  'max_usd': '100',
  'card': <String, dynamic>{
    'brand': 'visa',
    'last4': '4242',
    'masked': '•••• 4242',
    'display': 'Visa •••• 4242',
    'resolved_via': 'stripe',
  },
  'monthly_cap': <String, dynamic>{
    'limit_usd': '100',
    'limit_display': r'$100',
    'spent_this_month_usd': '25.50',
    'spent_display': r'$25.50',
    'is_default_ceiling': false,
  },
  'auto_reload': <String, dynamic>{
    'enabled': true,
    'threshold_usd': '10',
    'threshold_display': r'$10',
    'reload_to_usd': '20',
    'reload_to_display': r'$20',
    'card': <String, dynamic>{
      'kind': 'canonical',
    },
  },
  'portal_url': 'https://portal.example.com',
  'error': null,
  'usage': <String, dynamic>{
    'has_topup': true,
  },
};

void main() {
  late FakeGatewayRpcClient client;
  late BillingRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = BillingRepositoryImpl(client);
  });

  group('state', () {
    test('sends billing.state with EMPTY params', () async {
      client = FakeGatewayRpcClient(handler: (_, _) => stateResultOk);
      repository = BillingRepositoryImpl(client);

      await repository.state();

      expect(client.calls.single.method, 'billing.state');
      expect(client.calls.single.params, isEmpty);
    });

    test('maps the ok result with all fields', () async {
      client = FakeGatewayRpcClient(handler: (_, _) => stateResultOk);
      repository = BillingRepositoryImpl(client);

      final result = await repository.state();

      expect(result.ok, isTrue);
      expect(result.loggedIn, isTrue);
      expect(result.orgName, 'Test Org');
      expect(result.orgSlug, 'test-org');
      expect(result.role, 'admin');
      expect(result.isAdmin, isTrue);
      expect(result.canChangePlan, isTrue);
      expect(result.canCharge, isTrue);
      expect(result.balanceUsd, '52.50');
      expect(result.balanceDisplay, r'$52.50');
      expect(result.cliBillingEnabled, isTrue);
      expect(result.chargePresets, <String>['5', '10', '20']);
      expect(result.chargePresetsDisplay, <String>[r'$5', r'$10', r'$20']);
      expect(result.minUsd, '5');
      expect(result.maxUsd, '100');
      expect(result.card, isNotNull);
      expect(result.card!.brand, 'visa');
      expect(result.card!.last4, '4242');
      expect(result.card!.display, 'Visa •••• 4242');
      expect(result.monthlyCap, isNotNull);
      expect(result.monthlyCap!.limitDisplay, r'$100');
      expect(result.monthlyCap!.spentDisplay, r'$25.50');
      expect(result.monthlyCap!.isDefaultCeiling, isFalse);
      expect(result.autoReload, isNotNull);
      expect(result.autoReload!.enabled, isTrue);
      expect(result.autoReload!.thresholdDisplay, r'$10');
      expect(result.autoReload!.reloadToDisplay, r'$20');
      expect(result.portalUrl, 'https://portal.example.com');
      expect(result.errorCode, isNull);
      expect(result.hasTopup, isTrue);
    });

    test('maps error field to errorCode', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': false,
          'logged_in': false,
          'is_admin': false,
          'can_change_plan': false,
          'can_charge': false,
          'balance_display': r'$0.00',
          'cli_billing_enabled': false,
          'charge_presets': <String>[],
          'charge_presets_display': <String>[],
          'error': 'insufficient_scope',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.state();

      expect(result.ok, isFalse);
      expect(result.errorCode, 'insufficient_scope');
    });
  });

  group('charge', () {
    test('sends billing.charge with amount_usd and optional idempotency_key',
        () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'charge_id': 'ch_123',
          'idempotency_key': 'idem_456',
        },
      );
      repository = BillingRepositoryImpl(client);

      await repository.charge(
        amountUsd: '10.00',
        idempotencyKey: 'idem_456',
      );

      expect(client.calls.single.method, 'billing.charge');
      expect(client.calls.single.params, <String, dynamic>{
        'amount_usd': '10.00',
        'idempotency_key': 'idem_456',
      });
    });

    test('maps ok result with charge_id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'charge_id': 'ch_123',
          'idempotency_key': 'idem_456',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.charge(
        amountUsd: '10.00',
        idempotencyKey: 'idem_456',
      );

      expect(result.ok, isTrue);
      expect(result.chargeId, 'ch_123');
      expect(result.idempotencyKey, 'idem_456');
      expect(result.errorCode, isNull);
    });

    test('maps ok:false with error code to result (NOT thrown)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': false,
          'error': 'insufficient_scope',
          'message': 'Need permission to charge',
          'idempotency_key': 'idem_456',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.charge(
        amountUsd: '10.00',
        idempotencyKey: 'idem_456',
      );

      expect(result.ok, isFalse);
      expect(result.errorCode, 'insufficient_scope');
      expect(result.message, 'Need permission to charge');
      expect(result.chargeId, isNull);
    });
  });

  group('chargeStatus', () {
    test('sends billing.charge_status with charge_id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'status': 'settled',
          'amount_usd': '10.00',
          'settled_at': '2024-01-01T00:00:00Z',
        },
      );
      repository = BillingRepositoryImpl(client);

      await repository.chargeStatus('ch_123');

      expect(client.calls.single.method, 'billing.charge_status');
      expect(client.calls.single.params, <String, dynamic>{
        'charge_id': 'ch_123',
      });
    });

    test('maps ok result with status', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'status': 'settled',
          'amount_usd': '10.00',
          'settled_at': '2024-01-01T00:00:00Z',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.chargeStatus('ch_123');

      expect(result.ok, isTrue);
      expect(result.status, 'settled');
      expect(result.amountUsd, '10.00');
      expect(result.settledAt, '2024-01-01T00:00:00Z');
      expect(result.reason, isNull);
      expect(result.errorCode, isNull);
    });

    test('maps failure reason', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'status': 'failed',
          'reason': 'card_declined',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.chargeStatus('ch_123');

      expect(result.ok, isTrue);
      expect(result.status, 'failed');
      expect(result.reason, 'card_declined');
    });
  });

  group('autoReload', () {
    test('sends billing.auto_reload with enabled, threshold, top_up_amount',
        () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'ok': true},
      );
      repository = BillingRepositoryImpl(client);

      await repository.autoReload(
        enabled: true,
        threshold: 10,
        topUpAmount: 20,
      );

      expect(client.calls.single.method, 'billing.auto_reload');
      expect(client.calls.single.params, <String, dynamic>{
        'enabled': true,
        'threshold': 10,
        'top_up_amount': 20,
      });
    });

    test('maps ok result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'ok': true},
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.autoReload(
        enabled: true,
        threshold: 10,
        topUpAmount: 20,
      );

      expect(result.ok, isTrue);
      expect(result.errorCode, isNull);
    });

    test('maps ok:false with error', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': false,
          'error': 'validation_failed',
          'message': 'Invalid threshold',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.autoReload(
        enabled: true,
        threshold: 10,
        topUpAmount: 20,
      );

      expect(result.ok, isFalse);
      expect(result.errorCode, 'validation_failed');
      expect(result.message, 'Invalid threshold');
    });
  });

  group('stepUp', () {
    test('sends billing.step_up with session_id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'granted': true,
        },
      );
      repository = BillingRepositoryImpl(client);

      await repository.stepUp(sessionId: 'sess_123');

      expect(client.calls.single.method, 'billing.step_up');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_123',
      });
    });

    test('maps ok result with granted', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': true,
          'granted': true,
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.stepUp(sessionId: 'sess_123');

      expect(result.ok, isTrue);
      expect(result.granted, isTrue);
      expect(result.errorCode, isNull);
    });

    test('maps ok:false with error', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'ok': false,
          'granted': false,
          'error': 'session_revoked',
          'message': 'Session was revoked',
        },
      );
      repository = BillingRepositoryImpl(client);

      final result = await repository.stepUp(sessionId: 'sess_123');

      expect(result.ok, isFalse);
      expect(result.granted, isFalse);
      expect(result.errorCode, 'session_revoked');
      expect(result.message, 'Session was revoked');
    });
  });
}
