import 'package:flutter/material.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';

/// The live gateway connection-state chip (ticket P1-16), shared by the
/// connect screen's app bar and the chat app bar (left-most action).
///
/// The reconnecting state is deliberately distinct (syncing icon +
/// 'Reconnecting') so a dropped socket never mystifies: the RPC client is
/// auto-reconnecting with backoff and the active session will be re-bound
/// via `session.resume` on ready (protocol §10).
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.state});

  /// The current connection state, or null while it is unknown (renders as
  /// offline — e.g. before the first connect attempt).
  final GatewayConnectionState? state;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state) {
      GatewayConnectionState.connecting => ('Connecting', Icons.sync),
      GatewayConnectionState.ready => ('Connected', Icons.cloud_done),
      GatewayConnectionState.reconnecting => (
        'Reconnecting',
        Icons.sync_problem,
      ),
      _ => ('Offline', Icons.cloud_off),
    };
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
