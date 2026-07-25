import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter/material.dart';

class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.state});

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
    return Tooltip(
      message: label,
      child: Icon(icon, size: 20),
    );
  }
}
