/// Connect transport to a flit server (flit.v1 over the Connect protocol,
/// binary protobuf). Every call carries the device token, except pairing.
library;

import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/protobuf.dart' as connect_pb;
import 'package:connectrpc/protocol/connect.dart' as protocol;
import 'package:flit/data/flit/flit_http_io.dart'
    if (dart.library.js_interop) 'package:flit/data/flit/flit_http_web.dart';

/// A transport for [baseUrl] (e.g. `https://flit.example.com`). With a
/// [token], every request sends `Authorization: Bearer <token>`.
connect.Transport createFlitTransport({
  required String baseUrl,
  String? token,
  connect.HttpClient? httpClient,
}) {
  return protocol.Transport(
    baseUrl: baseUrl,
    codec: const connect_pb.ProtoCodec(),
    httpClient: httpClient ?? createFlitHttpClient(),
    interceptors: <connect.Interceptor>[
      if (token != null && token.isNotEmpty) _bearer(token),
    ],
  );
}

connect.Interceptor _bearer(String token) {
  return <I extends Object, O extends Object>(connect.AnyFn<I, O> next) {
    return (connect.Request<I, O> request) {
      request.headers['authorization'] = 'Bearer $token';
      return next(request);
    };
  };
}
