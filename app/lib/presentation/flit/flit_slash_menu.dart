/// Slash commands in the composer: typing "/" lists the session's skills
/// (flit's own /init among them); picking one fills in "/name ". The
/// server tells the agent that a message starting with /name asks for that
/// skill.
library;

import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';

/// One suggestion row; its key is this plus the skill name.
const String flitSlashItemKeyPrefix = 'flit_slash_';

/// The skills matching a "/prefix" the user is typing, or none once there's
/// a space (or anything that isn't a skill name) after the slash.
List<FlitSkill> flitSlashMatches(String text, List<FlitSkill> skills) {
  final m = RegExp(r'^/([a-z0-9-]*)$').firstMatch(text);
  if (m == null) {
    return const <FlitSkill>[];
  }
  final prefix = m.group(1)!;
  return <FlitSkill>[
    for (final s in skills)
      if (s.name.startsWith(prefix) && s.name != prefix) s,
  ];
}

/// Shows the matching skills above the composer while a slash command is
/// being typed.
class FlitSlashMenu extends StatelessWidget {
  const FlitSlashMenu({
    required this.controller,
    required this.skills,
    super.key,
  });

  final TextEditingController controller;
  final List<FlitSkill> skills;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final matches = flitSlashMatches(value.text, skills);
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHigh,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  for (final s in matches)
                    ListTile(
                      key: Key('$flitSlashItemKeyPrefix${s.name}'),
                      dense: true,
                      title: Text('/${s.name}'),
                      subtitle: Text(
                        s.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        final text = '/${s.name} ';
                        controller.value = TextEditingValue(
                          text: text,
                          selection: TextSelection.collapsed(
                            offset: text.length,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
