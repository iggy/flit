import 'package:flit/domain/models/browser_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'browser_dtos.g.dart';

/// Wire DTO for `browser.manage` result (actions: status|connect|disconnect).
///
/// Defensive parsing: [connected] defaults to false when absent; [url] and
/// [messages] are nullable (may be missing in the payload). A connect may
/// return `connected: false` with `messages` — that's a SUCCESSFUL result,
/// not an error.
@JsonSerializable()
class BrowserManageResultDto {
  const BrowserManageResultDto({this.connected, this.url, this.messages});

  factory BrowserManageResultDto.fromJson(Map<String, dynamic> json) =>
      _$BrowserManageResultDtoFromJson(json);

  @JsonKey(name: 'connected')
  final bool? connected;

  @JsonKey(name: 'url')
  final String? url;

  @JsonKey(name: 'messages')
  final List<String>? messages;

  Map<String, dynamic> toJson() => _$BrowserManageResultDtoToJson(this);

  BrowserStatus toDomain() {
    return BrowserStatus(
      connected: connected ?? false,
      url: url,
      messages: messages ?? const <String>[],
    );
  }
}

/// Wire DTO for `preview.restart` result (immediate: the agent runs in the
/// background).
@JsonSerializable()
class PreviewRestartResultDto {
  const PreviewRestartResultDto({this.taskId});

  factory PreviewRestartResultDto.fromJson(Map<String, dynamic> json) =>
      _$PreviewRestartResultDtoFromJson(json);

  @JsonKey(name: 'task_id')
  final String? taskId;

  Map<String, dynamic> toJson() => _$PreviewRestartResultDtoToJson(this);

  String toDomain() {
    return taskId ?? '';
  }
}
