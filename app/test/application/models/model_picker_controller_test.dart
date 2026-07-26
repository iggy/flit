// P1-11 acceptance: the model picker controller — select success path
// (refresh of modelOptionsProvider), the needsConfirm → confirmExpensive
// re-send path, and the error path (repo throws GatewayException →
// state.error, never throws). Plus the merged current-model tracker
// (options seed + session.info freshness).

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/models/model_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/repositories/model_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake model repository: records calls, answers from configurable stubs.
final class FakeModelRepository implements ModelRepository {
  int optionsCalls = 0;
  final List<({String model, String providerSlug})> setCalls =
      <({String model, String providerSlug})>[];
  final List<({String model, String providerSlug})> confirmedCalls =
      <({String model, String providerSlug})>[];

  ModelOptions optionsResult = (
    current: const CurrentModel(model: 'hermes-4-405b', provider: 'nous'),
    providers: const <ModelProvider>[
      ModelProvider(
        name: 'Nous Portal',
        slug: 'nous',
        authenticated: true,
        isCurrent: true,
        models: <String>['hermes-4-405b', 'hermes-4-70b'],
      ),
    ],
  );
  ModelSetOutcome setOutcome = const ModelSetApplied(value: 'hermes-4-70b');
  ModelSetOutcome confirmedOutcome = const ModelSetApplied(
    value: 'hermes-4-70b',
  );
  GatewayException? setError;

  @override
  Future<ModelOptions> options() async {
    optionsCalls++;
    return optionsResult;
  }

  @override
  Future<ModelSetOutcome> setModel({
    required String model,
    required String providerSlug,
  }) async {
    setCalls.add((model: model, providerSlug: providerSlug));
    final error = setError;
    if (error != null) {
      throw error;
    }
    return setOutcome;
  }

  @override
  Future<ModelSetOutcome> setModelConfirmed({
    required String model,
    required String providerSlug,
  }) async {
    confirmedCalls.add((model: model, providerSlug: providerSlug));
    final error = setError;
    if (error != null) {
      throw error;
    }
    return confirmedOutcome;
  }

  @override
  Future<ModelProvider> saveKey({
    required String slug,
    required String apiKey,
  }) async {
    throw UnimplementedError('saveKey not stubbed in this test');
  }

  @override
  Future<void> disconnectProvider({required String slug}) async {
    throw UnimplementedError('disconnectProvider not stubbed in this test');
  }
}

const option = ModelOption(providerSlug: 'nous', model: 'hermes-4-70b');

