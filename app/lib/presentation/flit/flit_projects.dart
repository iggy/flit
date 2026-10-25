/// Project switching for the flit sessions list: a menu of projects with
/// "All projects" and "New project…", the new-project dialog, the
/// move-session dialog, and a project's options and context menu.
library;

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/flit/flit_new_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _newProject = '\u0000new';
const String _allProjects = '\u0000all';

/// The app bar title of the sessions list: the selected project, tap to
/// switch.
class FlitProjectSwitcher extends ConsumerWidget {
  const FlitProjectSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(flitSelectedProjectProvider);
    final projects =
        ref.watch(flitProjectsProvider).value ?? const <FlitProject>[];
    String label = 'All projects';
    for (final p in projects) {
      if (p.id == selected) {
        label = p.name;
      }
    }
    return PopupMenuButton<String>(
      tooltip: 'Switch project',
      onSelected: (value) async {
        if (value == _newProject) {
          final created = await showNewProjectDialog(context, ref);
          if (created != null) {
            ref.read(flitSelectedProjectProvider.notifier).select(created.id);
          }
          return;
        }
        ref
            .read(flitSelectedProjectProvider.notifier)
            .select(value == _allProjects ? null : value);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        CheckedPopupMenuItem<String>(
          value: _allProjects,
          checked: selected == null,
          child: const Text('All projects'),
        ),
        const PopupMenuDivider(),
        for (final p in projects)
          CheckedPopupMenuItem<String>(
            value: p.id,
            checked: p.id == selected,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(p.name),
              subtitle: Text(
                p.directory.isEmpty
                    ? '${p.sessionCount} sessions'
                    : '${p.directory} · ${p.sessionCount} sessions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _newProject,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.create_new_folder_outlined),
            title: Text('New project…'),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

/// Asks for a directory (and optional name) and creates a project.
Future<FlitProject?> showNewProjectDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final input = await showDialog<(String, String)>(
    context: context,
    builder: (_) => const _NewProjectDialog(),
  );
  final repository = ref.read(flitRepositoryProvider);
  if (input == null || repository == null) {
    return null;
  }
  try {
    final project = await repository.createProject(
      directory: input.$1,
      name: input.$2,
    );
    ref.invalidate(flitProjectsProvider);
    return project;
  } on GatewayException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create the project: ${error.message}'),
        ),
      );
    }
    return null;
  }
}

class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final TextEditingController _dir = TextEditingController();
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _dir.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final dir = _dir.text.trim();
    if (dir.isNotEmpty) {
      Navigator.pop(context, (dir, _name.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _dir,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Directory on the server',
              hintText: '/home/me/projects/app',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name (optional)',
              helperText: 'Defaults to the directory name',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

/// Lets the user pick a project to move [session] to, and moves it.
Future<void> showMoveSessionDialog(
  BuildContext context,
  WidgetRef ref,
  FlitSession session,
) async {
  final projects = await ref.read(flitProjectsProvider.future);
  if (!context.mounted) {
    return;
  }
  final target = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Move to project'),
      children: <Widget>[
        for (final p in projects)
          SimpleDialogOption(
            onPressed: p.id == session.projectId
                ? null
                : () => Navigator.pop(context, p.id),
            child: Text(
              p.id == session.projectId ? '${p.name} (current)' : p.name,
            ),
          ),
      ],
    ),
  );
  final repository = ref.read(flitRepositoryProvider);
  if (target == null || repository == null) {
    return;
  }
  try {
    await repository.moveSession(session.id, target);
    ref
      ..invalidate(flitSessionsProvider)
      ..invalidate(flitAllSessionsProvider)
      ..invalidate(flitProjectsProvider);
  } on GatewayException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not move the session: ${error.message}')),
      );
    }
  }
}

/// For the selected project: whether `flit export` includes its sessions
/// (the training corpus). Hidden when "All projects" is selected.
class FlitProjectExportToggle extends ConsumerWidget {
  const FlitProjectExportToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(flitSelectedProjectProvider);
    FlitProject? project;
    for (final p
        in ref.watch(flitProjectsProvider).value ?? const <FlitProject>[]) {
      if (p.id == selected) {
        project = p;
      }
    }
    if (project == null) {
      return const SizedBox.shrink();
    }
    final p = project;
    return PopupMenuButton<_ProjectOption>(
      tooltip: 'Project options',
      icon: const Icon(Icons.more_vert),
      onSelected: (option) => _setProjectOption(context, ref, p, option),
      itemBuilder: (_) => _projectOptionItems<_ProjectOption>(p, (o) => o),
    );
  }
}

enum _ProjectOption { export, worktrees }

/// The project's checkable options, as menu entries whose values are
/// [wrap]ped options.
List<PopupMenuEntry<T>> _projectOptionItems<T>(
  FlitProject p,
  T Function(_ProjectOption) wrap,
) => <PopupMenuEntry<T>>[
  CheckedPopupMenuItem<T>(
    value: wrap(_ProjectOption.export),
    checked: p.exportEnabled,
    child: const Text('Include in exports'),
  ),
  if (p.directory.isNotEmpty)
    CheckedPopupMenuItem<T>(
      value: wrap(_ProjectOption.worktrees),
      checked: p.worktrees,
      child: const Text('A git worktree per session'),
    ),
];

/// Flips [option] for project [p].
Future<void> _setProjectOption(
  BuildContext context,
  WidgetRef ref,
  FlitProject p,
  _ProjectOption option,
) async {
  final repository = ref.read(flitRepositoryProvider);
  if (repository == null) {
    return;
  }
  try {
    switch (option) {
      case _ProjectOption.export:
        await repository.setProjectExport(p.id, enabled: !p.exportEnabled);
      case _ProjectOption.worktrees:
        await repository.setProjectWorktrees(p.id, enabled: !p.worktrees);
    }
    ref.invalidate(flitProjectsProvider);
  } on GatewayException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change it: ${error.message}')),
      );
    }
  }
}

/// What the project context menu can do: start a session or flip an
/// option.
sealed class _ProjectAction {
  const _ProjectAction();
}

final class _NewSessionAction extends _ProjectAction {
  const _NewSessionAction();
}

final class _OptionAction extends _ProjectAction {
  const _OptionAction(this.option);

  final _ProjectOption option;
}

/// The context menu for project [p] (right-click or long-press in a project
/// list), opened at [position] (global): New session, then the project's
/// options. [sessions] are the project's, newest first, for the new
/// session's default directory.
Future<void> showFlitProjectMenu(
  BuildContext context,
  WidgetRef ref,
  FlitProject p, {
  required Offset position,
  List<FlitSession> sessions = const <FlitSession>[],
}) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final action = await showMenu<_ProjectAction>(
    context: context,
    position: RelativeRect.fromRect(
      position & Size.zero,
      Offset.zero & overlay.size,
    ),
    items: <PopupMenuEntry<_ProjectAction>>[
      const PopupMenuItem<_ProjectAction>(
        value: _NewSessionAction(),
        child: Text('New session…'),
      ),
      const PopupMenuDivider(),
      ..._projectOptionItems<_ProjectAction>(p, _OptionAction.new),
    ],
  );
  if (action == null || !context.mounted) {
    return;
  }
  switch (action) {
    case _NewSessionAction():
      await showFlitNewSession(
        context,
        ref,
        projectId: p.id,
        existing: sessions,
      );
    case _OptionAction(:final option):
      await _setProjectOption(context, ref, p, option);
  }
}
