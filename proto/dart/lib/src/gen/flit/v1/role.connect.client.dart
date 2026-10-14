//
//  Generated code. Do not modify.
//  source: flit/v1/role.proto
//

import "package:connectrpc/connect.dart" as connect;
import "role.pb.dart" as flitv1role;
import "role.connect.spec.dart" as specs;

/// RoleService lists roles. A role is a Markdown file with YAML frontmatter
/// in the server's roles directory: the body is added to the system prompt,
/// and the frontmatter sets a default model and effort, a memory file, and
/// per-task models. A session picks its role when it is created.
extension type RoleServiceClient (connect.Transport _transport) {
  Future<flitv1role.ListRolesResponse> listRoles(
    flitv1role.ListRolesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.RoleService.listRoles,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