void main() {
  late FakeModelRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeModelRepository();
    container = ProviderContainer(
      overrides: [modelRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  ModelPickerState readState() => container.read(modelPickerControllerProvider);
  ModelPickerController readController() =>
      container.read(modelPickerControllerProvider.notifier);

  group('select', () {
    test('success: calls setModel, clears state, refreshes options', () async {
      // Establish a baseline fetch so the post-select invalidate is
      // observable as a SECOND fetch.
      await container.read(modelOptionsProvider.future);
      expect(repository.optionsCalls, 1);

      await readController().select(option);

      expect(repository.setCalls.single, (
        model: 'hermes-4-70b',
        providerSlug: 'nous',
      ));
      final state = readState();
      expect(state.switching, isFalse);
      expect(state.needsConfirm, isNull);
      expect(state.error, isNull);
      // Successful switch → modelOptionsProvider refreshed (wire §9: the
      // current model/badges change).
      await container.read(modelOptionsProvider.future);
      expect(repository.optionsCalls, 2);
    });

    test('needsConfirm: message lands in state, nothing applied yet', () async {
      repository.setOutcome = const ModelSetNeedsConfirm(
        message: 'This model is \$X/Mtok. Continue?',
      );

      await readController().select(option);

      final state = readState();
      expect(state.switching, isFalse);
      expect(state.needsConfirm, 'This model is \$X/Mtok. Continue?');
      expect(state.error, isNull);
      expect(repository.confirmedCalls, isEmpty);
    });

    test('needsConfirm → confirmExpensive re-sends confirmed', () async {
      repository.setOutcome = const ModelSetNeedsConfirm(
        message: 'This model is \$X/Mtok. Continue?',
      );
      repository.confirmedOutcome = const ModelSetApplied(
        value: 'hermes-4-70b',
      );

      await readController().select(option);
      expect(readState().needsConfirm, isNotNull);

      await readController().confirmExpensive();

      expect(repository.confirmedCalls.single, (
        model: 'hermes-4-70b',
        providerSlug: 'nous',
      ));
      final state = readState();
      expect(state.switching, isFalse);
      expect(state.needsConfirm, isNull);
      expect(state.error, isNull);
    });

    test('cancelConfirm clears needsConfirm without a re-send', () async {
      repository.setOutcome = const ModelSetNeedsConfirm(message: 'sure?');

      await readController().select(option);
      readController().cancelConfirm();

      expect(readState(), const ModelPickerState());
      expect(repository.confirmedCalls, isEmpty);
    });

    test(
      'error: repo throws GatewayException → state.error, never throws',
      () async {
        repository.setError = const GatewayRpcException(
          -32603,
          'backend exploded',
        );

        await expectLater(readController().select(option), completes);

        final state = readState();
        expect(state.switching, isFalse);
        expect(state.needsConfirm, isNull);
        expect(state.error, 'backend exploded');

        // clearError resets the banner.
        readController().clearError();
        expect(readState().error, isNull);
      },
    );

    test(
      'select without a repository (disconnected) reports an error',
      () async {
        final disconnected = ProviderContainer();
        addTearDown(disconnected.dispose);

        await disconnected
            .read(modelPickerControllerProvider.notifier)
            .select(option);

        final state = disconnected.read(modelPickerControllerProvider);
        expect(state.error, contains('Not connected'));
        expect(state.switching, isFalse);
      },
    );
  });

  group('currentModelProvider (merge of options + session.info)', () {
    /// NOTE: Riverpod 3 pauses a provider's internal ref.listen
    /// subscriptions while the provider itself has NO listeners — so the
    /// tracker must be LISTENED to, not merely read (in the app the
    /// picker button/sheet always watch it).
    ProviderSubscription<CurrentModel?> track(ProviderContainer c) {
      return c.listen(currentModelProvider, (previous, next) {});
    }

    test('null before options load, seeded by the options result', () async {
      final sub = track(container);
      addTearDown(sub.close);
      expect(container.read(currentModelProvider), isNull);

      await container.read(modelOptionsProvider.future);
      // Let the listener on modelOptionsProvider deliver.
      await Future<void>.value();

      expect(
        container.read(currentModelProvider),
        const CurrentModel(model: 'hermes-4-405b', provider: 'nous'),
      );
    });

    test('a stale model.options refetch after select() must not revert the '
        'freshly-applied model (regression: gateway model.options is not '
        'guaranteed immediately consistent after config.set)', () async {
      final sub = track(container);
      addTearDown(sub.close);

      // Seed with the initial (pre-switch) model.
      await container.read(modelOptionsProvider.future);
      await Future<void>.value();
      expect(
        container.read(currentModelProvider),
        const CurrentModel(model: 'hermes-4-405b', provider: 'nous'),
      );

      // The repository's options() STILL reports the OLD model on the
      // post-switch refetch (simulating a gateway that has not yet
      // caught up) — select() invalidates modelOptionsProvider, which
      // re-runs options() with this stale value still in place.
      await readController().select(option);

      // The explicit apply must win: NOT reverted to hermes-4-405b by
      // the (stale) refetch that select() triggered.
      expect(
        container.read(currentModelProvider),
        const CurrentModel(model: 'hermes-4-70b', provider: 'nous'),
      );
    });

    test(
      'session.info event updates the model, keeping the provider',
      () async {
        final events = StreamController<GatewayEvent>.broadcast();
        addTearDown(events.close);
        final withEvents = ProviderContainer(
          overrides: [
            modelRepositoryProvider.overrideWithValue(repository),
            gatewayEventsProvider.overrideWith((ref) => events.stream),
          ],
        );
        addTearDown(withEvents.dispose);

        // Create the tracker BEFORE options resolve so its listeners observe
        // both the seed and the event.
        final sub = track(withEvents);
        addTearDown(sub.close);
        await withEvents.read(modelOptionsProvider.future);
        await Future<void>.value();

        // After a successful switch the gateway pushes session.info with the
        // new model (wire §9/§6; only payload.model is pinned by the docs).
        events.add(
          const GatewayEvent(
            type: 'session.info',
            sessionId: 'a1b2c3d4',
            payload: <String, dynamic>{'model': 'hermes-4-70b'},
          ),
        );
        // Flush the async stream delivery + listener propagation.
        await Future<void>.delayed(Duration.zero);

        expect(
          withEvents.read(currentModelProvider),
          const CurrentModel(model: 'hermes-4-70b', provider: 'nous'),
        );
      },
    );

    test(
      'ignores session.info without a model and non-session.info events',
      () async {
        final events = StreamController<GatewayEvent>.broadcast();
        addTearDown(events.close);
        final withEvents = ProviderContainer(
          overrides: [
            modelRepositoryProvider.overrideWithValue(repository),
            gatewayEventsProvider.overrideWith((ref) => events.stream),
          ],
        );
        addTearDown(withEvents.dispose);

        final sub = track(withEvents);
        addTearDown(sub.close);
        await withEvents.read(modelOptionsProvider.future);
        await Future<void>.value();

        events.add(
          const GatewayEvent(
            type: 'session.info',
            sessionId: 'a1b2c3d4',
            payload: <String, dynamic>{'running': false},
          ),
        );
        events.add(
          const GatewayEvent(
            type: 'message.delta',
            sessionId: 'a1b2c3d4',
            payload: <String, dynamic>{'text': 'hi'},
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          withEvents.read(currentModelProvider),
          const CurrentModel(model: 'hermes-4-405b', provider: 'nous'),
        );
      },
    );
  });
}
