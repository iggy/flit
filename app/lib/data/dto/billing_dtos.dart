import 'package:flit/domain/models/billing_state.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_dtos.g.dart';

/// Wire DTO for `billing.state` result (tickets P8-04, P8-05).
@JsonSerializable()
class BillingStateDto {
  const BillingStateDto({
    this.ok,
    this.loggedIn,
    this.orgName,
    this.orgSlug,
    this.role,
    this.isAdmin,
    this.canChangePlan,
    this.canCharge,
    this.balanceUsd,
    this.balanceDisplay,
    this.cliBillingEnabled,
    this.chargePresets,
    this.chargePresetsDisplay,
    this.minUsd,
    this.maxUsd,
    this.card,
    this.monthlyCap,
    this.autoReload,
    this.portalUrl,
    this.error,
    this.usage,
  });

  factory BillingStateDto.fromJson(Map<String, dynamic> json) =>
      _$BillingStateDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'logged_in')
  final bool? loggedIn;

  @JsonKey(name: 'org_name')
  final String? orgName;

  @JsonKey(name: 'org_slug')
  final String? orgSlug;

  @JsonKey(name: 'role')
  final String? role;

  @JsonKey(name: 'is_admin')
  final bool? isAdmin;

  @JsonKey(name: 'can_change_plan')
  final bool? canChangePlan;

  @JsonKey(name: 'can_charge')
  final bool? canCharge;

  @JsonKey(name: 'balance_usd')
  final String? balanceUsd;

  @JsonKey(name: 'balance_display')
  final String? balanceDisplay;

  @JsonKey(name: 'cli_billing_enabled')
  final bool? cliBillingEnabled;

  @JsonKey(name: 'charge_presets')
  final List<String>? chargePresets;

  @JsonKey(name: 'charge_presets_display')
  final List<String>? chargePresetsDisplay;

  @JsonKey(name: 'min_usd')
  final String? minUsd;

  @JsonKey(name: 'max_usd')
  final String? maxUsd;

  @JsonKey(name: 'card')
  final BillingCardDto? card;

  @JsonKey(name: 'monthly_cap')
  final BillingMonthlyCapDto? monthlyCap;

  @JsonKey(name: 'auto_reload')
  final BillingAutoReloadDto? autoReload;

  @JsonKey(name: 'portal_url')
  final String? portalUrl;

  @JsonKey(name: 'error')
  final String? error;

  @JsonKey(name: 'usage')
  final Map<String, dynamic>? usage;

  Map<String, dynamic> toJson() => _$BillingStateDtoToJson(this);

  BillingState toDomain() {
    return BillingState(
      ok: ok ?? false,
      loggedIn: loggedIn ?? false,
      orgName: orgName,
      orgSlug: orgSlug,
      role: role,
      isAdmin: isAdmin ?? false,
      canChangePlan: canChangePlan ?? false,
      canCharge: canCharge ?? false,
      balanceUsd: balanceUsd,
      balanceDisplay: balanceDisplay ?? '\$0.00',
      cliBillingEnabled: cliBillingEnabled ?? false,
      chargePresets: chargePresets ?? const <String>[],
      chargePresetsDisplay: chargePresetsDisplay ?? const <String>[],
      minUsd: minUsd,
      maxUsd: maxUsd,
      card: card?.toDomain(),
      monthlyCap: monthlyCap?.toDomain(),
      autoReload: autoReload?.toDomain(),
      portalUrl: portalUrl,
      errorCode: error,
      hasTopup: usage?['has_topup'] as bool?,
    );
  }
}

/// Wire DTO for billing card.
@JsonSerializable()
class BillingCardDto {
  const BillingCardDto({
    this.brand,
    this.last4,
    this.masked,
    this.display,
    this.resolvedVia,
  });

  factory BillingCardDto.fromJson(Map<String, dynamic> json) =>
      _$BillingCardDtoFromJson(json);

  @JsonKey(name: 'brand')
  final String? brand;

  @JsonKey(name: 'last4')
  final String? last4;

  @JsonKey(name: 'masked')
  final String? masked;

  @JsonKey(name: 'display')
  final String? display;

  @JsonKey(name: 'resolved_via')
  final String? resolvedVia;

  Map<String, dynamic> toJson() => _$BillingCardDtoToJson(this);

  BillingCard toDomain() {
    return BillingCard(
      brand: brand ?? '',
      last4: last4 ?? '',
      masked: masked ?? '',
      display: display,
      resolvedVia: resolvedVia,
    );
  }
}

/// Wire DTO for monthly cap.
@JsonSerializable()
class BillingMonthlyCapDto {
  const BillingMonthlyCapDto({
    this.limitUsd,
    this.limitDisplay,
    this.spentThisMonthUsd,
    this.spentDisplay,
    this.isDefaultCeiling,
  });

  factory BillingMonthlyCapDto.fromJson(Map<String, dynamic> json) =>
      _$BillingMonthlyCapDtoFromJson(json);

  @JsonKey(name: 'limit_usd')
  final String? limitUsd;

  @JsonKey(name: 'limit_display')
  final String? limitDisplay;

  @JsonKey(name: 'spent_this_month_usd')
  final String? spentThisMonthUsd;

