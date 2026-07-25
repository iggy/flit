library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/data/repositories/health_repository.dart';
import 'package:flit/domain/models/health_status.dart';
import 'package:flit/domain/repositories/health_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Health repository provider (ticket P4-06).
final healthRepositoryProvider = Provider<HealthRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return HealthRepositoryImpl(client);
});

/// Gateway health status provider (ticket P4-06) — assembles
/// setupStatus + runtimeCheck + verificationStatus.
final healthStatusProvider = FutureProvider<HealthStatus>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  if (repository == null) {
    return const HealthStatus(
      providerConfigured: false,
      runtime: null,
      verificationStatus: 'unknown',
    );
  }

  // Fetch all three health checks
  final providerConfigured = await repository.setupStatus();

  RuntimeCheck? runtime;
  try {
    runtime = await repository.runtimeCheck();
  } on Object {
    // Runtime check failed; leave runtime null
  }

  final liveId = ref.read(activeSessionProvider).liveId;
  final verificationStatus = await repository.verificationStatus(
    sessionId: liveId,
  );

  return HealthStatus(
    providerConfigured: providerConfigured,
    runtime: runtime,
    verificationStatus: verificationStatus,
  );
});
