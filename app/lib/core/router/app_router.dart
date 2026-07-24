/// App routing (go_router). Phase 0 wires /connect + a /chat placeholder;
/// Phase 1 fills in the real screens.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes/presentation/common/placeholder_screen.dart';
import 'package:hermes/presentation/connect/connect_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    routes: <RouteBase>[
      GoRoute(
        path: '/connect',
        name: 'connect',
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Chat', detail: 'Phase 1'),
      ),
    ],
  );
});
