/// The flit home screen: the server's sessions, newest first, and a button
/// to start one.
library;

import 'package:flit/application/flit/flit_pair_controller.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/common/middle_ellipsis_text.dart';
import 'package:flit/presentation/flit/flit_crons.dart';
import 'package:flit/presentation/flit/flit_learn_sheet.dart';
import 'package:flit/presentation/flit/flit_new_session.dart';
import 'package:flit/presentation/flit/flit_projects.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FlitSessionsScreen extends ConsumerWidget {
  const FlitSessionsScreen({super.key});

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
        title: const FlitProjectSwitcher(),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref
              ..invalidate(flitSessionsProvider)
              ..invalidate(flitAllSessionsProvider)
              ..invalidate(flitProjectsProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cron jobs',
            onPressed: () => context.push('/flit/crons'),
            icon: const Icon(Icons.schedule),
          ),
          const FlitProjectExportToggle(),
          IconButton(
            tooltip: 'Disconnect',
            onPressed: () => _disconnect(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFlitNewSession(
          context,
          ref,
          projectId: ref.read(flitSelectedProjectProvider),
          existing: sessions.value ?? const <FlitSession>[],
        ),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.workingDir,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          MiddleEllipsisText(
                            flitModelLabel(s.provider, s.model),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (s.isCronRun) ...<Widget>[
                            FlitCronBadge(job: s.cronJob),
                            const SizedBox(width: 4),
                          ],
                          FlitTaskStateChip(state: s.state),
                          PopupMenuButton<String>(
                            tooltip: 'Session actions',
                            onSelected: (action) => action == 'learn'
                                ? showFlitLearnSheet(context, s.id)
                                : showMoveSessionDialog(context, ref, s),
                            itemBuilder: (_) => const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'move',
                                child: Text('Move to project…'),
                              ),
                              PopupMenuItem<String>(
                                value: 'learn',
                                child: Text('Learn from this session'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () async {
                        await context.push('/flit/session/${s.id}');
                        ref
                          ..invalidate(flitSessionsProvider)
                          ..invalidate(flitAllSessionsProvider);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
