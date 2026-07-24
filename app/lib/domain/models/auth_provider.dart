/// One entry of `GET /api/auth/providers`
/// (docs/reference/01-gateway-protocol.md §2.2 step 1;
/// `dashboard_auth/routes.py:152`).
final class AuthProviderInfo {
  const AuthProviderInfo({
    required this.name,
    required this.displayName,
    required this.supportsPassword,
  });

  /// Provider slug, e.g. `local`, `nous`.
  final String name;

  /// Human label for the login UI.
  final String displayName;

  /// Whether `POST /auth/password-login` works against this provider.
  final bool supportsPassword;

  @override
  bool operator ==(Object other) {
    return other is AuthProviderInfo &&
        other.name == name &&
        other.displayName == displayName &&
        other.supportsPassword == supportsPassword;
  }

  @override
  int get hashCode => Object.hash(name, displayName, supportsPassword);

  @override
  String toString() =>
      'AuthProviderInfo(name: $name, supportsPassword: $supportsPassword)';
}
