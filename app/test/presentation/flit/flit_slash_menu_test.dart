import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/flit/flit_slash_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<FlitSkill> _skills = <FlitSkill>[
  FlitSkill(name: 'init', description: 'Write AGENTS.md', source: 'built-in'),
  FlitSkill(name: 'deploy', description: 'Deploy it', source: 'global'),
];

void main() {
  test('matches a slash prefix until the name is complete', () {
    List<String> names(String text) =>
        flitSlashMatches(text, _skills).map((s) => s.name).toList();
    expect(names('/'), <String>['init', 'deploy']);
    expect(names('/in'), <String>['init']);
    expect(names('/init'), isEmpty);
    expect(names('/init focus on tests'), isEmpty);
    expect(names('hello /in'), isEmpty);
    expect(names(''), isEmpty);
  });

  testWidgets('picking a command fills it in', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              FlitSlashMenu(controller: controller, skills: _skills),
              TextField(controller: controller),
            ],
          ),
        ),
      ),
    );
    expect(find.text('/init'), findsNothing);
    await tester.enterText(find.byType(TextField), '/i');
    await tester.pump();
    expect(find.text('/init'), findsOneWidget);
    expect(find.text('/deploy'), findsNothing);
    await tester.tap(find.byKey(const Key('${flitSlashItemKeyPrefix}init')));
    await tester.pump();
    expect(controller.text, '/init ');
    expect(controller.selection.baseOffset, 6);
    expect(find.text('/init'), findsNothing);
  });
}
