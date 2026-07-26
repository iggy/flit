// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingStateDto _$BillingStateDtoFromJson(Map<String, dynamic> json) =>
    BillingStateDto(
      ok: json['ok'] as bool?,
      loggedIn: json['logged_in'] as bool?,
      orgName: json['org_name'] as String?,
      orgSlug: json['org_slug'] as String?,
      role: json['role'] as String?,
      isAdmin: json['is_admin'] as bool?,
      canChangePlan: json['can_change_plan'] as bool?,
      canCharge: json['can_charge'] as bool?,
      balanceUsd: json['balance_usd'] as String?,
      balanceDisplay: json['balance_display'] as String?,
      cliBillingEnabled: json['cli_billing_enabled'] as bool?,
      chargePresets: (json['charge_presets'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      chargePresetsDisplay: (json['charge_presets_display'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      minUsd: json['min_usd'] as String?,
      maxUsd: json['max_usd'] as String?,
      card: json['card'] == null
          ? null
          : BillingCardDto.fromJson(json['card'] as Map<String, dynamic>),
      monthlyCap: json['monthly_cap'] == null
          ? null
          : BillingMonthlyCapDto.fromJson(
              json['monthly_cap'] as Map<String, dynamic>,
            ),
      autoReload: json['auto_reload'] == null
          ? null
          : BillingAutoReloadDto.fromJson(
              json['auto_reload'] as Map<String, dynamic>,
            ),
      portalUrl: json['portal_url'] as String?,
      error: json['error'] as String?,
      usage: json['usage'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BillingStateDtoToJson(BillingStateDto instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'logged_in': instance.loggedIn,
      'org_name': instance.orgName,
      'org_slug': instance.orgSlug,
      'role': instance.role,
      'is_admin': instance.isAdmin,
      'can_change_plan': instance.canChangePlan,
      'can_charge': instance.canCharge,
      'balance_usd': instance.balanceUsd,
      'balance_display': instance.balanceDisplay,
      'cli_billing_enabled': instance.cliBillingEnabled,
      'charge_presets': instance.chargePresets,
      'charge_presets_display': instance.chargePresetsDisplay,
      'min_usd': instance.minUsd,
      'max_usd': instance.maxUsd,
      'card': instance.card,
      'monthly_cap': instance.monthlyCap,
      'auto_reload': instance.autoReload,
      'portal_url': instance.portalUrl,
      'error': instance.error,
      'usage': instance.usage,
    };

BillingCardDto _$BillingCardDtoFromJson(Map<String, dynamic> json) =>
    BillingCardDto(
      brand: json['brand'] as String?,
      last4: json['last4'] as String?,
      masked: json['masked'] as String?,
      display: json['display'] as String?,
      resolvedVia: json['resolved_via'] as String?,
    );

Map<String, dynamic> _$BillingCardDtoToJson(BillingCardDto instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'last4': instance.last4,
      'masked': instance.masked,
      'display': instance.display,
      'resolved_via': instance.resolvedVia,
    };

BillingMonthlyCapDto _$BillingMonthlyCapDtoFromJson(
  Map<String, dynamic> json,
) => BillingMonthlyCapDto(
  limitUsd: json['limit_usd'] as String?,
  limitDisplay: json['limit_display'] as String?,
  spentThisMonthUsd: json['spent_this_month_usd'] as String?,
  spentDisplay: json['spent_display'] as String?,
  isDefaultCeiling: json['is_default_ceiling'] as bool?,
);

Map<String, dynamic> _$BillingMonthlyCapDtoToJson(
  BillingMonthlyCapDto instance,
) => <String, dynamic>{
  'limit_usd': instance.limitUsd,
  'limit_display': instance.limitDisplay,
  'spent_this_month_usd': instance.spentThisMonthUsd,
  'spent_display': instance.spentDisplay,
  'is_default_ceiling': instance.isDefaultCeiling,
};

BillingAutoReloadDto _$BillingAutoReloadDtoFromJson(
  Map<String, dynamic> json,
) => BillingAutoReloadDto(
  enabled: json['enabled'] as bool?,
  thresholdUsd: json['threshold_usd'] as String?,
  thresholdDisplay: json['threshold_display'] as String?,
  reloadToUsd: json['reload_to_usd'] as String?,
  reloadToDisplay: json['reload_to_display'] as String?,
  card: json['card'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$BillingAutoReloadDtoToJson(
  BillingAutoReloadDto instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'threshold_usd': instance.thresholdUsd,
  'threshold_display': instance.thresholdDisplay,
  'reload_to_usd': instance.reloadToUsd,
  'reload_to_display': instance.reloadToDisplay,
  'card': instance.card,
};

BillingChargeResultDto _$BillingChargeResultDtoFromJson(
  Map<String, dynamic> json,
) => BillingChargeResultDto(
  ok: json['ok'] as bool?,
  chargeId: json['charge_id'] as String?,
  idempotencyKey: json['idempotency_key'] as String?,
  error: json['error'] as String?,
  message: json['message'] as String?,
  portalUrl: json['portal_url'] as String?,
  retryAfter: (json['retry_after'] as num?)?.toInt(),
);

Map<String, dynamic> _$BillingChargeResultDtoToJson(
  BillingChargeResultDto instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'charge_id': instance.chargeId,
  'idempotency_key': instance.idempotencyKey,
  'error': instance.error,
  'message': instance.message,
  'portal_url': instance.portalUrl,
  'retry_after': instance.retryAfter,
};

BillingChargeStatusDto _$BillingChargeStatusDtoFromJson(
  Map<String, dynamic> json,
) => BillingChargeStatusDto(
  ok: json['ok'] as bool?,
  status: json['status'] as String?,
  amountUsd: json['amount_usd'] as String?,
  settledAt: json['settled_at'] as String?,
  reason: json['reason'] as String?,
  error: json['error'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$BillingChargeStatusDtoToJson(
  BillingChargeStatusDto instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'status': instance.status,
  'amount_usd': instance.amountUsd,
  'settled_at': instance.settledAt,
  'reason': instance.reason,
  'error': instance.error,
  'message': instance.message,
};

BillingMutationResultDto _$BillingMutationResultDtoFromJson(
  Map<String, dynamic> json,
) => BillingMutationResultDto(
  ok: json['ok'] as bool?,
  granted: json['granted'] as bool?,
  error: json['error'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$BillingMutationResultDtoToJson(
  BillingMutationResultDto instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'granted': instance.granted,
  'error': instance.error,
  'message': instance.message,
};
