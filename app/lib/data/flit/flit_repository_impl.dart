import 'dart:async';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flit/data/flit/flit_errors.dart';
import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_learning.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit_api/flit_api.dart' as pb;

/// [FlitRepository] over a Connect transport.
final class FlitRepositoryImpl implements FlitRepository {
  FlitRepositoryImpl(connect.Transport transport)
    : _sessions = pb.SessionServiceClient(transport),
      _models = pb.ModelServiceClient(transport),
      _roles = pb.RoleServiceClient(transport),
      _projects = pb.ProjectServiceClient(transport),
      _learning = pb.LearningServiceClient(transport);

  final pb.SessionServiceClient _sessions;
  final pb.ModelServiceClient _models;
  final pb.RoleServiceClient _roles;
  final pb.ProjectServiceClient _projects;
  final pb.LearningServiceClient _learning;

  /// Page size for [listSessions]; it fetches every page.
  static const int _pageSize = 200;

  @override
  Future<List<FlitSession>> listSessions({String? projectId}) {
    return flitCall(() async {
      final out = <FlitSession>[];
      var token = '';
      do {
        final res = await _sessions.listSessions(
          pb.ListSessionsRequest(
            pageSize: _pageSize,
            pageToken: token,
            projectId: projectId ?? '',
          ),
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
    String effort = '',
    String role = '',
    String projectId = '',
  }) {
    return flitCall(() async {
      final res = await _sessions.createSession(
        pb.CreateSessionRequest(
          workingDir: workingDir,
          title: title,
          provider: provider,
          model: model,
          effort: effort,
          role: role,
          projectId: projectId,
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
  Future<void> send(String sessionId, String text, {String client = ''}) {
    return flitCall(
      () => _sessions.send(
        pb.SendRequest(sessionId: sessionId, text: text, client: client),
      ),
    );
  }

  @override
  Future<void> editQueuedMessage(
    String sessionId,
    String queueId,
    String text,
  ) {
    return flitCall(
      () => _sessions.editQueuedMessage(
        pb.EditQueuedMessageRequest(
          sessionId: sessionId,
          queueId: queueId,
          text: text,
        ),
      ),
    );
  }

  @override
  Future<void> cancelQueuedMessage(String sessionId, String queueId) {
    return flitCall(
      () => _sessions.cancelQueuedMessage(
        pb.CancelQueuedMessageRequest(sessionId: sessionId, queueId: queueId),
      ),
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
  Future<void> endReasoning(String sessionId, {String client = ''}) {
    return flitCall(() async {
      await _sessions.endReasoning(
        pb.EndReasoningRequest(sessionId: sessionId, client: client),
      );
    });
  }

  @override
  Future<bool> compact(
    String sessionId, {
    String instructions = '',
    String client = '',
  }) {
    return flitCall(() async {
      final res = await _sessions.compact(
        pb.CompactRequest(
          sessionId: sessionId,
          instructions: instructions,
          client: client,
        ),
      );
      return res.queued;
    });
  }

  @override
  Future<void> retryModelCall(String sessionId) {
    return flitCall(() async {
      await _sessions.retryModelCall(
        pb.RetryModelCallRequest(sessionId: sessionId),
      );
    });
  }

  @override
  Future<void> retryFromMessage(
    String sessionId,
    String messageId, {
    String client = '',
  }) {
    return flitCall(() async {
      await _sessions.retryFromMessage(
        pb.RetryFromMessageRequest(
          sessionId: sessionId,
          messageId: messageId,
          client: client,
        ),
      );
    });
  }

  @override
  Future<void> editMessage(
    String sessionId,
    String messageId,
    String text, {
    String client = '',
  }) {
    return flitCall(() async {
      await _sessions.editMessage(
        pb.EditMessageRequest(
          sessionId: sessionId,
          messageId: messageId,
          text: text,
          client: client,
        ),
      );
    });
  }

  @override
  Future<void> switchBranch(
    String sessionId,
    String branchId, {
    String client = '',
  }) {
    return flitCall(() async {
      await _sessions.switchBranch(
        pb.SwitchBranchRequest(
          sessionId: sessionId,
          branchId: branchId,
          client: client,
        ),
      );
    });
  }

  @override
  Future<void> answerPrompt(
    String sessionId,
    String promptId, {
    required bool allow,
    bool forSession = false,
    String client = '',
  }) {
    return flitCall(
      () => _sessions.answerPrompt(
        pb.AnswerPromptRequest(
          sessionId: sessionId,
          promptId: promptId,
          decision: forSession
              ? pb.PromptDecision.PROMPT_DECISION_ALLOW_SESSION
              : allow
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

  @override
  Future<FlitSession> setEffort(String sessionId, String effort) {
    return flitCall(() async {
      final res = await _sessions.setEffort(
        pb.SetEffortRequest(sessionId: sessionId, effort: effort),
      );
      return sessionFromProto(res.session);
    });
  }

  @override
  Future<FlitSession> setYolo(String sessionId, {required bool yolo}) {
    return flitCall(() async {
      final res = await _sessions.setYolo(
        pb.SetYoloRequest(sessionId: sessionId, yolo: yolo),
      );
      return sessionFromProto(res.session);
    });
  }

  @override
  Future<List<FlitModel>> listModels() {
    return flitCall(() async {
      final res = await _models.listModels(pb.ListModelsRequest());
      return res.models.map(modelFromProto).toList();
    });
  }

  @override
  Future<List<FlitModel>> refreshModels() {
    return flitCall(() async {
      await _models.refresh(pb.RefreshRequest());
      final res = await _models.listModels(pb.ListModelsRequest());
      return res.models.map(modelFromProto).toList();
    });
  }

  @override
  Future<void> setFavorite(
    String provider,
    String model, {
    required bool favorite,
  }) {
    return flitCall(() async {
      await _models.setFavorite(
        pb.SetFavoriteRequest(
          provider: provider,
          model: model,
          favorite: favorite,
        ),
      );
    });
  }

  @override
  Future<FlitModel> setModelLoaded(
    String provider,
    String model, {
    required bool load,
  }) {
    return flitCall(() async {
      if (load) {
        final res = await _models.loadModel(
          pb.LoadModelRequest(provider: provider, model: model),
        );
        return modelFromProto(res.model);
      }
      final res = await _models.unloadModel(
        pb.UnloadModelRequest(provider: provider, model: model),
      );
      return modelFromProto(res.model);
    });
  }

  @override
  Future<List<FlitAgentRole>> listRoles() {
    return flitCall(() async {
      final res = await _roles.listRoles(pb.ListRolesRequest());
      return res.roles.map(roleFromProto).toList();
    });
  }

  @override
  Future<List<FlitProject>> listProjects() {
    return flitCall(() async {
      final res = await _projects.listProjects(pb.ListProjectsRequest());
      return res.projects.map(projectFromProto).toList();
    });
  }

  @override
  Future<FlitProject> createProject({
    required String directory,
    String name = '',
  }) {
    return flitCall(() async {
      final res = await _projects.createProject(
        pb.CreateProjectRequest(directory: directory, name: name),
      );
      return projectFromProto(res.project);
    });
  }

  @override
  Future<FlitSession> moveSession(String sessionId, String projectId) {
    return flitCall(() async {
      final res = await _sessions.moveSession(
        pb.MoveSessionRequest(sessionId: sessionId, projectId: projectId),
      );
      return sessionFromProto(res.session);
    });
  }

  @override
  Future<void> rate(
    String sessionId, {
    required FlitRatingTarget target,
    required bool good,
    String messageId = '',
    String note = '',
  }) {
    return flitCall(
      () => _sessions.rate(
        pb.RateRequest(
          sessionId: sessionId,
          target: target == FlitRatingTarget.model
              ? pb.RatingTarget.RATING_TARGET_MODEL
              : pb.RatingTarget.RATING_TARGET_TURN,
          rating: good ? pb.Rating.RATING_GOOD : pb.Rating.RATING_BAD,
          messageId: messageId,
          note: note,
        ),
      ),
    );
  }

  @override
  Future<List<FlitMcpServer>> listMcpServers(String sessionId) {
    return flitCall(() async {
      final res = await _sessions.listMcpServers(
        pb.ListMcpServersRequest(sessionId: sessionId),
      );
      return res.servers.map(mcpServerFromProto).toList();
    });
  }

  @override
  Future<FlitSession> setMcpServer(
    String sessionId,
    String server, {
    required bool enabled,
  }) {
    return flitCall(() async {
      final res = await _sessions.setMcpServer(
        pb.SetMcpServerRequest(
          sessionId: sessionId,
          server: server,
          enabled: enabled,
        ),
      );
      return sessionFromProto(res.session);
    });
  }

  @override
  Future<List<FlitSkill>> listSkills(String sessionId) {
    return flitCall(() async {
      final res = await _sessions.listSkills(
        pb.ListSkillsRequest(sessionId: sessionId),
      );
      return res.skills
          .map(
            (s) => FlitSkill(
              name: s.name,
              description: s.description,
              source: s.source,
            ),
          )
          .toList();
    });
  }

  @override
  Future<FlitProject> setProjectExport(
    String projectId, {
    required bool enabled,
  }) {
    return flitCall(() async {
      final res = await _projects.setProjectExport(
        pb.SetProjectExportRequest(projectId: projectId, enabled: enabled),
      );
      return projectFromProto(res.project);
    });
  }

  @override
  Future<FlitLearnResult> learn(String sessionId) {
    return flitCall(() async {
      final res = await _learning.learn(pb.LearnRequest(sessionId: sessionId));
      return FlitLearnResult(
        proposals: res.proposals.map(learnProposalFromProto).toList(),
        dropped: res.dropped.toList(),
        provider: res.provider,
        model: res.model,
      );
    });
  }

  @override
  Future<List<FlitLearnProposal>> listLearnProposals({
    String sessionId = '',
    bool includeDecided = false,
  }) {
    return flitCall(() async {
      final res = await _learning.listLearnProposals(
        pb.ListLearnProposalsRequest(
          sessionId: sessionId,
          includeDecided: includeDecided,
        ),
      );
      return res.proposals.map(learnProposalFromProto).toList();
    });
  }

  @override
  Future<FlitLearnProposal> acceptLearnProposal(String id, {String? text}) {
    return flitCall(() async {
      final req = pb.AcceptLearnProposalRequest(id: id);
      if (text != null) {
        req.text = text;
      }
      final res = await _learning.acceptLearnProposal(req);
      return learnProposalFromProto(res.proposal);
    });
  }

  @override
  Future<FlitLearnProposal> rejectLearnProposal(String id) {
    return flitCall(() async {
      final res = await _learning.rejectLearnProposal(
        pb.RejectLearnProposalRequest(id: id),
      );
      return learnProposalFromProto(res.proposal);
    });
  }
}
