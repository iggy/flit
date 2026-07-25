/// Domain models for gateway health diagnostics (ticket P4-06).
library;

/// Gateway health status from `setup.status`, `setup.runtime_check`, and
/// `verification.status` (ticket P4-06).
final class HealthStatus {
  const HealthStatus({
    required this.providerConfigured,
    this.runtime,
    required this.verificationStatus,
  });

  /// Whether the LLM provider is configured (from `setup.status`).
  final bool providerConfigured;

  /// Runtime check result (from `setup.runtime_check`), or null if the check
  /// failed or wasn't run.
  final RuntimeCheck? runtime;

  /// Verification status string (from `verification.status.status`).
  final String verificationStatus;

  @override
  bool operator ==(Object other) {
    return other is HealthStatus &&
        other.providerConfigured == providerConfigured &&
        other.runtime == runtime &&
        other.verificationStatus == verificationStatus;
  }

  @override
  int get hashCode =>
      Object.hash(providerConfigured, runtime, verificationStatus);

  @override
  String toString() {
    return 'HealthStatus(providerConfigured: $providerConfigured, '
        'runtime: $runtime, verificationStatus: $verificationStatus)';
  }
}

/// Runtime check result from `setup.runtime_check` (ticket P4-06).
final class RuntimeCheck {
  const RuntimeCheck({
    required this.ok,
    required this.provider,
    required this.model,
    required this.source,
    this.error,
  });

  /// Whether the runtime check passed.
  final bool ok;

  /// Provider name (e.g. "anthropic").
  final String provider;

  /// Model identifier (e.g. "claude-3-5-sonnet-20250219").
  final String model;

  /// Source of the config (e.g. "env", "file").
  final String source;

  /// Error message when ok is false.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is RuntimeCheck &&
        other.ok == ok &&
        other.provider == provider &&
        other.model == model &&
        other.source == source &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(ok, provider, model, source, error);

  @override
  String toString() {
    return 'RuntimeCheck(ok: $ok, provider: $provider, model: $model, '
        'source: $source, error: $error)';
  }
}
