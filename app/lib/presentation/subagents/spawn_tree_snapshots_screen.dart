import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/subagents/delegation_providers.dart';
import 'package:flit/core/util/format_time.dart';
import 'package:flit/domain/models/spawn_tree_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spawn-tree snapshots screen (ticket P3-06): browse + load saved snapshots.
class SpawnTreeSnapshotsScreen extends ConsumerWidget {
  const SpawnTreeSnapshotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);
    final liveId = activeSession.liveId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spawn Tree Snapshots'),
      ),
      body: liveId == null
          ? const _DisconnectedMessage()
          : _SnapshotsList(sessionId: liveId),
    );
  }
}

class _DisconnectedMessage extends StatelessWidget {
  const _DisconnectedMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Not connected — return to chat to establish a session.'),
    );
  }
}

class _SnapshotsList extends ConsumerWidget {
  const _SnapshotsList({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotListProvider(sessionId));

    return snapshots.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading snapshots: $error')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('No snapshots saved yet.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _SnapshotEntryTile(entry: entry);
          },
        );
      },
    );
  }
}

class _SnapshotEntryTile extends StatelessWidget {
  const _SnapshotEntryTile({required this.entry});

  final SpawnTreeSnapshotEntry entry;

  @override
  Widget build(BuildContext context) {
    final finishedDate = DateTime.fromMillisecondsSinceEpoch(
      (entry.finishedAt * 1000).toInt(),
    );
    final formattedDate = formatDateMinutes(finishedDate);

    return Card(
      child: ListTile(
        title: Text(entry.label),
        subtitle: Text(
          '${entry.count} subagents • $formattedDate',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _SnapshotDetailScreen(path: entry.path),
            ),
          );
        },
      ),
    );
  }
}

class _SnapshotDetailScreen extends ConsumerWidget {
  const _SnapshotDetailScreen({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(snapshotDetailProvider(path));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshot Details'),
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading snapshot: $error')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Snapshot not found.'));
          }
          return _SnapshotDetailView(snapshot: data);
        },
      ),
    );
  }
}

class _SnapshotDetailView extends StatelessWidget {
  const _SnapshotDetailView({required this.snapshot});

  final SpawnTreeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final finishedDate = DateTime.fromMillisecondsSinceEpoch(
      (snapshot.finishedAt * 1000).toInt(),
    );
    final formattedFinished = formatDateSeconds(finishedDate);

    String? formattedStarted;
    if (snapshot.startedAt != null) {
      final startedDate = DateTime.fromMillisecondsSinceEpoch(
        (snapshot.startedAt! * 1000).toInt(),
      );
      formattedStarted = formatDateSeconds(startedDate);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Metadata',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('Label: ${snapshot.label}'),
                  Text('Session: ${snapshot.sessionId}'),
                  if (formattedStarted != null)
                    Text('Started: $formattedStarted'),
                  Text('Finished: $formattedFinished'),
                  Text('Subagents: ${snapshot.subagents.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Subagents (opaque TUI-assembled)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...snapshot.subagents.map(_renderSubagent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderSubagent(dynamic entry) {
    // Best-effort rendering of opaque subagent entries.
    // Do NOT assume fields; read them defensively.
    if (entry is! Map) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(entry.toString()),
      );
    }

    final goal = entry['goal'] as String? ?? '(no goal)';
    final id = entry['id'] as String? ?? entry['subagent_id'] as String? ?? '(no id)';
    final status = entry['status'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('• $id: $goal${status.isNotEmpty ? " [$status]" : ""}'),
    );
  }
}
