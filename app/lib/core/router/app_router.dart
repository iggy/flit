/// App routing (go_router). Phase 0 wires /connect; Phase 1 lands the real
/// chat screen (P1-07) which bootstraps a session on arrival (P1-09).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes/presentation/chat/chat_screen.dart';
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
        builder: (context, state) => const ChatScreen(),
      ),
    ],
  );
});
