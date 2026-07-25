import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flit/core/router/app_router.dart';
import 'package:flit/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FlitApp()));
}

class FlitApp extends ConsumerWidget {
  const FlitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Flit',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
