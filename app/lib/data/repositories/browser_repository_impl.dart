import 'package:flit/data/dto/browser_dtos.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/browser_status.dart';
import 'package:flit/domain/repositories/browser_repository.dart';

/// [BrowserRepository] over [GatewayRpcClient.request] (ticket P9-05).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
/// `browser.manage` takes `action` (status|connect|disconnect), optional `url`
/// and `session_id`. `preview.restart` takes required `session_id` + `url`,
/// optional `cwd` + `context`.
///
/// Wire quirk: `browser.progress` events are ONLY emitted when `browser.manage`
/// was called WITH a `session_id` param; otherwise human-readable lines come
/// back in the result's `messages` list.
final class BrowserRepositoryImpl implements BrowserRepository {
  const BrowserRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<BrowserStatus> status() async {
    final params = <String, dynamic>{'action': 'status'};
    final result = await _client.request('browser.manage', params);
    final dto = BrowserManageResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<BrowserStatus> connect({String? url, String? sessionId}) async {
    final params = <String, dynamic>{
      'action': 'connect',
      'url': ?url,
      'session_id': ?sessionId,
    };
    final result = await _client.request('browser.manage', params);
    final dto = BrowserManageResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<BrowserStatus> disconnect() async {
    final params = <String, dynamic>{'action': 'disconnect'};
    final result = await _client.request('browser.manage', params);
    final dto = BrowserManageResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Stream<BrowserProgressLine> progress(String sessionId) {
    // browser.progress events are emitted on the session_id passed to
    // browser.manage (protocol P9-05).
    return _client.events
        .where((event) => event.sessionId == sessionId)
        .map(parseGatewayEvent)
        .where((event) => event is BrowserProgressEvent)
        .cast<BrowserProgressEvent>()
        .map(
          (event) =>
              BrowserProgressLine(message: event.message, level: event.level),
        );
  }

  @override
  Future<String> restartPreview({
    required String sessionId,
    required String url,
    String? cwd,
    String? context,
  }) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'url': url,
      'cwd': ?cwd,
      'context': ?context,
    };
    final result = await _client.request('preview.restart', params);
    final dto = PreviewRestartResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Stream<PreviewRestartEvent> previewEvents(String sessionId) {
    // preview.restart events are emitted on the PARENT session_id (protocol
    // P9-05). The first progress frame may omit `level`, defaulting to "info".
    return _client.events
        .where((event) => event.sessionId == sessionId)
        .map(parseGatewayEvent)
        .where(
          (event) =>
              event is PreviewRestartProgressEvent ||
              event is PreviewRestartCompleteEvent,
        )
        .map((event) {
          if (event is PreviewRestartProgressEvent) {
            return PreviewRestartEvent(
              taskId: event.taskId,
              text: event.text,
              level: event.level,
              terminal: false,
            );
          } else if (event is PreviewRestartCompleteEvent) {
            return PreviewRestartEvent(
              taskId: event.taskId,
              text: event.text,
              level: 'info',
              terminal: true,
            );
          } else {
            // unreachable, but satisfy the type checker
            throw StateError('Unexpected event type: ${event.runtimeType}');
          }
        });
  }
}
