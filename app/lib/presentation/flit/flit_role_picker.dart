/// Switching a session's role: the picker, the /role composer command, and
/// the divider the chat shows where the role changed.
library;

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The status strip's role button.
const Key flitRoleButtonKey = Key('flit_role');

/// One row of the picker; its key is this plus the role name ('' = none).
const String flitRoleItemKeyPrefix = 'flit_role_item_';

/// A role divider in the chat; its key is this plus the event's seq.
const String flitRoleMarkerKeyPrefix = 'flit_role_marker_';

/// The composer command, offered in the slash menu with the skills.
const String flitRoleCommand = 'role';
const FlitSkill flitRoleSkill = FlitSkill(
  name: flitRoleCommand,
  description:
      "Switch this session's role from the next model call "
      '(/role name, or /role to pick)',
  source: 'flit',
);

/// The role named by a "/role ..." message ('' when it names none, which
/// opens the picker), or null when [text] isn't one.
String? flitRoleCommandArg(String text) {
  final m = RegExp(r'^/role(?:\s+(\S*))?\s*$').firstMatch(text.trim());
  if (m == null) {
    return null;
  }
  return m.group(1) ?? '';
}

/// Lets the user pick a role for the session. Returns the role name ('' for
/// none), or null if dismissed.
Future<String?> showFlitRolePicker(
  BuildContext context, {
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FlitRolePicker(current: current),
  );
}

class FlitRolePicker extends ConsumerWidget {
  const FlitRolePicker({required this.current, super.key});

  /// The session's role now; '' for none.
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(flitRolesProvider);
    final theme = Theme.of(context);
    Widget row({
      required String name,
      required String title,
      String subtitle = '',
      bool enabled = true,
    }) {
      final selected = name == current;
      return ListTile(
        key: Key('$flitRoleItemKeyPrefix$name'),
        enabled: enabled,
        selected: selected,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(title),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.of(context).pop(name),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Role', style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Applies from the next model call. The model and effort '
                "follow the role's defaults unless you changed them.",
                style: theme.textTheme.bodySmall,
              ),
            ),
            row(name: '', title: 'None'),
            ...switch (roles) {
              AsyncData(:final value) => <Widget>[
                for (final r in value)
                  row(
                    name: r.name,
                    title: r.builtin ? '${r.name} (built-in)' : r.name,
                    subtitle: r.error.isNotEmpty ? r.error : r.description,
                    enabled: r.error.isEmpty,
                  ),
              ],
              AsyncError(:final error) => <Widget>[
                ListTile(title: Text('Could not list roles: $error')),
              ],
              _ => const <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

/// The divider where the session's role changed.
class FlitRoleMarkerView extends StatelessWidget {
  const FlitRoleMarkerView({required this.marker, super.key});

  final FlitRoleMarker marker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outline;
    final text = marker.role.isEmpty
        ? 'Cleared role ${marker.previousRole}'.trimRight()
        : 'Switched role to ${marker.role}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.badge_outlined, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
}
