import 'package:flit/application/sessions/deep_link_resolver.dart';
import 'package:flit/presentation/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a session deep link (ticket P9-02) by switching to the requested
/// durable session id, then showing the chat screen. The durable id comes
/// from the router's `:id` path parameter.
class SessionDeepLinkScreen extends ConsumerStatefulWidget {
  const SessionDeepLinkScreen({super.key, required this.durableId});

  final String durableId;

  @override
  ConsumerState<SessionDeepLinkScreen> createState() =>
      _SessionDeepLinkScreenState();
}

class _SessionDeepLinkScreenState extends ConsumerState<SessionDeepLinkScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger resolution post-frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(deepLinkResolverProvider.notifier).resolve(widget.durableId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolveState = ref.watch(deepLinkResolverProvider);

    if (resolveState.busy) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading session...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (resolveState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Failed to load session')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                resolveState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref
                    .read(deepLinkResolverProvider.notifier)
                    .resolve(widget.durableId),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Resolution succeeded — show the chat screen.
    return const ChatScreen();
  }
}
