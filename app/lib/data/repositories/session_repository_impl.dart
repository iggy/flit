import 'package:flit/data/dto/session_dtos.dart';
import 'package:flit/data/dto/status_result_dto.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/session_bootstrap.dart';
import 'package:flit/domain/models/session_detail.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flit/domain/repositories/session_repository.dart';

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
    String? provider,
    String? reasoningEffort,
    bool? fast,
    String? parentSessionId,
    String? source,
  }) async {
    // Wire §2: send only the non-null optionals (null-aware map elements) —
    // an omitted per-session override means "inherit the profile", and for
    // `fast` that is distinct from an explicit `false` (contract v4).
    final params = <String, dynamic>{
      'profile': ?profile,
      'cwd': ?cwd,
      'model': ?model,
      'provider': ?provider,
      'reasoning_effort': ?reasoningEffort,
      'fast': ?fast,
      'parent_session_id': ?parentSessionId,
      'source': ?source,
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
  Future<SessionResumeResult> resume(
    String durableId, {
    bool omitMessages = false,
    bool lazy = false,
  }) async {
    // Wire §5: the DURABLE id goes in as `session_id`; a NEW short live id
    // comes back. `omit_messages` / `lazy` are only sent when set — the
    // gateway defaults both to false and older ones ignore them anyway.
    final params = <String, dynamic>{
      'session_id': durableId,
      if (omitMessages) 'omit_messages': true,
      if (lazy) 'lazy': true,
    };
    final result = await _client.request('session.resume', params);
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

  @override
  Future<MostRecentSession?> mostRecent({String? profile}) async {
    // Phase 2, §session.most_recent: NO session id param (protocol §9).
    // Returns null when no eligible session found (wire `session_id: null`).
    final params = <String, dynamic>{'profile': ?profile};
    final result = await _client.request('session.most_recent', params);
    return MostRecentSessionDto.fromJson(result).toDomainOrNull();
  }

  @override
  Future<String> setTitle(String liveId, String title) async {
    // Phase 2, §session.title SET: LIVE id (protocol §9).
    final result = await _client.request('session.title', <String, dynamic>{
      'session_id': liveId,
      'title': title,
    });
    return result['title'] as String? ?? title;
  }

  @override
  Future<void> delete(String durableId, {String? profile}) async {
    // Phase 2, §session.delete: DURABLE id (protocol §9).
    final params = <String, dynamic>{
      'session_id': durableId,
      'profile': ?profile,
    };
    await _client.request('session.delete', params);
  }

  @override
  Future<SessionUsageStats> usage(String liveId) async {
    // Phase 2, §session.usage: LIVE id (protocol §9). LONG handler.
    final result = await _client.request('session.usage', <String, dynamic>{
      'session_id': liveId,
    });
    return SessionUsageDto.fromJson(result).toDomain();
  }

  @override
  Future<ContextBreakdown> contextBreakdown(String liveId) async {
    // Phase 2, §session.context_breakdown: LIVE id (protocol §9).
    final result = await _client.request(
      'session.context_breakdown',
      <String, dynamic>{'session_id': liveId},
    );
    return ContextBreakdownDto.fromJson(result).toDomain();
  }

  @override
  Future<CompressResult> compress(String liveId, {String? focusTopic}) async {
    // Phase 2, §session.compress: LIVE id (protocol §9). LONG handler.
    final params = <String, dynamic>{
      'session_id': liveId,
      'focus_topic': ?focusTopic,
    };
    final result = await _client.request('session.compress', params);
    return CompressResultDto.fromJson(result).toDomain();
  }

  @override
  Future<int> undo(String liveId) async {
    // Phase 2, §session.undo: LIVE id (protocol §9).
    final result = await _client.request('session.undo', <String, dynamic>{
      'session_id': liveId,
    });
    return result['removed'] as int? ?? 0;
  }

  @override
  Future<String> save(String liveId) async {
    // Phase 2, §session.save: LIVE id (protocol §9).
    final result = await _client.request('session.save', <String, dynamic>{
      'session_id': liveId,
    });
    return result['file'] as String? ?? '';
  }

  @override
  Future<BranchResult> branch(String liveId, {String? name}) async {
    // Phase 2, §session.branch: LIVE id of parent (protocol §9). LONG handler.
    final params = <String, dynamic>{'session_id': liveId, 'name': ?name};
    final result = await _client.request('session.branch', params);
    return BranchResultDto.fromJson(result).toDomain();
  }

  @override
  Future<void> setCwd(String liveId, String cwd) async {
    // Phase 2, §session.cwd.set: LIVE id (protocol §9). Ignore the info dict.
    await _client.request('session.cwd.set', <String, dynamic>{
      'session_id': liveId,
      'cwd': cwd,
    });
  }

  @override
  Future<SteerOutcome> steer(String liveId, String text) async {
    // P3-07: LIVE id (protocol §9). Result status ∈ queued|rejected.
    final result = await _client.request('session.steer', <String, dynamic>{
      'session_id': liveId,
      'text': text,
    });
    return result['status'] == 'rejected'
        ? SteerOutcome.rejected
        : SteerOutcome.queued;
  }

  /// Asserts the normal-path acknowledgement without enforcing it (see the
  /// defensive note at each call site).
  static void _expectStatus(Map<String, dynamic> result, String expected) {
    final status = StatusResultDto.fromJson(result).status;
    assert(status == expected, 'expected status "$expected", got "$status"');
  }
}
