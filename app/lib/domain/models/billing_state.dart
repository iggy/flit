/// Domain models for billing & credits (tickets P8-04, P8-05).
///
/// Wire shapes from `billing.*` RPCs — never invent protocol.
library;

/// Result of `billing.state` RPC.
final class BillingState {
  const BillingState({
    required this.ok,
    required this.loggedIn,
    this.orgName,
    this.orgSlug,
    this.role,
    required this.isAdmin,
    required this.canChangePlan,
    required this.canCharge,
    this.balanceUsd,
    required this.balanceDisplay,
    required this.cliBillingEnabled,
    required this.chargePresets,
    required this.chargePresetsDisplay,
    this.minUsd,
    this.maxUsd,
    this.card,
    this.monthlyCap,
    this.autoReload,
    this.portalUrl,
    this.errorCode,
    this.hasTopup,
  });

  final bool ok;
  final bool loggedIn;
  final String? orgName;
  final String? orgSlug;
  final String? role;
  final bool isAdmin;
  final bool canChangePlan;
  final bool canCharge;

  /// Decimal as string, e.g. "52.50".
  final String? balanceUsd;

  /// Pre-formatted, e.g. "$52.50".
  final String balanceDisplay;

  final bool cliBillingEnabled;

  /// Preset amounts, e.g. ["5","10","20"].
  final List<String> chargePresets;

  /// Preset display labels, e.g. ["\$5","\$10","\$20"].
  final List<String> chargePresetsDisplay;

  final String? minUsd;
  final String? maxUsd;
  final BillingCard? card;
  final BillingMonthlyCap? monthlyCap;
  final BillingAutoReload? autoReload;
  final String? portalUrl;
  final String? errorCode;

  /// From usage sub-object (optional).
  final bool? hasTopup;

  @override
  bool operator ==(Object other) {
    return other is BillingState &&
        other.ok == ok &&
        other.loggedIn == loggedIn &&
        other.orgName == orgName &&
        other.orgSlug == orgSlug &&
        other.role == role &&
        other.isAdmin == isAdmin &&
        other.canChangePlan == canChangePlan &&
        other.canCharge == canCharge &&
        other.balanceUsd == balanceUsd &&
        other.balanceDisplay == balanceDisplay &&
        other.cliBillingEnabled == cliBillingEnabled &&
        _listEquals(other.chargePresets, chargePresets) &&
        _listEquals(other.chargePresetsDisplay, chargePresetsDisplay) &&
        other.minUsd == minUsd &&
        other.maxUsd == maxUsd &&
        other.card == card &&
        other.monthlyCap == monthlyCap &&
        other.autoReload == autoReload &&
        other.portalUrl == portalUrl &&
        other.errorCode == errorCode &&
        other.hasTopup == hasTopup;
  }

  @override
  int get hashCode => Object.hash(
        ok,
        loggedIn,
        orgName,
        orgSlug,
        role,
        isAdmin,
        canChangePlan,
        canCharge,
        balanceUsd,
        balanceDisplay,
        cliBillingEnabled,
        Object.hashAll(chargePresets),
        Object.hashAll(chargePresetsDisplay),
        minUsd,
        maxUsd,
        card,
        monthlyCap,
        autoReload,
        portalUrl,
        errorCode,
      );

  @override
  String toString() => 'BillingState('
      'ok: $ok, '
      'loggedIn: $loggedIn, '
      'balanceDisplay: $balanceDisplay, '
      'canCharge: $canCharge, '
      'errorCode: $errorCode)';

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Payment card info from billing state.
final class BillingCard {
  const BillingCard({
    required this.brand,
    required this.last4,
    required this.masked,
    this.display,
    this.resolvedVia,
  });

  final String brand;
  final String last4;
  final String masked;
  final String? display;
  final String? resolvedVia;

  @override
  bool operator ==(Object other) {
    return other is BillingCard &&
        other.brand == brand &&
        other.last4 == last4 &&
        other.masked == masked &&
        other.display == display &&
        other.resolvedVia == resolvedVia;
  }

  @override
  int get hashCode => Object.hash(brand, last4, masked, display, resolvedVia);

  @override
  String toString() =>
      'BillingCard(brand: $brand, last4: $last4, display: $display)';
}

/// Monthly spending cap from billing state.
final class BillingMonthlyCap {
  const BillingMonthlyCap({
    this.limitUsd,
    required this.limitDisplay,
    this.spentThisMonthUsd,
    required this.spentDisplay,
    required this.isDefaultCeiling,
  });

  final String? limitUsd;
  final String limitDisplay;
  final String? spentThisMonthUsd;
  final String spentDisplay;
  final bool isDefaultCeiling;

  @override
  bool operator ==(Object other) {
    return other is BillingMonthlyCap &&
        other.limitUsd == limitUsd &&
        other.limitDisplay == limitDisplay &&
        other.spentThisMonthUsd == spentThisMonthUsd &&
        other.spentDisplay == spentDisplay &&
        other.isDefaultCeiling == isDefaultCeiling;
  }

