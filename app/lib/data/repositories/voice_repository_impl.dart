import 'package:flit/data/dto/voice_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/voice_state.dart';
import 'package:flit/domain/repositories/voice_repository.dart';

/// [VoiceRepository] over [GatewayRpcClient.request] (ticket P7-05).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
/// Legacy fallback path: the gateway records from its own mic and speaks
/// through its own speakers; this client just triggers actions and consumes
/// events. The default client-side path lives in
/// lib/application/voice/client_voice_providers.dart.
final class VoiceRepositoryImpl implements VoiceRepository {
  const VoiceRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<VoiceToggleResult> toggle(String action) async {
    final params = <String, dynamic>{'action': action};
    final result = await _client.request('voice.toggle', params);
    final dto = VoiceToggleResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<VoiceRecordResult> record(String action, {String? sessionId}) async {
    final params = <String, dynamic>{
      'action': action,
      'session_id': ?sessionId,
    };
    final result = await _client.request('voice.record', params);
    final dto = VoiceRecordResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<VoiceTtsResult> tts(String text) async {
    final params = <String, dynamic>{'text': text};
    final result = await _client.request('voice.tts', params);
    final dto = VoiceTtsResultDto.fromJson(result);
    return dto.toDomain();
  }
}
