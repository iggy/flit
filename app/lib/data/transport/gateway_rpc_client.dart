/// JSON-RPC 2.0 over WebSocket client for the Hermes gateway.
///
/// Port of the attach-mode parts of `ui-tui/src/gatewayClient.ts`, grounded
/// in docs/reference/01-gateway-protocol.md:
/// - §3 newline-delimited framing; multiple frames per WS message; routing.
/// - §4 connect handshake: the first event is `gateway.ready`; only then is
///   the client ready.
/// - §5 delta coalescing is handled server-side; ordering is preserved.
/// - §10 reconnect is client-driven: exponential backoff; in-flight requests
///   are rejected on transport swap.
/// - §11 long handlers exist → default per-request timeout is 120s.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flit/core/errors/gateway_error.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connection lifecycle (protocol §4, §10).
enum GatewayConnectionState {
  /// Initial connect in progress (socket opening, awaiting `gateway.ready`).
  connecting,

  /// `gateway.ready` received; requests may be sent.
  ready,

  /// The transport dropped after being ready; backoff reconnect in progress.
  reconnecting,

  /// Terminal: closed by the user, or failed before ever becoming ready
  /// (e.g. a 4401/4403 auth rejection — protocol §2.3).
  closed,
}

/// One server-pushed event frame (`method:"event"`, protocol §3c):
/// `{type, session_id, payload}` from `params`.
final class GatewayEvent {
  const GatewayEvent({
    required this.type,
    required this.sessionId,
    required this.payload,
  });

  /// `params.type`, e.g. `message.delta`, `gateway.ready`.
  final String type;

  /// `params.session_id` — the short live session id. Absent on
  /// `gateway.ready` (protocol §4).
  final String? sessionId;

  /// `params.payload`; empty map when the frame carries none.
  final Map<String, dynamic> payload;

  @override
  String toString() =>
      'GatewayEvent(type: $type, sessionId: $sessionId, '
      'payload: {${payload.keys.join(', ')}})';
}

/// Factory for the underlying string channel. Injectable for tests; the
/// default wraps `WebSocketChannel.connect`.
typedef GatewayChannelFactory = StreamChannel<String> Function(Uri uri);

/// The gateway's app-specific WS close codes (protocol §2.3).
const int kGatewayCloseBadCredential = 4401;
const int kGatewayCloseForbidden = 4403;

/// Attach-mode JSON-RPC client. One instance per gateway connection.
///
/// Not safe to reuse after [close]. Reconnect after a drop is automatic
/// (backoff); the app layer is notified via [connection] and is responsible
/// for `session.resume` afterwards (protocol §10).
class GatewayRpcClient {
  GatewayRpcClient({
    this.requestTimeout = const Duration(seconds: 120),
    this.handshakeTimeout = const Duration(seconds: 30),
    this.channelFactory,
  });

  /// Injectable transport (tests); defaults to `WebSocketChannel.connect`.
  final GatewayChannelFactory? channelFactory;

  /// Per-request timeout (long handlers exist — protocol §11).
  final Duration requestTimeout;

  /// Max wait for `gateway.ready` after opening a socket.
  final Duration handshakeTimeout;

  final StreamController<GatewayConnectionState> _connectionController =
      StreamController<GatewayConnectionState>.broadcast();
  final StreamController<GatewayEvent> _eventsController =
      StreamController<GatewayEvent>.broadcast();

  final Map<String, Completer<Map<String, dynamic>>> _pending =
      <String, Completer<Map<String, dynamic>>>{};
  final Map<String, Timer> _timeoutTimers = <String, Timer>{};

  StreamChannel<String>? _channel;
  StreamSubscription<String>? _channelSubscription;
  WebSocketChannel? _wsChannel; // kept for close-code access (default factory)
  Timer? _handshakeTimer;
  Timer? _reconnectTimer;
  Completer<void>? _readyCompleter;

  Future<Uri> Function()? _wsUriFactory;
  int _nextRequestId = 0;
  int _reconnectAttempts = 0;
  bool _closedByUser = false;
  bool _sawReady = false;

  /// Guards against handling the same channel failure twice (onError then
  /// onDone fire for one drop). Reset per channel open.
  bool _dropHandled = false;
  GatewayConnectionState _state = GatewayConnectionState.closed;
  Map<String, dynamic>? _skin;

  /// Emits state changes: connecting → ready → (reconnecting → ready)* →
  /// closed. Read [state] for the current value when subscribing late.
  Stream<GatewayConnectionState> get connection => _connectionController.stream;

  /// All server-pushed events (broadcast). Includes `gateway.ready`.
  Stream<GatewayEvent> get events => _eventsController.stream;

  /// The current connection state.
  GatewayConnectionState get state => _state;

  /// The skin dict from the `gateway.ready` payload (protocol §4); null
  /// until the first ready event. `{}` is a valid server-sent skin.
  Map<String, dynamic>? get skin => _skin;

