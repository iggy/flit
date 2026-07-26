import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A friendly "Page not found" screen for unknown deep-link paths (ticket P9-02).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('The page you requested does not exist.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/chat'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
