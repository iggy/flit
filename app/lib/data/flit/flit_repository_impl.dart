import 'dart:async';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flit/data/flit/flit_errors.dart';
import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit_api/flit_api.dart' as pb;

/// [FlitRepository] over a Connect transport.
final class FlitRepositoryImpl implements FlitRepository {
  FlitRepositoryImpl(connect.Transport transport)
    : _sessions = pb.SessionServiceClient(transport);

  final pb.SessionServiceClient _sessions;

  /// Page size for [listSessions]; it fetches every page.
  static const int _pageSize = 200;

  @override
  Future<List<FlitSession>> listSessions() {
    return flitCall(() async {
      final out = <FlitSession>[];
      var token = '';
      do {
        final res = await _sessions.listSessions(
          pb.ListSessionsRequest(pageSize: _pageSize, pageToken: token),
        );
        out.addAll(res.sessions.map(sessionFromProto));
        token = res.nextPageToken;
      } while (token.isNotEmpty);
      return out;
    });
  }

  @override
  Future<FlitSession> createSession({
    required String workingDir,
    String title = '',
    String provider = '',
    String model = '',
  }) {
    return flitCall(() async {
      final res = await _sessions.createSession(
        pb.CreateSessionRequest(
          workingDir: workingDir,
          title: title,
          provider: provider,
          model: model,
        ),
      );
      return sessionFromProto(res.session);
    });
  }

  @override
  Future<FlitSession> getSession(String id) {
    return flitCall(() async {
      final res = await _sessions.getSession(
        pb.GetSessionRequest(sessionId: id),
      );
      return sessionFromProto(res.session);
    });
  }

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) {
    // To stop, abort the request rather than cancelling the Connect stream:
    // its async* generators only notice a cancel at the next event, and an
    // idle session may never send one. The aborted stream then ends with a
    // "canceled" error, which is ours to swallow, so the subscription stays
    // open until that arrives instead of being cancelled.
    final signal = connect.CancelableSignal();
    var stopped = false;
    late final StreamController<FlitEvent> controller;
    controller = StreamController<FlitEvent>(
      onListen: () {
        _sessions
            .attach(
              pb.AttachRequest(sessionId: sessionId, fromSeq: Int64(fromSeq)),
              signal: signal,
            )
            .listen(
              (res) {
                if (!stopped) {
                  controller.add(eventFromProto(res.event));
                }
              },
              onError: (Object error, StackTrace stack) {
                if (!stopped) {
                  controller.addError(flitError(error), stack);
                }
              },
              onDone: () {
                if (!stopped) {
                  unawaited(controller.close());
                }
              },
            );
      },
      onCancel: () {
        stopped = true;
        signal.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> send(String sessionId, String text) {
    return flitCall(
      () => _sessions.send(pb.SendRequest(sessionId: sessionId, text: text)),
    );
  }

  @override
  Future<bool> interrupt(String sessionId) {
    return flitCall(() async {
      final res = await _sessions.interrupt(
        pb.InterruptRequest(sessionId: sessionId),
      );
      return res.interrupted;
    });
  }

  @override
  Future<void> answerPrompt(
    String sessionId,
    String promptId, {
    required bool allow,
    String client = '',
  }) {
    return flitCall(
      () => _sessions.answerPrompt(
        pb.AnswerPromptRequest(
          sessionId: sessionId,
          promptId: promptId,
          decision: allow
              ? pb.PromptDecision.PROMPT_DECISION_ALLOW
              : pb.PromptDecision.PROMPT_DECISION_DENY,
          client: client,
        ),
      ),
    );
  }

  @override
  Future<FlitSession> setModel(
    String sessionId, {
    required String provider,
    required String model,
  }) {
    return flitCall(() async {
      final res = await _sessions.setModel(
        pb.SetModelRequest(
          sessionId: sessionId,
          provider: provider,
          model: model,
        ),
      );
      return sessionFromProto(res.session);
    });
  }
}
