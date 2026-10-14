import 'dart:io' as io;

/// A default name for this device when pairing: the host name on desktop,
/// the platform on phones (their host names are meaningless).
String defaultFlitDeviceName() {
  if (io.Platform.isAndroid) {
    return 'Android phone';
  }
  if (io.Platform.isIOS) {
    return 'iPhone';
  }
  try {
    final host = io.Platform.localHostname;
    if (host.isNotEmpty) {
      return host;
    }
  } on Object {
    // Fall through.
  }
  return io.Platform.operatingSystem;
}
