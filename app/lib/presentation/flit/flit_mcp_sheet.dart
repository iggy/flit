/// Bottom sheet listing the configured MCP servers with a switch each, for
/// one session. Only enabled servers' tools reach the model.
library;

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showFlitMcpSheet(BuildContext context, String sessionId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _McpSheet(sessionId: sessionId),
  );
}

class _McpSheet extends ConsumerStatefulWidget {
  const _McpSheet({required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<_McpSheet> createState() => _McpSheetState();
}

class _McpSheetState extends ConsumerState<_McpSheet> {
  final Set<String> _busy = <String>{};

  Future<void> _toggle(String server, bool enabled) async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    setState(() => _busy.add(server));
    try {
      await repository.setMcpServer(widget.sessionId, server, enabled: enabled);
      ref.invalidate(flitMcpServersProvider(widget.sessionId));
    } on GatewayException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not change $server: ${error.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy.remove(server));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(flitMcpServersProvider(widget.sessionId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('MCP servers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Servers are set up in the server config. Turned-on servers '
              'start when the agent next needs them.',
            ),
            const SizedBox(height: 8),
            servers.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Could not list servers: ${e is GatewayException ? e.message : e}',
              ),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No MCP servers are configured.'),
                    )
                  : Column(
                      children: <Widget>[
                        for (final s in list)
                          SwitchListTile(
                            value: s.enabled,
                            onChanged: _busy.contains(s.name)
                                ? null
                                : (v) => _toggle(s.name, v),
                            title: Text(s.name),
                            subtitle: Text(
                              s.error.isNotEmpty
                                  ? s.error
                                  : s.running
                                  ? '${s.toolCount} tools'
                                  : 'not started yet',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