  @override
  int get hashCode => Object.hash(
        limitUsd,
        limitDisplay,
        spentThisMonthUsd,
        spentDisplay,
        isDefaultCeiling,
      );

  @override
  String toString() => 'BillingMonthlyCap('
      'limitDisplay: $limitDisplay, '
      'spentDisplay: $spentDisplay, '
      'isDefaultCeiling: $isDefaultCeiling)';
}

/// Auto-reload config from billing state.
final class BillingAutoReload {
  const BillingAutoReload({
    required this.enabled,
    this.thresholdUsd,
    required this.thresholdDisplay,
    this.reloadToUsd,
    required this.reloadToDisplay,
    this.card,
  });

  final bool enabled;
  final String? thresholdUsd;
  final String thresholdDisplay;
  final String? reloadToUsd;
  final String reloadToDisplay;
  final BillingAutoReloadCard? card;

  @override
  bool operator ==(Object other) {
    return other is BillingAutoReload &&
        other.enabled == enabled &&
        other.thresholdUsd == thresholdUsd &&
        other.thresholdDisplay == thresholdDisplay &&
        other.reloadToUsd == reloadToUsd &&
        other.reloadToDisplay == reloadToDisplay &&
        other.card == card;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        thresholdUsd,
        thresholdDisplay,
        reloadToUsd,
        reloadToDisplay,
        card,
      );

  @override
  String toString() => 'BillingAutoReload('
      'enabled: $enabled, '
      'thresholdDisplay: $thresholdDisplay, '
      'reloadToDisplay: $reloadToDisplay)';
}

/// Auto-reload card union: canonical / none / distinct.
final class BillingAutoReloadCard {
  const BillingAutoReloadCard({
    required this.kind,
    this.paymentMethodId,
    this.brand,
    this.last4,
  });

  final String kind;
  final String? paymentMethodId;
  final String? brand;
  final String? last4;

  @override
  bool operator ==(Object other) {
    return other is BillingAutoReloadCard &&
        other.kind == kind &&
        other.paymentMethodId == paymentMethodId &&
        other.brand == brand &&
        other.last4 == last4;
  }

  @override
  int get hashCode =>
      Object.hash(kind, paymentMethodId, brand, last4);

  @override
  String toString() => 'BillingAutoReloadCard(kind: $kind)';
}

/// Result of `billing.charge` RPC.
final class BillingChargeResult {
  const BillingChargeResult({
    required this.ok,
    this.chargeId,
    required this.idempotencyKey,
    this.errorCode,
    this.message,
    this.portalUrl,
    this.retryAfter,
  });

  final bool ok;
  final String? chargeId;
  final String idempotencyKey;
  final String? errorCode;
  final String? message;
  final String? portalUrl;
  final int? retryAfter;

  @override
  bool operator ==(Object other) {
    return other is BillingChargeResult &&
        other.ok == ok &&
        other.chargeId == chargeId &&
        other.idempotencyKey == idempotencyKey &&
        other.errorCode == errorCode &&
        other.message == message &&
        other.portalUrl == portalUrl &&
        other.retryAfter == retryAfter;
  }

  @override
  int get hashCode => Object.hash(
        ok,
        chargeId,
        idempotencyKey,
        errorCode,
        message,
        portalUrl,
        retryAfter,
      );

  @override
  String toString() => 'BillingChargeResult('
      'ok: $ok, '
      'chargeId: $chargeId, '
      'errorCode: $errorCode)';
}

/// Result of `billing.charge_status` RPC.
final class BillingChargeStatus {
  const BillingChargeStatus({
    required this.ok,
    this.status,
    this.amountUsd,
    this.settledAt,
    this.reason,
    this.errorCode,
    this.message,
  });

  final bool ok;
  final String? status;
  final String? amountUsd;
  final String? settledAt;
  final String? reason;
  final String? errorCode;
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is BillingChargeStatus &&
        other.ok == ok &&
        other.status == status &&
        other.amountUsd == amountUsd &&
        other.settledAt == settledAt &&
        other.reason == reason &&
        other.errorCode == errorCode &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        ok,
        status,
        amountUsd,
        settledAt,
        reason,
        errorCode,
        message,
      );

  @override
  String toString() => 'BillingChargeStatus('
      'ok: $ok, '
      'status: $status, '
      'reason: $reason)';
}

/// Result of `billing.auto_reload` and `billing.step_up` RPCs.
final class BillingMutationResult {
  const BillingMutationResult({
    required this.ok,
    this.granted,
    this.errorCode,
    this.message,
  });

  final bool ok;
  final bool? granted;
  final String? errorCode;
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is BillingMutationResult &&
        other.ok == ok &&
        other.granted == granted &&
        other.errorCode == errorCode &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(ok, granted, errorCode, message);

  @override
  String toString() =>
      'BillingMutationResult(ok: $ok, granted: $granted, errorCode: $errorCode)';
}
