/// Starting a flit session: the new-session dialog and what follows it
/// (create, refresh the lists, open the session). Shared by the sessions
/// list's button and the project context menu.
library;

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Asks for a working directory and role, creates a session in
/// [projectId] (null: the server's default project) and opens it. The
/// directory starts at the project's, else the newest of [existing].
Future<void> showFlitNewSession(
  BuildContext context,
  WidgetRef ref, {
  required String? projectId,
  List<FlitSession> existing = const <FlitSession>[],
}) async {
  var initialDir = existing.isEmpty ? '' : existing.first.workingDir;
  for (final p
      in ref.read(flitProjectsProvider).value ?? const <FlitProject>[]) {
    if (p.id == projectId && p.directory.isNotEmpty) {
      initialDir = p.directory;
    }
  }
  final choice = await showDialog<({String dir, String role})>(
    context: context,
    builder: (_) => _NewSessionDialog(initialDir: initialDir),
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
      projectId: projectId ?? '',
    );
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

class _NewSessionDialog extends ConsumerStatefulWidget {
  const _NewSessionDialog({required this.initialDir});

  final String initialDir;

  @override
  ConsumerState<_NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends ConsumerState<_NewSessionDialog> {
  String _role = '';
  late final TextEditingController _dir = TextEditingController(
    text: widget.initialDir,
  );

  @override
  void dispose() {
    _dir.dispose();
    super.dispose();
  }

  void _submit() {
    final dir = _dir.text.trim();
    if (dir.isNotEmpty) {
      Navigator.pop(context, (dir: dir, role: _role));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
