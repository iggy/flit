import 'package:flit/data/dto/background_dtos.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/background_task.dart';
import 'package:flit/domain/repositories/background_repository.dart';

final class BackgroundRepositoryImpl implements BackgroundRepository {
  const BackgroundRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<String> submit(String sessionId, String text) async {
    final result = await _client.request('prompt.background', <String, dynamic>{
      'session_id': sessionId,
      'text': text,
    });
    return PromptBackgroundResultDto.fromJson(result).toDomain();
  }

  @override
  Stream<BackgroundCompletion> completions(String sessionId) {
    // background.complete is emitted on the PARENT session_id (protocol P5-02).
    return _client.events
        .where((event) => event.sessionId == sessionId)
        .map(parseGatewayEvent)
        .where((event) => event is BackgroundCompleteEvent)
        .cast<BackgroundCompleteEvent>()
        .map(
          (event) =>
              BackgroundCompletion(taskId: event.taskId, text: event.text),
        );
  }
}
