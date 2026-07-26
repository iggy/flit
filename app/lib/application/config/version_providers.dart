/// Riverpod providers for app versioning and update checks (ticket P9-08).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/util/semver.dart';
import 'package:flit/domain/models/app_version.dart';
import 'package:flit/domain/models/update_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's bundled version and build number (ticket P9-08).
///
/// Reads from the platform via `package_info_plus`; failures yield a safe
/// "unknown" value rather than throwing (this must not break a screen).
final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersion(version: info.version, buildNumber: info.buildNumber);
  } on Object {
    // Platform call failed; yield a safe unknown value
    return const AppVersion(version: 'unknown', buildNumber: 'unknown');
  }
});

/// Update check result comparing local app version against the connected
/// gateway's version (ticket P9-08).
///
/// Reads the gateway version from [gatewayStatusProvider] (which is set by the
/// connect controller on successful connect) and compares it numerically against
/// the local version. If either side is missing, the status is [UpdateCheckStatus.unknown].
final updateCheckProvider = FutureProvider<UpdateCheck>((ref) async {
  final appVersionAsync = await ref.watch(appVersionProvider.future);
  final gatewayStatus = ref.watch(gatewayStatusProvider);

  final localVersion = appVersionAsync.version;
  final gatewayVersion = gatewayStatus?.version ?? '';

  // If either version is missing or unknown, we can't compare
  if (localVersion == 'unknown' ||
      gatewayVersion.isEmpty ||
      gatewayVersion == 'unknown') {
    return UpdateCheck(
      localVersion: localVersion,
      gatewayVersion: gatewayVersion,
      status: UpdateCheckStatus.unknown,
    );
  }

  // Compare versions numerically
  final cmp = compareSemver(localVersion, gatewayVersion);

  final status = cmp == 0
      ? UpdateCheckStatus.upToDate
      : cmp < 0
      ? UpdateCheckStatus.gatewayNewer
      : UpdateCheckStatus.clientNewer;

  return UpdateCheck(
    localVersion: localVersion,
    gatewayVersion: gatewayVersion,
    status: status,
  );
});
