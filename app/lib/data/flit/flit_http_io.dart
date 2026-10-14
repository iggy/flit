import 'dart:io' as io;

import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/io.dart' as connect_io;

/// The Connect HTTP client on platforms with `dart:io` (mobile, desktop).
/// HTTP/1.1 is enough: flit only uses unary and server-streaming calls.
connect.HttpClient createFlitHttpClient() {
  final client = io.HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 30);
  return connect_io.createHttpClient(client);
}
