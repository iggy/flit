import 'package:flit/data/dto/slash_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/slash_command.dart';
import 'package:flit/domain/models/slash_completion.dart';
import 'package:flit/domain/repositories/slash_repository.dart';

/// [SlashRepository] over [GatewayRpcClient.request] (tickets P3-01/02/03).
///
/// Method names/params come VERBATIM from
/// docs/reference/08-agent-transparency-wire-shapes.md — never invent protocol.
final class SlashRepositoryImpl implements SlashRepository {
  const SlashRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<SlashCatalog> catalog() async {
    // Wire §commands.catalog: no params.
    final result = await _client.request('commands.catalog');
    return CommandsCatalogDto.fromJson(result).toDomain();
  }

  @override
  Future<CommandResolution> resolve(String name) async {
    // Wire §command.resolve: {name: str}.
    final result = await _client.request('command.resolve', <String, dynamic>{
      'name': name,
    });
    return CommandResolveDto.fromJson(result).toDomain();
  }

  @override
  Future<SlashCompletionResult> completeSlash(String text) async {
    // Wire §complete.slash: {text: str}.
    final result = await _client.request('complete.slash', <String, dynamic>{
      'text': text,
    });
    return CompleteSlashDto.fromJson(result).toDomain();
  }

  @override
  Future<List<CompletionItem>> completePath(String word) async {
    // Wire §complete.path: {word: str}.
    final result = await _client.request('complete.path', <String, dynamic>{
      'word': word,
    });
    return CompletePathDto.fromJson(result).toDomain();
  }

  @override
  Future<CommandDispatchResult> dispatch({
    required String name,
    required String arg,
    required String sessionId,
  }) async {
    // Wire §command.dispatch: {name, arg, session_id}.
    final result = await _client.request('command.dispatch', <String, dynamic>{
      'name': name,
      'arg': arg,
      'session_id': sessionId,
    });
    return CommandDispatchDto.fromJson(result).toDomain();
  }

  @override
  Future<SlashExecResult> exec({
    required String command,
    required String sessionId,
  }) async {
    // Wire §slash.exec: {command, session_id}. LONG handler.
    final result = await _client.request('slash.exec', <String, dynamic>{
      'command': command,
      'session_id': sessionId,
    });
    return SlashExecDto.fromJson(result).toDomain();
  }
}
