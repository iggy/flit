/// The flit home screen: the server's sessions, newest first, and a button
/// to start one.
library;

import 'package:flit/application/flit/flit_pair_controller.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FlitSessionsScreen extends ConsumerWidget {
  const FlitSessionsScreen({super.key});

  Future<void> _newSession(
    BuildContext context,
    WidgetRef ref,
    List<FlitSession> existing,
  ) async {
    final dir = await showDialog<String>(
      context: context,
      builder: (_) => _NewSessionDialog(
        initialDir: existing.isEmpty ? '' : existing.first.workingDir,
      ),
    );
    if (dir == null || !context.mounted) {
      return;
    }
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    try {
      final session = await repository.createSession(workingDir: dir);
      ref.invalidate(flitSessionsProvider);
      if (context.mounted) {
        await context.push('/flit/session/${session.id}');
        ref.invalidate(flitSessionsProvider);
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

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect from flit?'),
        content: const Text(
          'This device forgets its token. To also revoke it on the server, '
          'run "flit devices revoke" there.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await ref.read(flitPairControllerProvider.notifier).disconnect();
    if (context.mounted) {
      context.go('/connect');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(flitSessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('flit sessions'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(flitSessionsProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Disconnect',
            onPressed: () => _disconnect(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _newSession(context, ref, sessions.value ?? const <FlitSession>[]),
        icon: const Icon(Icons.add),
        label: const Text('New session'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(flitSessionsProvider.future),
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load sessions: '
                  '${error is GatewayException ? error.message : error}',
                ),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const <Widget>[
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No sessions yet. Start one with New session.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return ListTile(
                      title: Text(
                        s.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${s.workingDir}\n${flitModelLabel(s.provider, s.model)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: FlitTaskStateChip(state: s.state),
                      onTap: () async {
                        await context.push('/flit/session/${s.id}');
                        ref.invalidate(flitSessionsProvider);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _NewSessionDialog extends StatefulWidget {
  const _NewSessionDialog({required this.initialDir});

  final String initialDir;

  @override
  State<_NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<_NewSessionDialog> {
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
      Navigator.pop(context, dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New session'),
      content: TextField(
        controller: _dir,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Working directory on the server',
          hintText: '/home/me/projects/app',
        ),
        onSubmitted: (_) => _submit(),
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
