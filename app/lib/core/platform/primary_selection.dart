/// The Linux PRIMARY selection: the text you last selected anywhere, which
/// middle-click pastes. Flutter has no API for it, so the Linux runner
/// exposes it on the "flit/primary_selection" channel (see
/// linux/runner/my_application.cc). Elsewhere it doesn't exist.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('flit/primary_selection');

/// Whether this platform has a PRIMARY selection.
bool get hasPrimarySelection =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

/// The PRIMARY selection's text, or null if there is none (or the platform
/// has no PRIMARY selection).
Future<String?> readPrimarySelection() async {
  if (!hasPrimarySelection) {
    return null;
  }
  try {
    return await _channel.invokeMethod<String>('get');
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

/// Makes [text] the PRIMARY selection, so middle-click pastes it in other
/// apps. No-op where there is no PRIMARY selection.
Future<void> writePrimarySelection(String text) async {
  if (!hasPrimarySelection || text.isEmpty) {
    return;
  }
  try {
    await _channel.invokeMethod<void>('set', text);
  } on PlatformException {
    // Best effort.
  } on MissingPluginException {
    // Best effort.
  }
}
