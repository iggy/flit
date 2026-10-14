//
//  Generated code. Do not modify.
//  source: flit/v1/project.proto
//

import "package:connectrpc/connect.dart" as connect;
import "project.pb.dart" as flitv1project;

/// ProjectService manages projects. A project groups sessions and usually
/// points at a directory on the server, which new sessions in it work in.
/// Every team starts with a project called "Scratch" that has no directory.
abstract final class ProjectService {
  /// Fully-qualified name of the ProjectService service.
  static const name = 'flit.v1.ProjectService';

  static const listProjects = connect.Spec(
    '/$name/ListProjects',
    connect.StreamType.unary,
    flitv1project.ListProjectsRequest.new,
    flitv1project.ListProjectsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// CreateProject adds a project for a directory on the server.
  static const createProject = connect.Spec(
    '/$name/CreateProject',
    connect.StreamType.unary,
    flitv1project.CreateProjectRequest.new,
    flitv1project.CreateProjectResponse.new,
  );
}
