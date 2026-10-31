/// Starting a flit session: the new-session dialog and what follows it
/// (create, refresh the lists, open the session). Shared by the sessions
/// list's button, the project context menu, and shares from other apps.
library;

import 'package:flit/application/flit/flit_drafts.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Asks for a working directory and role, creates a session in
/// [projectId] (null: the server's default project) and opens it. The
/// directory starts at the project's, else the newest of [existing].
///
/// A non-empty [draft] (text shared from another app) is shown in the
/// dialog, which then also lets the user pick the project, and becomes the
/// new session's unsent composer text: it is not sent.
Future<void> showFlitNewSession(
  BuildContext context,
  WidgetRef ref, {
  required String? projectId,
  List<FlitSession> existing = const <FlitSession>[],
  String draft = '',
}) async {
  final choice = await showDialog<_NewSessionChoice>(
    context: context,
    builder: (_) => _NewSessionDialog(
      initialProject: projectId,
      fallbackDir: existing.isEmpty ? '' : existing.first.workingDir,
      draft: draft,
    ),
  );
  if (choice == null || !context.mounted) {
    return;
  }
  final repository = ref.read(flitRepositoryProvider);
  if (repository == null) {
    return;
  }
  try {
    final session = await repository.createSession(
      workingDir: choice.dir,
      role: choice.role,
      projectId: choice.projectId ?? '',
    );
    if (draft.isNotEmpty) {
      ref.read(flitDraftStoreProvider).write(session.id, draft);
    }
    ref
      ..invalidate(flitSessionsProvider)
      ..invalidate(flitAllSessionsProvider)
      ..invalidate(flitProjectsProvider);
    if (context.mounted) {
      await context.push('/flit/session/${session.id}');
      ref
        ..invalidate(flitSessionsProvider)
        ..invalidate(flitAllSessionsProvider);
    }
  } on GatewayException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create the session: ${error.message}'),
        ),
      );
    }
  }
}

typedef _NewSessionChoice = ({String dir, String role, String? projectId});

/// [project]'s directory, else [fallback].
String _dirFor(WidgetRef ref, String? project, String fallback) {
  for (final p
      in ref.read(flitProjectsProvider).value ?? const <FlitProject>[]) {
    if (p.id == project && p.directory.isNotEmpty) {
      return p.directory;
    }
  }
  return fallback;
}

class _NewSessionDialog extends ConsumerStatefulWidget {
  const _NewSessionDialog({
    required this.initialProject,
    required this.fallbackDir,
    required this.draft,
  });

  final String? initialProject;
  final String fallbackDir;

  /// Shared text that will become the composer draft; non-empty adds the
  /// project picker and a preview.
  final String draft;

  @override
  ConsumerState<_NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends ConsumerState<_NewSessionDialog> {
  String _role = '';
  late String? _project = widget.initialProject;
  late final TextEditingController _dir = TextEditingController(
    text: _dirFor(ref, widget.initialProject, widget.fallbackDir),
  );

  /// Default, the server's projects, and the chosen one even if the list
  /// hasn't loaded (a dropdown's value must be one of its items).
  List<DropdownMenuItem<String?>> _projectItems() {
    final projects =
        ref.watch(flitProjectsProvider).value ?? const <FlitProject>[];
    return <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(child: Text('Default')),
      if (_project != null && projects.every((p) => p.id != _project))
        DropdownMenuItem<String?>(value: _project, child: Text(_project!)),
      for (final p in projects)
        DropdownMenuItem<String?>(
          value: p.id,
          child: Text(p.name, overflow: TextOverflow.ellipsis),
        ),
    ];
  }

  void _pickProject(String? project) {
    setState(() => _project = project);
    final dir = _dirFor(ref, project, '');
    if (dir.isNotEmpty) {
      _dir.text = dir;
    }
  }

  @override
  void dispose() {
    _dir.dispose();
    super.dispose();
  }

  void _submit() {
    final dir = _dir.text.trim();
    if (dir.isNotEmpty) {
      Navigator.pop<_NewSessionChoice>(context, (
        dir: dir,
        role: _role,
        projectId: _project,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.draft.isNotEmpty) ...<Widget>[
            _SharedPreview(text: widget.draft),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: flitNewSessionProjectKey,
              initialValue: _project,
              decoration: const InputDecoration(labelText: 'Project'),
              items: _projectItems(),
              onChanged: _pickProject,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _dir,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Working directory on the server',
              hintText: '/home/me/projects/app',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(value: '', child: Text('None')),
              for (final r
                  in ref.watch(flitRolesProvider).value ??
                      const <FlitAgentRole>[])
                if (r.error.isEmpty)
                  DropdownMenuItem<String>(
                    value: r.name,
                    child: Text(
                      <String>[
                        r.name,
                        if (r.builtin) '(built-in)',
                        if (r.description.isNotEmpty) '— ${r.description}',
                      ].join(' '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: (v) => setState(() => _role = v ?? ''),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Start')),
      ],
    );
  }
}

/// The project picker in the new-session dialog (shown for shares).
const Key flitNewSessionProjectKey = Key('flit_new_session_project');

/// What will go into the composer, so the user sees what they shared.
class _SharedPreview extends StatelessWidget {
  const _SharedPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Shared into the message box (not sent)',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
