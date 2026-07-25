import 'package:flit/domain/models/health_status.dart';

/// Repository for gateway health diagnostics (ticket P4-06).
abstract interface class HealthRepository {
  /// `setup.status` — whether the LLM provider is configured.
  Future<bool> setupStatus();

  /// `setup.runtime_check` — runtime LLM provider check.
  Future<RuntimeCheck> runtimeCheck({String? provider});

  /// `verification.status` — verification status string (defaults "unknown"
  /// when missing or nested field absent).
  Future<String> verificationStatus({String? sessionId, String? cwd});
}