  @JsonKey(name: 'spent_display')
  final String? spentDisplay;

  @JsonKey(name: 'is_default_ceiling')
  final bool? isDefaultCeiling;

  Map<String, dynamic> toJson() => _$BillingMonthlyCapDtoToJson(this);

  BillingMonthlyCap toDomain() {
    return BillingMonthlyCap(
      limitUsd: limitUsd,
      limitDisplay: limitDisplay ?? '',
      spentThisMonthUsd: spentThisMonthUsd,
      spentDisplay: spentDisplay ?? '',
      isDefaultCeiling: isDefaultCeiling ?? false,
    );
  }
}

/// Wire DTO for auto-reload config.
@JsonSerializable()
class BillingAutoReloadDto {
  const BillingAutoReloadDto({
    this.enabled,
    this.thresholdUsd,
    this.thresholdDisplay,
    this.reloadToUsd,
    this.reloadToDisplay,
    this.card,
  });

  factory BillingAutoReloadDto.fromJson(Map<String, dynamic> json) =>
      _$BillingAutoReloadDtoFromJson(json);

  @JsonKey(name: 'enabled')
  final bool? enabled;

  @JsonKey(name: 'threshold_usd')
  final String? thresholdUsd;

  @JsonKey(name: 'threshold_display')
  final String? thresholdDisplay;

  @JsonKey(name: 'reload_to_usd')
  final String? reloadToUsd;

  @JsonKey(name: 'reload_to_display')
  final String? reloadToDisplay;

  @JsonKey(name: 'card')
  final Map<String, dynamic>? card;

  Map<String, dynamic> toJson() => _$BillingAutoReloadDtoToJson(this);

  BillingAutoReload toDomain() {
    BillingAutoReloadCard? cardModel;
    if (card != null) {
      final kind = card!['kind'] as String?;
      if (kind != null) {
        cardModel = BillingAutoReloadCard(
          kind: kind,
          paymentMethodId: card!['payment_method_id'] as String?,
          brand: card!['brand'] as String?,
          last4: card!['last4'] as String?,
        );
      }
    }
    return BillingAutoReload(
      enabled: enabled ?? false,
      thresholdUsd: thresholdUsd,
      thresholdDisplay: thresholdDisplay ?? '',
      reloadToUsd: reloadToUsd,
      reloadToDisplay: reloadToDisplay ?? '',
      card: cardModel,
    );
  }
}

/// Wire DTO for `billing.charge` result.
@JsonSerializable()
class BillingChargeResultDto {
  const BillingChargeResultDto({
    this.ok,
    this.chargeId,
    this.idempotencyKey,
    this.error,
    this.message,
    this.portalUrl,
    this.retryAfter,
  });

  factory BillingChargeResultDto.fromJson(Map<String, dynamic> json) =>
      _$BillingChargeResultDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'charge_id')
  final String? chargeId;

  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  @JsonKey(name: 'error')
  final String? error;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'portal_url')
  final String? portalUrl;

  @JsonKey(name: 'retry_after')
  final int? retryAfter;

  Map<String, dynamic> toJson() => _$BillingChargeResultDtoToJson(this);

  BillingChargeResult toDomain() {
    return BillingChargeResult(
      ok: ok ?? false,
      chargeId: chargeId,
      idempotencyKey: idempotencyKey ?? '',
      errorCode: error,
      message: message,
      portalUrl: portalUrl,
      retryAfter: retryAfter,
    );
  }
}

/// Wire DTO for `billing.charge_status` result.
@JsonSerializable()
class BillingChargeStatusDto {
  const BillingChargeStatusDto({
    this.ok,
    this.status,
    this.amountUsd,
    this.settledAt,
    this.reason,
    this.error,
    this.message,
  });

  factory BillingChargeStatusDto.fromJson(Map<String, dynamic> json) =>
      _$BillingChargeStatusDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'amount_usd')
  final String? amountUsd;

  @JsonKey(name: 'settled_at')
  final String? settledAt;

  @JsonKey(name: 'reason')
  final String? reason;

  @JsonKey(name: 'error')
  final String? error;

  @JsonKey(name: 'message')
  final String? message;

  Map<String, dynamic> toJson() => _$BillingChargeStatusDtoToJson(this);

  BillingChargeStatus toDomain() {
    return BillingChargeStatus(
      ok: ok ?? false,
      status: status,
      amountUsd: amountUsd,
      settledAt: settledAt,
      reason: reason,
      errorCode: error,
      message: message,
    );
  }
}

/// Wire DTO for `billing.auto_reload` and `billing.step_up` results.
@JsonSerializable()
class BillingMutationResultDto {
  const BillingMutationResultDto({
    this.ok,
    this.granted,
    this.error,
    this.message,
  });

  factory BillingMutationResultDto.fromJson(Map<String, dynamic> json) =>
      _$BillingMutationResultDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'granted')
  final bool? granted;

  @JsonKey(name: 'error')
  final String? error;

  @JsonKey(name: 'message')
  final String? message;

  Map<String, dynamic> toJson() => _$BillingMutationResultDtoToJson(this);

  BillingMutationResult toDomain() {
    return BillingMutationResult(
      ok: ok ?? false,
      granted: granted,
      errorCode: error,
      message: message,
    );
  }
}
