import 'package:flutter/material.dart';

/// Temporary stand-in for screens implemented in later tickets.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          detail == null ? title : '$title — $detail',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
