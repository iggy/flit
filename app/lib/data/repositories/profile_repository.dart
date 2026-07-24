import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/transport/gateway_rest_client.dart';
import 'package:hermes/domain/models/profile.dart';
import 'package:hermes/domain/repositories/profile_repository.dart';

/// [ProfileRepository] over [GatewayRestClient] (ticket P1-13).
///
/// Endpoints and field names come VERBATIM from
/// docs/reference/03-mvp-wire-shapes.md §14 — never invent protocol:
///   - `GET  /api/profiles`         → `{"profiles": [...]}`
///   - `GET  /api/profiles/active`  → `{"active": "default"}`
///   - `POST /api/profiles/active`  body `{"name": "research"}`
/// Wire quirks (snake_case `is_default`/`skill_count`, absent optionals on
/// older gateways) are absorbed HERE; the domain model stays tidy
/// (05-conventions.md). [GatewayException]s from the client pass through;
/// only malformed bodies are mapped to [GatewayParseException].
final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._client);

  final GatewayRestClient _client;

  @override
  Future<List<Profile>> list() async {
    final body = await _client.getJson('/api/profiles');
    if (body is! Map<String, dynamic>) {
      throw const GatewayParseException(
        'GET /api/profiles returned a non-object body.',
      );
    }
    final profiles = body['profiles'];
    if (profiles is! List<dynamic>) {
      throw const GatewayParseException(
        'GET /api/profiles is missing the "profiles" list.',
      );
    }
    return profiles.map(_parseProfile).toList();
  }

  @override
  Future<String?> active() async {
    final body = await _client.getJson('/api/profiles/active');
    if (body is! Map<String, dynamic>) {
      throw const GatewayParseException(
        'GET /api/profiles/active returned a non-object body.',
      );
    }
    // Wire §14: {"active":"default"}. Tolerate a null/absent value — no
    // active profile is a legal state.
    final active = body['active'];
    if (active != null && active is! String) {
      throw const GatewayParseException(
        'GET /api/profiles/active: "active" is not a string.',
      );
    }
    return active as String?;
  }

  @override
  Future<void> setActive(String name) async {
    // Writes the sticky pointer FUTURE launches read — does NOT retarget
    // the running gateway (wire §14 / roadmap caveat).
    await _client.postJson(
      '/api/profiles/active',
      body: <String, dynamic>{'name': name},
    );
  }

  /// One entry of the `profiles` list. `name` is the identity and required;
  /// every other field is documented optional in wire §14 and tolerated
  /// missing (older gateways omit `provider`/`skill_count`/…).
  static Profile _parseProfile(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const GatewayParseException(
        'GET /api/profiles: a profile entry is not an object.',
      );
    }
    final name = raw['name'];
    if (name is! String) {
      throw const GatewayParseException(
        'GET /api/profiles: a profile entry is missing "name".',
      );
    }
    final isDefault = raw['is_default'];
    final skillCount = raw['skill_count'];
    return Profile(
      name: name,
      isDefault: isDefault is bool ? isDefault : false,
      model: raw['model'] as String?,
      provider: raw['provider'] as String?,
      description: raw['description'] as String?,
      skillCount: skillCount is num ? skillCount.toInt() : null,
    );
  }
}
