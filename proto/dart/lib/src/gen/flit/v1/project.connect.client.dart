//
//  Generated code. Do not modify.
//  source: flit/v1/project.proto
//

import "package:connectrpc/connect.dart" as connect;
import "project.pb.dart" as flitv1project;
import "project.connect.spec.dart" as specs;

/// ProjectService manages projects. A project groups sessions and usually
/// points at a directory on the server, which new sessions in it work in.
/// Every team starts with a project called "Scratch" that has no directory.
extension type ProjectServiceClient (connect.Transport _transport) {
  Future<flitv1project.ListProjectsResponse> listProjects(
    flitv1project.ListProjectsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ProjectService.listProjects,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// CreateProject adds a project for a directory on the server.
  Future<flitv1project.CreateProjectResponse> createProject(
    flitv1project.CreateProjectRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ProjectService.createProject,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetProjectExport includes or excludes a project's sessions from
  /// "flit export". Projects are included by default.
  Future<flitv1project.SetProjectExportResponse> setProjectExport(
    flitv1project.SetProjectExportRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ProjectService.setProjectExport,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
