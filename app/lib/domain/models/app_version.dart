/// Domain model for the app's bundled version (ticket P9-08).
library;

/// The app's bundled version and build number.
final class AppVersion {
  const AppVersion({required this.version, required this.buildNumber});

  /// Semantic version string (e.g. "1.0.0").
  final String version;

  /// Build number string (e.g. "1").
  final String buildNumber;

  @override
  bool operator ==(Object other) {
    return other is AppVersion &&
        other.version == version &&
        other.buildNumber == buildNumber;
  }

  @override
  int get hashCode => Object.hash(version, buildNumber);

  @override
  String toString() {
    return 'AppVersion(version: $version, buildNumber: $buildNumber)';
  }
}
