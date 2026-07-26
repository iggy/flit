import 'dart:async';

import 'package:flit/application/billing/billing_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/domain/models/billing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Billing & credits screen (tickets P8-04, P8-05): balance, card, monthly
/// cap, auto-reload, charge presets, and step-up device flow for granting
/// charge access.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String? _chargingAmount;
  bool _isPolling = false;
  String? _chargeError;
  bool _chargeSuccess = false;

  bool _autoReloadEnabled = false;
  double _autoReloadThreshold = 10.0;
  double _autoReloadTopUp = 20.0;
  bool _isUpdatingAutoReload = false;
  String? _autoReloadError;
  bool _autoReloadSuccess = false;

  bool _isSteppingUp = false;
  String? _stepUpError;

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & credits'),
      ),
      body: billingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BillingError(
          message: error.toString(),
          onRetry: () => ref.invalidate(billingStateProvider),
        ),
        data: (data) {
          if (data == null) {
            return const _BillingDisconnected();
          }
          return _BillingContent(
            state: data,
            chargingAmount: _chargingAmount,
            isPolling: _isPolling,
            chargeError: _chargeError,
            chargeSuccess: _chargeSuccess,
            onCharge: _handleCharge,
            autoReloadEnabled: _autoReloadEnabled,
            autoReloadThreshold: _autoReloadThreshold,
            autoReloadTopUp: _autoReloadTopUp,
            onAutoReloadEnabledChanged: (value) {
              setState(() {
                _autoReloadEnabled = value;
              });
            },
            onAutoReloadThresholdChanged: (value) {
              setState(() {
                _autoReloadThreshold = value;
              });
            },
            onAutoReloadTopUpChanged: (value) {
              setState(() {
                _autoReloadTopUp = value;
              });
            },
            onAutoReloadSave: _handleAutoReloadSave,
            isUpdatingAutoReload: _isUpdatingAutoReload,
            autoReloadError: _autoReloadError,
            autoReloadSuccess: _autoReloadSuccess,
            onStepUp: _handleStepUp,
            isSteppingUp: _isSteppingUp,
            stepUpError: _stepUpError,
          );
        },
      ),
    );
  }

  Future<void> _handleCharge(String amountUsd) async {
    setState(() {
      _chargingAmount = amountUsd;
      _isPolling = false;
      _chargeError = null;
      _chargeSuccess = false;
    });

    final repository = ref.read(billingRepositoryProvider);
    if (repository == null) {
      setState(() {
        _chargeError = 'Not connected';
        _chargingAmount = null;
      });
      return;
    }

    try {
      final result = await repository.charge(
        amountUsd: amountUsd,
        idempotencyKey:
            'charge_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!result.ok) {
        setState(() {
          _chargeError = _formatBillingError(result.errorCode, result.message);
          _chargingAmount = null;
        });
        return;
      }

      final chargeId = result.chargeId;
      if (chargeId == null) {
        setState(() {
          _chargeError = 'No charge ID returned';
          _chargingAmount = null;
        });
        return;
      }

      setState(() {
        _isPolling = true;
      });

      unawaited(_pollChargeStatus(chargeId));
    } on Object catch (error) {
      setState(() {
        _chargeError = error.toString();
        _chargingAmount = null;
      });
    }
  }

  Future<void> _pollChargeStatus(String chargeId) async {
    final repository = ref.read(billingRepositoryProvider);
    if (repository == null) {
      return;
    }

    var attempts = 0;
    const maxAttempts = 30;
    const pollInterval = Duration(seconds: 2);

    while (attempts < maxAttempts && mounted) {
      await Future<void>.delayed(pollInterval);
      attempts++;

      try {
        final status = await repository.chargeStatus(chargeId);

        if (!status.ok) {
          if (mounted) {
            setState(() {
              _chargeError =
                  _formatBillingError(status.errorCode, status.message);
              _chargingAmount = null;
              _isPolling = false;
            });
          }
          return;
        }

        final statusValue = status.status?.toLowerCase() ?? '';
        if (statusValue.contains('settled') ||
            statusValue.contains('succeeded')) {
          if (mounted) {
            setState(() {
              _chargeSuccess = true;
              _chargingAmount = null;
              _isPolling = false;
            });
            ref.invalidate(billingStateProvider);
          }
          return;
        }

        final reason = status.reason;
        if (reason != null && reason.isNotEmpty) {
          if (mounted) {
            setState(() {
              _chargeError = 'Charge failed: $reason';
              _chargingAmount = null;
              _isPolling = false;
            });
          }
          return;
        }
      } on Object catch (error) {
        if (mounted) {
          setState(() {
            _chargeError = error.toString();
            _chargingAmount = null;
            _isPolling = false;
          });
        }
        return;
      }
    }

    if (mounted && _isPolling) {
      setState(() {
        _chargeError = 'Charge status polling timed out';
        _chargingAmount = null;
        _isPolling = false;
      });
    }
  }

  Future<void> _handleAutoReloadSave() async {
    setState(() {
      _isUpdatingAutoReload = true;
      _autoReloadError = null;
      _autoReloadSuccess = false;
    });

    final repository = ref.read(billingRepositoryProvider);
    if (repository == null) {
      setState(() {
        _autoReloadError = 'Not connected';
        _isUpdatingAutoReload = false;
      });
      return;
    }

    try {
      final result = await repository.autoReload(
        enabled: _autoReloadEnabled,
        threshold: _autoReloadThreshold,
        topUpAmount: _autoReloadTopUp,
      );

      if (!result.ok) {
        setState(() {
          _autoReloadError =
              _formatBillingError(result.errorCode, result.message);
          _isUpdatingAutoReload = false;
        });
        return;
      }

      setState(() {
        _autoReloadSuccess = true;
        _isUpdatingAutoReload = false;
      });
      ref.invalidate(billingStateProvider);
    } on Object catch (error) {
      setState(() {
        _autoReloadError = error.toString();
        _isUpdatingAutoReload = false;
      });
    }
  }

  Future<void> _handleStepUp() async {
    setState(() {
      _isSteppingUp = true;
      _stepUpError = null;
    });

    final repository = ref.read(billingRepositoryProvider);
    if (repository == null) {
      setState(() {
        _stepUpError = 'Not connected';
        _isSteppingUp = false;
      });
      return;
    }

    final sessionState = ref.read(activeSessionProvider);
    final sessionId = sessionState.liveId ?? '';

    try {
      final result = await repository.stepUp(sessionId: sessionId);

      if (!result.ok) {
        setState(() {
          _stepUpError =
              _formatBillingError(result.errorCode, result.message);
          _isSteppingUp = false;
        });
        return;
      }

      if (result.granted == true) {
        ref.invalidate(billingStateProvider);
      }

      setState(() {
        _isSteppingUp = false;
      });
    } on Object catch (error) {
      setState(() {
        _stepUpError = error.toString();
        _isSteppingUp = false;
      });
    }
  }

  String _formatBillingError(String? code, String? message) {
    if (code == null) {
      return message ?? 'Unknown error';
    }
    switch (code) {
      case 'insufficient_scope':
        return 'Insufficient permissions. Please grant charge access.';
      case 'no_payment_method':
        return 'No payment method configured. Please add a card.';
      case 'monthly_cap_exceeded':
        return 'Monthly spending cap exceeded.';
      case 'remote_spending_disabled':
        return 'Remote spending is disabled.';
      case 'remote_spending_revoked':
        return 'Remote spending permission was revoked.';
      case 'session_revoked':
        return 'Session was revoked.';
      case 'rate_limited':
        return 'Rate limited. Please try again later.';
      case 'cli_billing_disabled':
        return 'CLI billing is disabled.';
      case 'invalid_request':
        return 'Invalid request: ${message ?? code}';
      case 'invalid_charge_id':
        return 'Invalid charge ID.';
      case 'stripe_unavailable':
        return 'Payment provider temporarily unavailable.';
      case 'network_error':
        return 'Network error. Please try again.';
      case 'internal_error':
        return 'Internal error. Please try again.';
      case 'validation_failed':
        return 'Validation failed: ${message ?? code}';
      case 'consent_required':
        return 'Consent required to proceed.';
      default:
        return message ?? code;
    }
  }
}

