import 'package:flit/data/dto/attachment_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/attachment.dart';
import 'package:flit/domain/repositories/attachment_repository.dart';

/// [AttachmentRepository] over [GatewayRpcClient.request] (ticket P7).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
final class AttachmentRepositoryImpl implements AttachmentRepository {
  const AttachmentRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<ImageAttachment> attachImageBytes(
    String sessionId, {
    required String contentBase64,
    String? filename,
    String? ext,
  }) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'content_base64': contentBase64,
      'filename': ?filename,
      'ext': ?ext,
    };
    final result = await _client.request('image.attach_bytes', params);
    final dto = ImageAttachDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<DetachResult> detachImage(String sessionId, String path) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'path': path,
    };
    final result = await _client.request('image.detach', params);
    final dto = DetachResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<PdfAttachment> attachPdf(
    String sessionId, {
    required String contentBase64,
    String? filename,
    int? firstPage,
    int? lastPage,
  }) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'content_base64': contentBase64,
      'filename': ?filename,
      'first_page': ?firstPage,
      'last_page': ?lastPage,
    };
    final result = await _client.request('pdf.attach', params);
    final dto = PdfAttachDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<FileAttachment> attachFile(
    String sessionId, {
    String? path,
    String? dataUrl,
    String? name,
  }) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'path': ?path,
      'data_url': ?dataUrl,
      'name': ?name,
    };
    final result = await _client.request('file.attach', params);
    final dto = FileAttachDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<DropDetection> detectDrop(String sessionId, String text) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'text': text,
    };
    final result = await _client.request('input.detect_drop', params);
    final dto = DropDetectionDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<ClipboardPasteResult> pasteClipboard(String sessionId) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
    };
    final result = await _client.request('clipboard.paste', params);
    final dto = ClipboardPasteDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<PasteCollapseResult> collapsePaste(String text) async {
    final params = <String, dynamic>{
      'text': text,
    };
    final result = await _client.request('paste.collapse', params);
    final dto = PasteCollapseDto.fromJson(result);
    return dto.toDomain();
  }
}
