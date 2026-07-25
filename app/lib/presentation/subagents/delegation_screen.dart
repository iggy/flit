import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/subagents/delegation_providers.dart';
import 'package:flit/application/subagents/spawn_tree_fold.dart';
import 'package:flit/application/subagents/spawn_tree_notifier.dart';
import 'package:flit/core/util/format_time.dart';
import 'package:flit/domain/models/agent_process.dart';
import 'package:flit/domain/models/delegation_status.dart';
import 'package:flit/domain/models/subagent_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Agents screen (ticket P3-05): delegation status (active subagents, spawn
/// limits, paused state) + live spawn tree + agent processes.
class DelegationScreen extends ConsumerWidget {
  const DelegationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegationStatus = ref.watch(delegationStatusProvider);
    final agentProcesses = ref.watch(agentProcessesProvider);
    final activeSession = ref.watch(activeSessionProvider);
    final liveId = activeSession.liveId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(delegationStatusProvider);
              ref.invalidate(agentProcessesProvider);
            },
          ),
        ],
      ),
      body: liveId == null
          ? const _DisconnectedMessage()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DelegationStatusCard(status: delegationStatus),
                  const SizedBox(height: 16),
                  _SpawnTreeCard(liveId: liveId),
                  const SizedBox(height: 16),
                  _AgentProcessesCard(processes: agentProcesses),
                ],
              ),
            ),
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

class _DelegationStatusCard extends ConsumerWidget {
  const _DelegationStatusCard({required this.status});

  final AsyncValue<DelegationStatus?> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Delegation Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            status.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
              data: (data) {
                if (data == null) {
                  return const Text('No delegation status available.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Paused: ${data.paused ? "Yes" : "No"}',
                          ),
                        ),
                        FilledButton.tonal(
                          key: const Key('delegation_pause_toggle'),
                          onPressed: () {
                            ref
                                .read(delegationStatusProvider.notifier)
                                .setPaused(!data.paused);
                          },
                          child: Text(data.paused ? 'Resume' : 'Pause'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Max spawn depth: ${data.maxSpawnDepth}'),
                    Text(
                      'Max concurrent children: ${data.maxConcurrentChildren}',
                    ),
                    Text('Active subagents: ${data.active.length}'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SpawnTreeCard extends ConsumerWidget {
  const _SpawnTreeCard({required this.liveId});

  final String liveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spawnTree = ref.watch(spawnTreeProvider(liveId));
    final isEmpty = spawnTree.nodes.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Spawn Tree',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonal(
                  key: const Key('spawn_tree_snapshots_nav'),
                  onPressed: () {
                    context.push('/agents/snapshots');
                  },
                  child: const Text('Snapshots'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('spawn_tree_save'),
                  onPressed: isEmpty ? null : () => _saveSpawnTree(context, ref, liveId, spawnTree),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isEmpty)
              const Text('No active subagents.')
            else
              ...spawnTree.order.map((id) {
                final node = spawnTree.nodes[id];
                if (node == null) {
                  return const SizedBox.shrink();
                }
                return _SubagentNodeTile(node: node);
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSpawnTree(
    BuildContext context,
    WidgetRef ref,
    String liveId,
    SpawnTreeState spawnTree,
  ) async {
    final repository = ref.read(delegationRepositoryProvider);
    if (repository == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected')),
        );
      }
      return;
    }

    // Build a best-effort JSON list from the SubagentNode objects.
    // The wire `subagents` is opaque/TUI-assembled, but we can map our
    // Flutter domain nodes into a reasonable shape.
    final subagentsJson = spawnTree.order.map((String id) {
      final node = spawnTree.nodes[id];
      if (node == null) {
        return <String, dynamic>{};
      }
      return <String, dynamic>{
        'id': node.id,
        'parent_id': node.parentId,
        'goal': node.goal,
        'model': node.model,
        'status': node.status.name,
        'tool_count': node.toolCount,
      };
    }).toList();

    if (subagentsJson.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empty tree cannot be saved')),
        );
      }
      return;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final label =
          'Snapshot $liveId (${formatShortDateMinutes(DateTime.now())})';
      final path = await repository.saveSnapshot(
        sessionId: liveId,
        subagents: subagentsJson,
        startedAt: null,
        finishedAt: now,
        label: label,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving snapshot: $e')),
        );
      }
    }
  }
}

class _SubagentNodeTile extends ConsumerWidget {
  const _SubagentNodeTile({required this.node});

  final SubagentNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final indent = node.depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, top: 8),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        child: ListTile(
          dense: true,
          leading: _StatusChip(status: node.status),
          title: Text(
            node.goal,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _buildSubtitle(node),
          trailing: node.status == SubagentStatus.running ||
                  node.status == SubagentStatus.thinking
              ? IconButton(
                  key: ValueKey('subagent_interrupt_${node.id}'),
                  icon: const Icon(Icons.stop),
                  iconSize: 20,
                  tooltip: 'Interrupt',
                  onPressed: () {
                    ref
                        .read(delegationStatusProvider.notifier)
                        .interrupt(node.id);
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSubtitle(SubagentNode node) {
    final parts = <String>[];
    if (node.model != null) {
      parts.add(node.model!);
    }
    parts.add('${node.toolCount} tools');
    if (node.lastToolName != null) {
      parts.add('last: ${node.lastToolName}');
    }
    if (node.lastActivity != null) {
      parts.add(node.lastActivity!);
    }
    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SubagentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (status) {
      SubagentStatus.queued => (Icons.schedule, theme.colorScheme.secondary),
      SubagentStatus.running => (Icons.play_arrow, theme.colorScheme.primary),
      SubagentStatus.thinking => (Icons.psychology, theme.colorScheme.primary),
      SubagentStatus.completed =>
        (Icons.check_circle, theme.colorScheme.tertiary),
      SubagentStatus.error => (Icons.error, theme.colorScheme.error),
      SubagentStatus.failed => (Icons.cancel, theme.colorScheme.error),
      SubagentStatus.interrupted =>
        (Icons.stop_circle, theme.colorScheme.secondary),
      SubagentStatus.timeout => (Icons.timer_off, theme.colorScheme.error),
    };

    return Icon(icon, color: color, size: 24);
  }
}

class _AgentProcessesCard extends StatelessWidget {
  const _AgentProcessesCard({required this.processes});

  final AsyncValue<List<AgentProcess>> processes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Agent Processes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            processes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
              data: (data) {
                if (data.isEmpty) {
                  return const Text('No background agent processes.');
                }
                return Column(
                  children: data.map(_AgentProcessTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentProcessTile extends StatelessWidget {
  const _AgentProcessTile(this.process);

  final AgentProcess process;

  @override
  Widget build(BuildContext context) {
    final uptimeMinutes = (process.uptime / 60).floor();
    final uptimeSeconds = (process.uptime % 60).floor();
    final uptimeStr = '${uptimeMinutes}m ${uptimeSeconds}s';

    return ListTile(
      dense: true,
      leading: const Icon(Icons.terminal),
      title: Text(
        process.command,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${process.status} • uptime: $uptimeStr'),
      trailing: Text(
        process.sessionId.substring(0, 8),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
