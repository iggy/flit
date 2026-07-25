import 'package:flit/application/config/health_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Health diagnostics screen (ticket P4-06). Shows provider configuration,
/// runtime check, and verification status.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(healthStatusProvider);
            },
          ),
        ],
      ),
      body: healthAsync.when(
        data: (health) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Provider configured
            ListTile(
              leading: Icon(
                health.providerConfigured ? Icons.check_circle : Icons.cancel,
                color: health.providerConfigured ? Colors.green : Colors.red,
              ),
              title: const Text('Provider Configured'),
              subtitle: Text(
                health.providerConfigured ? 'Yes' : 'No',
              ),
            ),
            const Divider(),
            // Runtime check
            ListTile(
              title: const Text('Runtime Check'),
              subtitle: health.runtime != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              health.runtime!.ok
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: health.runtime!.ok
                                  ? Colors.green
                                  : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(health.runtime!.ok ? 'OK' : 'Failed'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Provider: ${health.runtime!.provider}'),
                        Text('Model: ${health.runtime!.model}'),
                        Text('Source: ${health.runtime!.source}'),
                        if (health.runtime!.error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Error: ${health.runtime!.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    )
                  : const Text('Check failed or not run'),
            ),
            const Divider(),
            // Verification status
            ListTile(
              leading: Icon(
                health.verificationStatus == 'unknown'
                    ? Icons.help_outline
                    : Icons.info,
                color: health.verificationStatus == 'unknown'
                    ? Colors.grey
                    : Colors.blue,
              ),
              title: const Text('Verification Status'),
              subtitle: Text(health.verificationStatus),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading health status: $error',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
