import 'package:hermes/data/dto/session_dtos.dart';
import 'package:hermes/data/dto/status_result_dto.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/session_bootstrap.dart';
import 'package:hermes/domain/models/session_summary.dart';
import 'package:hermes/domain/repositories/session_repository.dart';

/// [SessionRepository] over [GatewayRpcClient.request] (ticket P1-04).
///
/// Method names/params come VERBATIM from
/// docs/reference/03-mvp-wire-shapes.md §2–§5, §12 — never invent protocol.
/// Wire quirks (snake_case, the two session ids) are absorbed by the DTOs.
final class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<SessionCreateResult> create({
    String? profile,
    String? cwd,
    String? model,
  }) async {
    // Wire §2: send only the non-null optionals (null-aware map elements).
    final params = <String, dynamic>{
      'profile': ?profile,
      'cwd': ?cwd,
      'model': ?model,
    };
    final result = await _client.request('session.create', params);
    return SessionCreateResultDto.fromJson(result).toDomain();
  }

  @override
  Future<List<SessionSummary>> list() async {
    final result = await _client.request('session.list');
    return SessionListResultDto.fromJson(result).toDomain();
  }

  @override
  Future<List<ActiveSession>> activeList({String? currentLiveId}) async {
    // Wire §4: `current_session_id` is sent ONLY when non-null — the
    // gateway doesn't own "current" (protocol §9).
    final params = <String, dynamic>{'current_session_id': ?currentLiveId};
    final result = await _client.request('session.active_list', params);
    return ActiveSessionListResultDto.fromJson(result).toDomain();
  }

  @override
  Future<SessionResumeResult> resume(String durableId) async {
    // Wire §5: the DURABLE id goes in as `session_id`; a NEW short live id
    // comes back.
    final result = await _client.request('session.resume', <String, dynamic>{
      'session_id': durableId,
    });
    return SessionResumeResultDto.fromJson(result).toDomain();
  }

  @override
  Future<void> interrupt(String liveId) async {
    // Wire §12: the LIVE id goes in as `session_id`. The result is
    // `{"status":"interrupted"}` — NOT `{ok:true}` (00-overview.md
    // divergences). Defensive: an unexpected/absent status still succeeds;
    // the subsequent turn events carry the ground truth.
    final result = await _client.request('session.interrupt', <String, dynamic>{
      'session_id': liveId,
    });
    _expectStatus(result, 'interrupted');
  }

  /// Asserts the normal-path acknowledgement without enforcing it (see the
  /// defensive note at each call site).
  static void _expectStatus(Map<String, dynamic> result, String expected) {
    final status = StatusResultDto.fromJson(result).status;
    assert(status == expected, 'expected status "$expected", got "$status"');
  }
}
