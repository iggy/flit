// P9-05: DTO→domain mapping for browser.manage and preview.restart results.
// Defensive parsing: partial/empty payloads map without throwing.

import 'package:flit/data/dto/browser_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserManageResultDto', () {
    test('fromJson parses full result with connected, url, and messages', () {
      final json = <String, dynamic>{
        'connected': true,
        'url': 'ws://localhost:9222/devtools/browser/abc',
        'messages': <String>['Launching browser', 'Connected'],
      };

      final dto = BrowserManageResultDto.fromJson(json);

      expect(dto.connected, true);
      expect(dto.url, 'ws://localhost:9222/devtools/browser/abc');
      expect(dto.messages, <String>['Launching browser', 'Connected']);
    });

    test('fromJson parses connected: false with no url', () {
      final json = <String, dynamic>{'connected': false};

      final dto = BrowserManageResultDto.fromJson(json);

      expect(dto.connected, false);
      expect(dto.url, isNull);
      expect(dto.messages, isNull);
    });

    test('fromJson handles missing connected field (defaults to null)', () {
      final json = <String, dynamic>{
        'url': 'ws://localhost:9222/devtools/browser/xyz',
      };

      final dto = BrowserManageResultDto.fromJson(json);

      expect(dto.connected, isNull);
      expect(dto.url, 'ws://localhost:9222/devtools/browser/xyz');
    });

    test('fromJson handles empty json (all fields null)', () {
      final json = <String, dynamic>{};

      final dto = BrowserManageResultDto.fromJson(json);

      expect(dto.connected, isNull);
      expect(dto.url, isNull);
      expect(dto.messages, isNull);
    });

    test('toDomain defaults connected to false when null', () {
      final dto = BrowserManageResultDto(
        connected: null,
        url: null,
        messages: null,
      );

      final domain = dto.toDomain();

      expect(domain.connected, false);
      expect(domain.url, isNull);
      expect(domain.messages, isEmpty);
    });

    test('toDomain defaults messages to empty list when null', () {
      final dto = BrowserManageResultDto(
        connected: true,
        url: 'ws://localhost:9222/devtools/browser/foo',
        messages: null,
      );

      final domain = dto.toDomain();

      expect(domain.connected, true);
      expect(domain.url, 'ws://localhost:9222/devtools/browser/foo');
      expect(domain.messages, isEmpty);
    });

    test('toDomain preserves all fields when present', () {
      final dto = BrowserManageResultDto(
        connected: false,
        url: 'ws://localhost:9222/devtools/browser/bar',
        messages: const <String>['Error: timeout', 'Retry failed'],
      );

      final domain = dto.toDomain();

      expect(domain.connected, false);
      expect(domain.url, 'ws://localhost:9222/devtools/browser/bar');
      expect(domain.messages, <String>['Error: timeout', 'Retry failed']);
    });
  });

  group('PreviewRestartResultDto', () {
    test('fromJson parses task_id', () {
      final json = <String, dynamic>{'task_id': 'preview_abc123'};

      final dto = PreviewRestartResultDto.fromJson(json);

      expect(dto.taskId, 'preview_abc123');
    });

    test('fromJson handles missing task_id (null)', () {
      final json = <String, dynamic>{};

      final dto = PreviewRestartResultDto.fromJson(json);

      expect(dto.taskId, isNull);
    });

    test('toDomain defaults to empty string when taskId is null', () {
      final dto = PreviewRestartResultDto(taskId: null);

      final domain = dto.toDomain();

      expect(domain, '');
    });

    test('toDomain preserves taskId when present', () {
      final dto = PreviewRestartResultDto(taskId: 'preview_xyz789');

      final domain = dto.toDomain();

      expect(domain, 'preview_xyz789');
    });
  });
}
