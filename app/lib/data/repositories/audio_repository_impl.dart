import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/domain/repositories/audio_repository.dart';

/// [AudioRepository] over the gateway's released `/api/audio/*` routes
/// (same contract the Hermes desktop app uses):
///
/// - `POST /api/audio/transcribe` — `{data_url, mime_type}` → transcript;
/// - `POST /api/audio/speak` — `{text}` → base64 `data_url` audio.
///
/// Both ride the authenticated [GatewayRestClient] (token header / session
/// cookies / Bearer), so remote gateways work identically to loopback ones.
final class RestAudioRepository implements AudioRepository {
  RestAudioRepository(this._client);

  final GatewayRestClient _client;

  /// Transcription blocks on a provider STT round-trip; long clips plus a
  /// remote provider regularly exceed dio's default receive timeout (mirrors
  /// the desktop's scaled timeout).
  static const Duration _audioTimeout = Duration(minutes: 3);

  /// The auth-wired dio instance. [GatewayRestClient] keeps its dio private,
  /// so the repository goes through this public accessor added there.
  Dio get _dio => _client.dioForFeatureCalls;

  @override
  Future<AudioTranscription> transcribe({
    required String dataUrl,
    String? mimeType,
  }) async {
    final body = await _post(
      '/api/audio/transcribe',
      data: <String, String?>{'data_url': dataUrl, 'mime_type': mimeType},
      receiveTimeout: _audioTimeout * (dataUrl.length ~/ 20000 + 1).clamp(1, 5),
    );
    if (body is! Map) {
      throw const GatewayParseException(
        'POST /api/audio/transcribe returned an unexpected body.',
      );
    }
    // The route maps provider "empty transcript" errors to ok=true + "" —
    // silence is a normal voice-loop outcome, not a failure.
    return AudioTranscription(
      transcript: (body['transcript'] as String? ?? '').trim(),
      provider: body['provider'] as String?,
    );
  }

  @override
  Future<SpeechAudio> speak(String text) async {
    final body = await _post(
      '/api/audio/speak',
      data: <String, String>{'text': text},
      receiveTimeout: _audioTimeout,
    );
    if (body is! Map) {
      throw const GatewayParseException(
        'POST /api/audio/speak returned an unexpected body.',
      );
    }
    if (body['ok'] != true) {
      throw GatewayNetworkException(
        (body['error'] as String?) ?? 'Speech synthesis failed.',
      );
    }
    final dataUrl = body['data_url'] as String?;
    if (dataUrl == null || !dataUrl.startsWith('data:')) {
      throw const GatewayParseException(
        'POST /api/audio/speak returned no audio payload.',
      );
    }
    return SpeechAudio(bytes: _decodeDataAudio(dataUrl), mimeType: _dataMime(dataUrl));
  }

  @override
  Future<bool> audioRoutesAvailable() async {
    try {
      await _client.getJson('/api/audio/elevenlabs/voices');
      return true;
    } on GatewayException catch (error) {
      // A missing route on old gateways answers 404; anything else
      // (network down, auth expired) must not permanently hide voice —
      // report unknown as available so failures surface at use time.
      return error is! GatewayParseException && !_isNotFound(error);
    }
  }

  bool _isNotFound(GatewayException error) =>
      error.cause is DioException &&
      (error.cause as DioException).response?.statusCode == 404;

  Future<dynamic> _post(
    String path, {
    required Object data,
    required Duration receiveTimeout,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        options: Options(receiveTimeout: receiveTimeout),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  /// Local copy of the client's dio→typed-error mapping (the private one in
  /// [GatewayRestClient] is not reachable from here); messages stay redacted.
  GatewayException _mapDioException(DioException error) {
    final url = redactUrl(error.requestOptions.uri.toString());
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return GatewayAuthException(
        'Gateway rejected the audio request (HTTP $statusCode, $url).',
        cause: error,
      );
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return GatewayTimeoutException(
          'Timed out talking to the gateway ($url).',
          cause: error,
        );
      case DioExceptionType.badResponse:
        return GatewayNetworkException(
          'Audio request failed with HTTP $statusCode ($url).',
          cause: error,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return GatewayNetworkException(
          'Could not reach the gateway ($url).',
          cause: error,
        );
    }
  }

  static Uint8List _decodeDataAudio(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    if (comma < 0 || !dataUrl.substring(0, comma).contains(';base64')) {
      throw const GatewayParseException(
        'Speech audio payload was not a base64 data URL.',
      );
    }
    try {
      return base64Decode(dataUrl.substring(comma + 1));
    } on FormatException catch (error) {
      throw GatewayParseException(
        'Speech audio payload was not valid base64.',
        cause: error,
      );
    } on ArgumentError catch (error) {
      throw GatewayParseException(
        'Speech audio payload was not valid base64.',
        cause: error,
      );
    }
  }

  static String _dataMime(String dataUrl) {
    final header = dataUrl.substring(0, dataUrl.indexOf(','));
    final mime = header.substring(5).split(';').first;
    return mime.isEmpty ? 'audio/mpeg' : mime;
  }
}