class _BillingContent extends ConsumerWidget {
  const _BillingContent({
    required this.state,
    required this.chargingAmount,
    required this.isPolling,
    required this.chargeError,
    required this.chargeSuccess,
    required this.onCharge,
    required this.autoReloadEnabled,
    required this.autoReloadThreshold,
    required this.autoReloadTopUp,
    required this.onAutoReloadEnabledChanged,
    required this.onAutoReloadThresholdChanged,
    required this.onAutoReloadTopUpChanged,
    required this.onAutoReloadSave,
    required this.isUpdatingAutoReload,
    required this.autoReloadError,
    required this.autoReloadSuccess,
    required this.onStepUp,
    required this.isSteppingUp,
    required this.stepUpError,
  });

  final BillingState state;
  final String? chargingAmount;
  final bool isPolling;
  final String? chargeError;
  final bool chargeSuccess;
  final void Function(String amountUsd) onCharge;
  final bool autoReloadEnabled;
  final double autoReloadThreshold;
  final double autoReloadTopUp;
  final void Function(bool) onAutoReloadEnabledChanged;
  final void Function(double) onAutoReloadThresholdChanged;
  final void Function(double) onAutoReloadTopUpChanged;
  final VoidCallback onAutoReloadSave;
  final bool isUpdatingAutoReload;
  final String? autoReloadError;
  final bool autoReloadSuccess;
  final VoidCallback onStepUp;
  final bool isSteppingUp;
  final String? stepUpError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _BalanceCard(balance: state.balanceDisplay),
        const SizedBox(height: 16),
        if (state.card != null) _PaymentCard(card: state.card!),
        if (state.card != null) const SizedBox(height: 16),
        if (state.monthlyCap != null)
          _MonthlyCapCard(monthlyCap: state.monthlyCap!),
        if (state.monthlyCap != null) const SizedBox(height: 16),
        if (!state.canCharge && state.cliBillingEnabled)
          _StepUpSection(
            onStepUp: onStepUp,
            isSteppingUp: isSteppingUp,
            stepUpError: stepUpError,
          ),
        if (!state.canCharge && state.cliBillingEnabled)
          const SizedBox(height: 16),
        if (state.canCharge)
          _ChargeSection(
            presets: state.chargePresets,
            presetsDisplay: state.chargePresetsDisplay,
            chargingAmount: chargingAmount,
            isPolling: isPolling,
            chargeError: chargeError,
            chargeSuccess: chargeSuccess,
            onCharge: onCharge,
          ),
        if (state.canCharge) const SizedBox(height: 16),
        if (state.canCharge && state.cliBillingEnabled)
          _AutoReloadSection(
            currentAutoReload: state.autoReload,
            enabled: autoReloadEnabled,
            threshold: autoReloadThreshold,
            topUp: autoReloadTopUp,
            onEnabledChanged: onAutoReloadEnabledChanged,
            onThresholdChanged: onAutoReloadThresholdChanged,
            onTopUpChanged: onAutoReloadTopUpChanged,
            onSave: onAutoReloadSave,
            isUpdating: isUpdatingAutoReload,
            error: autoReloadError,
            success: autoReloadSuccess,
          ),
        const _StepUpVerificationListener(),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              balance,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.card});

  final BillingCard card;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              card.display ?? '${card.brand} •••• ${card.last4}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCapCard extends StatelessWidget {
  const _MonthlyCapCard({required this.monthlyCap});

  final BillingMonthlyCap monthlyCap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Monthly cap',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Limit: ${monthlyCap.limitDisplay}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Spent: ${monthlyCap.spentDisplay}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (monthlyCap.isDefaultCeiling) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                '(default ceiling)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepUpSection extends StatelessWidget {
  const _StepUpSection({
    required this.onStepUp,
    required this.isSteppingUp,
    required this.stepUpError,
  });

  final VoidCallback onStepUp;
  final bool isSteppingUp;
  final String? stepUpError;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Grant charge access',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You need to grant permission to charge your account.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isSteppingUp ? null : onStepUp,
              child: isSteppingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Grant access'),
            ),
            if (stepUpError != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                stepUpError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChargeSection extends StatelessWidget {
  const _ChargeSection({
    required this.presets,
    required this.presetsDisplay,
    required this.chargingAmount,
    required this.isPolling,
    required this.chargeError,
    required this.chargeSuccess,
    required this.onCharge,
  });

  final List<String> presets;
  final List<String> presetsDisplay;
  final String? chargingAmount;
  final bool isPolling;
  final String? chargeError;
  final bool chargeSuccess;
  final void Function(String amountUsd) onCharge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Add credits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (var i = 0; i < presets.length && i < presetsDisplay.length; i++)
                  FilledButton(
                    onPressed: chargingAmount != null
                        ? null
                        : () => onCharge(presets[i]),
                    child: Text(presetsDisplay[i]),
                  ),
              ],
            ),
            if (chargingAmount != null && isPolling) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processing charge...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            if (chargeError != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                chargeError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            if (chargeSuccess) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Charge successful!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AutoReloadSection extends StatelessWidget {
  const _AutoReloadSection({
    required this.currentAutoReload,
    required this.enabled,
    required this.threshold,
    required this.topUp,
    required this.onEnabledChanged,
    required this.onThresholdChanged,
    required this.onTopUpChanged,
    required this.onSave,
    required this.isUpdating,
    required this.error,
    required this.success,
  });

  final BillingAutoReload? currentAutoReload;
  final bool enabled;
  final double threshold;
  final double topUp;
  final void Function(bool) onEnabledChanged;
  final void Function(double) onThresholdChanged;
  final void Function(double) onTopUpChanged;
  final VoidCallback onSave;
  final bool isUpdating;
  final String? error;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Auto-reload',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (currentAutoReload != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Current: ${currentAutoReload!.enabled ? 'Enabled' : 'Disabled'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (currentAutoReload!.enabled) ...<Widget>[
                Text(
                  'Threshold: ${currentAutoReload!.thresholdDisplay}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  'Top-up: ${currentAutoReload!.reloadToDisplay}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable auto-reload'),
              value: enabled,
              onChanged: onEnabledChanged,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Text(
              'Threshold: \$${threshold.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: threshold,
              min: 5,
              max: 50,
              divisions: 9,
              label: '\$${threshold.toStringAsFixed(0)}',
              onChanged: enabled ? onThresholdChanged : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Top-up amount: \$${topUp.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: topUp,
              min: 10,
              max: 100,
              divisions: 18,
              label: '\$${topUp.toStringAsFixed(0)}',
              onChanged: enabled ? onTopUpChanged : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isUpdating ? null : onSave,
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            if (error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            if (success) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Auto-reload updated successfully!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepUpVerificationListener extends ConsumerWidget {
  const _StepUpVerificationListener();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<StepUpVerification?>(
      stepUpVerificationProvider,
      (previous, next) {
        if (next != null) {
          _showVerificationDialog(context, next);
          ref.read(stepUpVerificationProvider.notifier).clear();
        }
      },
    );
    return const SizedBox.shrink();
  }

  void _showVerificationDialog(
    BuildContext context,
    StepUpVerification verification,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Grant charge access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Open this URL in your browser:'),
            const SizedBox(height: 8),
            SelectableText(
              verification.verificationUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 12),
            const Text('Enter this code:'),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  verification.userCode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: verification.userCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              final url = Uri.parse(verification.verificationUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text('Open URL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _BillingDisconnected extends StatelessWidget {
  const _BillingDisconnected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Not connected to a gateway.'),
    );
  }
}

class _BillingError extends StatelessWidget {
  const _BillingError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline),
          const SizedBox(height: 8),
          Text(
            'Could not load billing state',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
