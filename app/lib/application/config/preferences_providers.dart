/// Riverpod wiring for the Phase 9 local UI preferences.
///
/// Deliberately tiny and dependency-free so every Phase 9 ticket (skin toggle,
/// window geometry, notification opt-in) shares ONE persistence seam. Override
/// [preferencesStoreProvider] in tests with an in-memory [KeyValueStore].
library;

import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence for the non-secret UI preferences.
final preferencesStoreProvider = Provider<PreferencesStore>((ref) {
  return const PreferencesStore(SecureKeyValueStore(FlutterSecureStorage()));
});
