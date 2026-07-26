/// Domain model for update check result (ticket P9-08).
library;

/// Result of comparing local app version against gateway version.
final class UpdateCheck {
  const UpdateCheck({
    required this.localVersion,
    required this.gatewayVersion,
    required this.status,
  });

  /// Local app version string (e.g. "1.0.0").
  final String localVersion;

  /// Gateway version string (e.g. "1.2.3"), or empty if not connected.
  final String gatewayVersion;

  /// Update check status.
  final UpdateCheckStatus status;

  @override
  bool operator ==(Object other) {
    return other is UpdateCheck &&
        other.localVersion == localVersion &&
        other.gatewayVersion == gatewayVersion &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(localVersion, gatewayVersion, status);

  @override
  String toString() {
    return 'UpdateCheck(localVersion: $localVersion, gatewayVersion: $gatewayVersion, status: $status)';
  }
}

/// Update check status enum.
enum UpdateCheckStatus {
  /// Local and gateway versions match.
  upToDate,

  /// Gateway version is newer than local.
  gatewayNewer,

  /// Local version is newer than gateway.
  clientNewer,

  /// Cannot determine (not connected or version missing).
  unknown,
}
