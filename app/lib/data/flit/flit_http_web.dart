import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/web.dart' as connect_web;

/// The Connect HTTP client on the web (fetch).
connect.HttpClient createFlitHttpClient() => connect_web.createHttpClient();
