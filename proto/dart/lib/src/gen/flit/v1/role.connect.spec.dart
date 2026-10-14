//
//  Generated code. Do not modify.
//  source: flit/v1/role.proto
//

import "package:connectrpc/connect.dart" as connect;
import "role.pb.dart" as flitv1role;

/// RoleService lists roles. A role is a Markdown file with YAML frontmatter
/// in the server's roles directory: the body is added to the system prompt,
/// and the frontmatter sets a default model and effort, a memory file, and
/// per-task models. A session picks its role when it is created.
abstract final class RoleService {
  /// Fully-qualified name of the RoleService service.
  static const name = 'flit.v1.RoleService';

  static const listRoles = connect.Spec(
    '/$name/ListRoles',
    connect.StreamType.unary,
    flitv1role.ListRolesRequest.new,
    flitv1role.ListRolesResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );
}
