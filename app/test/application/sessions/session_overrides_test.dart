// Gateway 0.20 contract v4: the per-session overrides `session.create`
// carries. Anything the user has not picked must stay ABSENT so the gateway
// inherits the profile — and `fast: false` must survive as a real pick.

import 'package:flit/application/config/config_providers.dart';
import 'package:flit/application/models/model_providers.dart';
import 'package:flit/application/sessions/session_overrides.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    // Disconnected container: the trackers' event/options listeners are
    // inert, so the only state comes from the explicit set() calls below.
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('nothing picked → every field null (inherit the profile)', () {
    expect(
      container.read(sessionCreateOverridesProvider),
      const SessionOverrides(),
    );
  });

  test('carries the model, provider slug, effort and fast pick', () {
    container
        .read(currentModelProvider.notifier)
        .set(const CurrentModel(model: 'hermes-4-70b', provider: 'nous'));
    container.read(currentReasoningProvider.notifier).set('high');
    container.read(currentFastProvider.notifier).set(true);

    expect(
      container.read(sessionCreateOverridesProvider),
      const SessionOverrides(
        model: 'hermes-4-70b',
        provider: 'nous',
        reasoningEffort: 'high',
        fast: true,
      ),
    );
  });

  test('fast: false is a PICK, not an absence', () {
    container.read(currentFastProvider.notifier).set(false);

    expect(container.read(sessionCreateOverridesProvider).fast, isFalse);
  });

  test('an empty model name is treated as unknown', () {
    container
        .read(currentModelProvider.notifier)
        .set(const CurrentModel(model: '', provider: 'nous'));

    final overrides = container.read(sessionCreateOverridesProvider);
    expect(overrides.model, isNull);
    // A bare provider slug would tell the gateway to pick a model for us.
    expect(overrides.provider, isNull);
  });

  test('a model without a known provider slug sends the model alone', () {
    container
        .read(currentModelProvider.notifier)
        .set(const CurrentModel(model: 'hermes-4-70b', provider: ''));

    final overrides = container.read(sessionCreateOverridesProvider);
    expect(overrides.model, 'hermes-4-70b');
    expect(overrides.provider, isNull);
  });
}