  /// Open the socket and wait for `gateway.ready` (protocol §4).
  ///
  /// [wsUriFactory] is invoked on the initial connect AND on every reconnect
  /// attempt — gated-mode WS tickets are single-use, so each attempt mints a
  /// fresh one (protocol §2.2 step 5). A factory that throws
  /// [GatewayAuthException] is terminal (no retry): the session is dead.
  ///
  /// Completes normally once ready; completes with:
  /// - [GatewayAuthException] on a 4401/4403 close or a factory auth failure,
  /// - [GatewayNetworkException] if the socket fails before ready,
  /// - [GatewayTimeoutException] if `gateway.ready` never arrives.
  Future<void> connect(Future<Uri> Function() wsUriFactory) {
    if (_state != GatewayConnectionState.closed) {
      return Future<void>.error(
        const GatewayClosedException(
          'connect() called on an open/connecting client; close() first',
        ),
      );
    }
    _wsUriFactory = wsUriFactory;
    _closedByUser = false;
    _sawReady = false;
    _reconnectAttempts = 0;
    _readyCompleter = Completer<void>();
    unawaited(_openChannel());
    return _readyCompleter!.future;
  }

  /// Send a JSON-RPC request and await its result.
  ///
  /// Rejects with [GatewayClosedException] when not ready,
  /// [GatewayRpcException] on an error frame, [GatewayTimeoutException]
  /// after [requestTimeout] (long handlers exist — protocol §11).
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const <String, dynamic>{},
  ]) {
    if (_state != GatewayConnectionState.ready) {
      return Future<Map<String, dynamic>>.error(
        GatewayClosedException(
          'request("$method") while not ready (state: ${_state.name})',
        ),
      );
    }

    final id = 'r${++_nextRequestId}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _timeoutTimers[id] = Timer(requestTimeout, () {
      final pending = _pending.remove(id);
      _timeoutTimers.remove(id);
      if (pending != null && !pending.isCompleted) {
        pending.completeError(
          GatewayTimeoutException(
            '"$method" no response after ${requestTimeout.inSeconds}s',
          ),
        );
      }
    });

    try {
      _send(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      });
    } on Object catch (error) {
      _pending.remove(id);
      _timeoutTimers.remove(id)?.cancel();
      completer.completeError(
        GatewayClosedException('send failed for "$method"', cause: error),
      );
    }
    return completer.future;
  }

  /// Terminal close: cancels reconnects, rejects in-flight requests, closes
  /// the socket. The client cannot be reused after this.
  Future<void> close() async {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _handshakeTimer?.cancel();
    _rejectAllPending(
      const GatewayClosedException('client closed with requests in flight'),
    );
    if (!_readyCompleterFulfilled) {
      _readyCompleter?.completeError(
        const GatewayClosedException('client closed before gateway.ready'),
      );
    }
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      await _channel?.sink.close();
    } on Object {
      // Sink close on a broken transport can throw; closing is terminal anyway.
    }
    _channel = null;
    _wsChannel = null;
    _setState(GatewayConnectionState.closed);
  }

  // --------------------------------------------------------------------------

  bool get _readyCompleterFulfilled =>
      _readyCompleter == null || _readyCompleter!.isCompleted;

  Future<void> _openChannel() async {
    final factory = _wsUriFactory;
    if (factory == null) {
      return;
    }
    if (!_sawReady) {
      _setState(GatewayConnectionState.connecting);
    }
    _dropHandled = false;

    // Mint the URI for THIS attempt (single-use tickets — protocol §2.2).
    final Uri uri;
    try {
      uri = await factory();
    } on GatewayAuthException {
      _handleAuthFailure(null);
      return;
    } on Object catch (error) {
      _handleTransportFailure(
        GatewayNetworkException('could not prepare the WS URI', cause: error),
      );
      return;
    }
    // close() (or a failure above) may have run while the factory was async.
    if (_closedByUser || _dropHandled) {
      return;
    }

    final StreamChannel<String> channel;
    try {
      final factory = channelFactory;
      if (factory != null) {
        channel = factory(uri);
        _wsChannel = null;
      } else {
        final ws = WebSocketChannel.connect(uri);
        _wsChannel = ws;
        channel = ws.cast<String>();
      }
    } on Object catch (error) {
      _handleTransportFailure(
        GatewayNetworkException('socket open failed', cause: error),
      );
      return;
    }
    _channel = channel;

    _handshakeTimer = Timer(handshakeTimeout, () {
      // Connected(ish) but no gateway.ready — force the close path.
      unawaited(_channelSubscription?.cancel());
      unawaited(channel.sink.close());
      _handleTransportFailure(
        GatewayTimeoutException(
          'no gateway.ready within ${handshakeTimeout.inSeconds}s',
        ),
      );
    });

    _channelSubscription = channel.stream.listen(
      _onMessage,
      onError: (Object error) {
        _handleTransportFailure(
          GatewayNetworkException('socket error', cause: error),
        );
      },
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  void _send(Map<String, dynamic> frame) {
    _channel?.sink.add('${jsonEncode(frame)}\n');
  }

  /// Inbound text: possibly SEVERAL newline-delimited frames per WS message
  /// (protocol §3 gotcha, §5 coalescing). Split, decode, route.
  void _onMessage(String message) {
    for (final line in const LineSplitter().convert(message)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      Object? decoded;
      try {
        decoded = jsonDecode(trimmed);
      } on FormatException {
        continue; // unparseable line — drop; the server keeps the socket open
      }
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      _routeFrame(decoded);
    }
  }

  /// Routing rule (protocol §3): id match → resolve/reject a pending request;
  /// `method == "event"` → dispatch; anything else → drop.
  void _routeFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id != null) {
      final key = id.toString();
      final completer = _pending.remove(key);
      _timeoutTimers.remove(key)?.cancel();
      if (completer == null || completer.isCompleted) {
        return; // stray response id (protocol §3)
      }
      final error = frame['error'];
      if (error is Map) {
        final code = error['code'];
        final message = error['message'];
        completer.completeError(
          GatewayRpcException(
            code is int ? code : -1,
            message is String ? message : 'unknown rpc error',
          ),
        );
      } else {
        final result = frame['result'];
        completer.complete(
          result is Map<String, dynamic>
              ? result
              : <String, dynamic>{'value': result},
        );
      }
      return;
    }

    if (frame['method'] == 'event') {
      final params = frame['params'];
      if (params is! Map<String, dynamic>) {
        return;
      }
      final type = params['type'];
      if (type is! String) {
        return;
      }
      final payload = params['payload'];
      final payloadMap = payload is Map<String, dynamic>
          ? payload
          : <String, dynamic>{};
      final sessionId = params['session_id'];
      final event = GatewayEvent(
        type: type,
        sessionId: sessionId is String ? sessionId : null,
        payload: payloadMap,
      );
      if (type == 'gateway.ready') {
        _onReady(payloadMap);
      }
      if (!_eventsController.isClosed) {
        _eventsController.add(event);
      }
    }
    // else: unknown frame — drop (protocol §3).
  }

  void _onReady(Map<String, dynamic> skin) {
    _skin = skin;
    _sawReady = true;
    _reconnectAttempts = 0;
    _handshakeTimer?.cancel();
    _setState(GatewayConnectionState.ready);
    if (!_readyCompleterFulfilled) {
      _readyCompleter!.complete();
    }
  }

  void _onDone() {
    if (_state == GatewayConnectionState.closed || _dropHandled) {
      return; // close() path, or this drop was already handled via onError.
    }
    final closeCode = _wsChannel?.closeCode;
    if (closeCode != null &&
        (closeCode == kGatewayCloseBadCredential ||
            closeCode == kGatewayCloseForbidden)) {
      // Auth rejection (protocol §2.3) — never auto-retry a bad credential.
      _handleAuthFailure(closeCode);
      return;
    }
    _handleTransportFailure(
      GatewayNetworkException(
        'socket closed${closeCode != null ? ' (code $closeCode)' : ''}',
      ),
    );
  }

  void _handleAuthFailure(int? closeCode) {
    _dropHandled = true;
    _handshakeTimer?.cancel();
    _rejectAllPending(
      GatewayAuthException(
        'gateway rejected the connection${closeCode != null ? ' (close $closeCode)' : ''}',
        closeCode: closeCode,
      ),
    );
    if (!_readyCompleterFulfilled) {
      _readyCompleter!.completeError(
        GatewayAuthException(
          'gateway rejected the WebSocket credential'
          '${closeCode != null ? ' (close $closeCode)' : ''} — '
          'sign in again',
          closeCode: closeCode,
        ),
      );
    }
    _setState(GatewayConnectionState.closed);
  }

  /// Transport dropped (or failed pre-ready). Rejects in-flight requests,
  /// then either fails the initial [connect] future or starts backoff
  /// reconnect (protocol §10).
  void _handleTransportFailure(GatewayException error) {
    if (_state == GatewayConnectionState.closed || _dropHandled) {
      return;
    }
    _dropHandled = true;
    _handshakeTimer?.cancel();
    _rejectAllPending(
      const GatewayClosedException('transport dropped with requests in flight'),
    );
    if (!_closedByUser && !_sawReady && !_readyCompleterFulfilled) {
      // Initial connect failed — surface it; the UI decides about retrying.
      _readyCompleter!.completeError(error);
      _setState(GatewayConnectionState.closed);
      return;
    }
    if (_closedByUser) {
      _setState(GatewayConnectionState.closed);
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _setState(GatewayConnectionState.reconnecting);
    _reconnectAttempts++;
    final shift = _reconnectAttempts - 1;
    final millis = 500 * (1 << (shift > 6 ? 6 : shift)); // 0.5s → cap below
    final delay = Duration(milliseconds: millis > 30000 ? 30000 : millis);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_closedByUser) {
        unawaited(_channelSubscription?.cancel());
        unawaited(_openChannel());
      }
    });
  }

  void _rejectAllPending(GatewayException error) {
    final pending = _pending.values.toList();
    _pending.clear();
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
  }

  void _setState(GatewayConnectionState next) {
    if (_state == next || _connectionController.isClosed) {
      _state = next;
      return;
    }
    _state = next;
    _connectionController.add(next);
  }
}
