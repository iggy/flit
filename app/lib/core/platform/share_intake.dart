/// Shares from other apps on Android. The app is a target for plain-text
/// shares (ACTION_SEND text/plain, see AndroidManifest.xml); MainActivity
/// holds the latest one and exposes it on the "flit/share" channel:
/// `take` returns `{text, subject}` (or null) and clears it, and the
/// activity calls `available` when a share arrives while running.
///
/// Other platforms have no share target (iOS would need a Share Extension),
/// so there this never yields anything.
library;

import 'dart:async';

import 'package:flit/domain/models/shared_content.dart';
import 'package:flit/domain/repositories/share_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// [ShareSource] backed by MainActivity's "flit/share" channel.
final class MethodChannelShareSource implements ShareSource {
  MethodChannelShareSource({
    this._channel = const MethodChannel('flit/share'),
    bool? supported,
  }) : _supported =
           supported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (_supported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'available') {
          _arrivals.add(null);
        }
      });
    }
  }

  final MethodChannel _channel;
  final bool _supported;
  final StreamController<void> _arrivals = StreamController<void>.broadcast();

  @override
  Stream<void> get arrivals => _arrivals.stream;

  @override
  Future<SharedContent?> take() async {
    if (!_supported) {
      return null;
    }
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('take');
      if (raw == null) {
        return null;
      }
      final content = SharedContent(
        text: raw['text'] is String ? raw['text']! as String : '',
        subject: raw['subject'] is String ? raw['subject']! as String : '',
      );
      return content.isEmpty ? null : content;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
