// P7-05 rework acceptance: RestAudioRepository against a fake Dio adapter.
// Asserts the EXACT route paths, body shapes (data_url + mime_type / text),
// response parsing, and the 404-based capability probe.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/audio_repository_impl.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dio adapter answering from a canned handler; records every request.
final class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  GatewayRestClient clientWith(FakeAdapter adapter) {
    return GatewayRestClient(
      ConnectionConfig(
        baseUrl: 'https://gw.example',
        authMode: AuthMode.token,
        token: 'tok',
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );
  }

  test('transcribe posts the data URL and parses the transcript', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'ok': true,
          'transcript': '  hello there  ',
          'provider': 'whisper',
        }),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      ),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    final result = await repository.transcribe(
      dataUrl: 'data:audio/wav;base64,AAAA',
      mimeType: 'audio/wav',
    );

    expect(adapter.requests.single.path, '/api/audio/transcribe');
    expect(adapter.requests.single.data, <String, String?>{
      'data_url': 'data:audio/wav;base64,AAAA',
      'mime_type': 'audio/wav',
    });
    expect(result.transcript, 'hello there');
    expect(result.provider, 'whisper');
  });

  test('empty transcript is silence, not failure', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'ok': true, 'transcript': ''}),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      ),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    final result = await repository.transcribe(dataUrl: 'data:audio/wav;base64,');

    expect(result.transcript, isEmpty);
  });

  test('transcribe maps HTTP errors to typed gateway errors', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString('nope', 400),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    await expectLater(
      repository.transcribe(dataUrl: 'data:audio/wav;base64,AAAA'),
      throwsA(isA<GatewayException>()),
    );
  });

  test('speak decodes the base64 data URL payload', () async {
    final audioBytes = <int>[1, 2, 3, 4];
    final dataUrl =
        'data:audio/mpeg;base64,${base64Encode(audioBytes)}';
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'ok': true,
          'data_url': dataUrl,
          'mime_type': 'audio/mpeg',
          'provider': 'edge',
        }),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      ),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    final result = await repository.speak('hello');

    expect(adapter.requests.single.path, '/api/audio/speak');
    expect(adapter.requests.single.data, <String, String>{'text': 'hello'});
    expect(result.bytes, audioBytes);
    expect(result.mimeType, 'audio/mpeg');
  });

  test('speak surfaces a provider failure as a network error', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'detail': 'Speech synthesis failed'}),
        400,
      ),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    await expectLater(repository.speak('hello'), throwsA(isA<GatewayException>()));
  });

  test('audioRoutesAvailable is true when the routes exist', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'available': false, 'voices': <String>[]}),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      ),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    expect(await repository.audioRoutesAvailable(), isTrue);
  });

  test('audioRoutesAvailable is false on 404 (old gateways)', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString('not found', 404),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    expect(await repository.audioRoutesAvailable(), isFalse);
  });

  test('audioRoutesAvailable stays true on transient failures', () async {
    final adapter = FakeAdapter(
      (options) => ResponseBody.fromString('server exploded', 500),
    );
    final repository = RestAudioRepository(clientWith(adapter));

    // Network/auth trouble must not permanently hide voice — surface at
    // use time instead.
    expect(await repository.audioRoutesAvailable(), isTrue);
  });
}
