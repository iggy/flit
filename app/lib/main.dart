import 'package:flit/application/config/skin_providers.dart';
import 'package:flit/application/config/window_providers.dart';
import 'package:flit/application/notifications/notification_providers.dart';
import 'package:flit/core/platform/desktop_window.dart';
import 'package:flit/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Desktop-only: restore window geometry, set title, show window (P9-01).
  if (isDesktopPlatform) {
    try {
      final controller = container.read(windowControllerProvider);
      final geometryService = container.read(windowGeometryServiceProvider);

      await controller.ensureInitialized();
      await geometryService.restore();
      await controller.setTitle('Flit');
      await controller.show();
    } on Object {
      // Window setup failure must not prevent the app from starting.
    }
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const FlitApp()),
  );
}

class FlitApp extends ConsumerStatefulWidget {
  const FlitApp({super.key});

  @override
  ConsumerState<FlitApp> createState() => _FlitAppState();
}

class _FlitAppState extends ConsumerState<FlitApp> {
  @override
  void initState() {
    super.initState();
    // Desktop-only: listen for window geometry changes and persist them (P9-01).
    if (isDesktopPlatform) {
      final controller = ref.read(windowControllerProvider);
      final geometryService = ref.read(windowGeometryServiceProvider);
      controller.setGeometryChangedCallback(geometryService.scheduleSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Keep the notification bridge (P9-03) alive for the whole app lifetime:
    // it is the only listener of background.complete / approval prompts, so
    // nothing else would mount it.
    ref.watch(notificationBridgeProvider);
    return MaterialApp.router(
      title: 'Flit',
      // Themes come from the skin providers (P9-07): the gateway-pushed skin
      // when the user opted in and it is usable, else the Material 3 default.
      theme: ref.watch(appLightThemeProvider),
      darkTheme: ref.watch(appDarkThemeProvider),
      routerConfig: router,
    );
  }
}
