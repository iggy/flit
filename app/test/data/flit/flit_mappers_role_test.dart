import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit_api/flit_api.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roles keep whether they are built in', () {
    final builtin = roleFromProto(
      pb.AgentRole(name: 'qa', description: 'QA engineer', builtin: true),
    );
    expect(builtin.name, 'qa');
    expect(builtin.description, 'QA engineer');
    expect(builtin.builtin, isTrue);
    expect(roleFromProto(pb.AgentRole(name: 'mine')).builtin, isFalse);
  });
}
