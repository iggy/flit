// P1-12 acceptance: the model picker sheet — provider sections with auth
// badges, the current-model check, disabled needs-key rows, selecting
// through the controller, the expensive-model confirm dialog, and the
// app-bar button label fed by currentModelProvider.

import 'package:flit/application/models/model_providers.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/repositories/model_repository.dart';
import 'package:flit/presentation/models/model_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The §8 example (docs/reference/03-mvp-wire-shapes.md) as domain models:
/// Nous Portal (authenticated, current, two models) + OpenRouter
/// (unauthenticated, warning, NO models on the wire).
const nousProvider = ModelProvider(
  name: 'Nous Portal',
  slug: 'nous',
  authenticated: true,
  isCurrent: true,
  authType: 'oauth',
  keyEnv: 'NOUS_API_KEY',
  models: <String>['hermes-4-405b', 'hermes-4-70b'],
  totalModels: 2,
);
const openRouterProvider = ModelProvider(
  name: 'OpenRouter',
  slug: 'openrouter',
  authenticated: false,
  isCurrent: false,
  keyEnv: 'OPENROUTER_API_KEY',
  warning: 'no key',
);

/// Fake model repository (records setModel calls for the wired-through
/// controller tests).
final class FakeModelRepository implements ModelRepository {
  FakeModelRepository({this.providers = const <ModelProvider>[]});

  final List<ModelProvider> providers;
  int optionsCalls = 0;
  final List<({String model, String providerSlug})> setCalls =
      <({String model, String providerSlug})>[];
  final List<({String model, String providerSlug})> confirmedCalls =
      <({String model, String providerSlug})>[];

  @override
  Future<ModelOptions> options() async {
    optionsCalls++;
    return (
      current: const CurrentModel(model: 'hermes-4-405b', provider: 'nous'),
      providers: providers,
    );
  }

  @override
  Future<ModelSetOutcome> setModel({
    required String model,
    required String providerSlug,
  }) async {
    setCalls.add((model: model, providerSlug: providerSlug));
    return ModelSetApplied(value: model);
  }

  @override
  Future<ModelSetOutcome> setModelConfirmed({
    required String model,
    required String providerSlug,
  }) async {
    confirmedCalls.add((model: model, providerSlug: providerSlug));
    return ModelSetApplied(value: model);
  }
}

/// Fake controller (records calls, drives needsConfirm on demand).
final class FakeModelPickerController extends ModelPickerController {
  final List<ModelOption> selected = <ModelOption>[];
  int confirmCalls = 0;
  int cancelCalls = 0;

  /// State applied after [select] — used to simulate needsConfirm.
  ModelPickerState stateAfterSelect = const ModelPickerState();

  @override
  ModelPickerState build() => const ModelPickerState();

  @override
  Future<void> select(ModelOption option) async {
    selected.add(option);
    state = stateAfterSelect;
  }

  @override
  Future<void> confirmExpensive() async {
    confirmCalls++;
  }

  @override
  void cancelConfirm() {
    cancelCalls++;
  }
}

void main() {
  late FakeModelRepository repository;

  setUp(() {
    repository = FakeModelRepository(
      providers: const <ModelProvider>[nousProvider, openRouterProvider],
    );
  });

  Widget sheetHarness({FakeModelPickerController? controller}) {
    return ProviderScope(
      overrides: [
        modelRepositoryProvider.overrideWithValue(repository),
        if (controller != null)
          modelPickerControllerProvider.overrideWith(() => controller),
      ],
      child: const MaterialApp(home: Scaffold(body: ModelPickerSheet())),
    );
  }

  /// Pump until the options fetch and the current-model seed land.
  Future<void> pumpSheet(WidgetTester tester, Widget harness) async {
    await tester.pumpWidget(harness);
    await tester.pump(); // options() resolves
    await tester.pump(); // currentModelProvider seed listener delivers
  }

  testWidgets('renders §8 providers with auth badges, warning, current check', (
    tester,
  ) async {
    await pumpSheet(tester, sheetHarness());

    // Provider sections.
    expect(find.text('Nous Portal'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    // Auth badges: authenticated / needs key / current provider marked.
    expect(find.text('Authenticated'), findsOneWidget);
    expect(find.text('Needs key'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    // The wire warning explains the disabled provider.
    expect(find.text('no key'), findsOneWidget);

    // Model rows under the authenticated provider.
    expect(find.text('hermes-4-405b'), findsOneWidget);
    expect(find.text('hermes-4-70b'), findsOneWidget);
    // The current model (hermes-4-405b, seeded from options) is checked.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // OpenRouter has no models on the wire (§8) — empty section hint.
    expect(find.text('No models listed'), findsOneWidget);
  });

  testWidgets('needs-key provider rows are disabled with a key icon + hint', (
    tester,
  ) async {
    repository = FakeModelRepository(
      providers: const <ModelProvider>[
        nousProvider,
        ModelProvider(
          name: 'OpenRouter',
          slug: 'openrouter',
          authenticated: false,
          isCurrent: false,
          keyEnv: 'OPENROUTER_API_KEY',
          models: <String>['openrouter-model-1'],
          warning: 'no key',
        ),
      ],
    );
    await pumpSheet(tester, sheetHarness());

    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('openrouter-model-1'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isFalse);
    expect(tile.onTap, isNull);
    // Key icon + "needs key" hint on the row.
    expect(find.byIcon(Icons.key_off_outlined), findsWidgets);
    expect(
      find.textContaining('Needs key (OPENROUTER_API_KEY)'),
      findsOneWidget,
    );

    // Tapping a disabled row selects nothing.
    await tester.tap(find.text('openrouter-model-1'));
    await tester.pump();
    expect(repository.setCalls, isEmpty);
  });

  testWidgets('selecting a model calls the controller', (tester) async {
    final controller = FakeModelPickerController();
    await pumpSheet(tester, sheetHarness(controller: controller));

    await tester.tap(find.text('hermes-4-70b'));
    await tester.pump();

    expect(
      controller.selected.single,
      const ModelOption(providerSlug: 'nous', model: 'hermes-4-70b'),
    );
  });

  testWidgets('needsConfirm shows the confirm dialog; Continue confirms', (
    tester,
  ) async {
    final controller = FakeModelPickerController()
      ..stateAfterSelect = const ModelPickerState(
        needsConfirm: 'This model is \$X/Mtok. Continue?',
      );
    await pumpSheet(tester, sheetHarness(controller: controller));

    await tester.tap(find.text('hermes-4-70b'));
    await tester.pump(); // select() applies the needsConfirm state
    await tester.pump(); // the listener opens the dialog

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('This model is \$X/Mtok. Continue?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    expect(controller.confirmCalls, 1);
    await tester.pump(const Duration(seconds: 1)); // dialog pop animation
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('confirm dialog Cancel cancels without confirming', (
    tester,
  ) async {
    final controller = FakeModelPickerController()
      ..stateAfterSelect = const ModelPickerState(needsConfirm: 'sure?');
    await pumpSheet(tester, sheetHarness(controller: controller));

    await tester.tap(find.text('hermes-4-70b'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    expect(controller.cancelCalls, 1);
    expect(controller.confirmCalls, 0);
    await tester.pump(const Duration(seconds: 1)); // dialog pop animation
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('end-to-end: button shows the current model, opens the sheet, a '
      'selection switches and closes it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [modelRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const <Widget>[ModelPickerButton()]),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump(); // options() resolves
    await tester.pump(); // currentModelProvider seed delivers

    // The button label is the CURRENT model (from currentModelProvider).
    expect(find.text('hermes-4-405b'), findsOneWidget);

    await tester.tap(find.byType(ModelPickerButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // sheet open animation
    expect(find.text('Nous Portal'), findsOneWidget);

    await tester.tap(find.text('hermes-4-70b'));
    await tester.pump(); // select() applies
    await tester.pump(); // close listener fires
    await tester.pump(const Duration(seconds: 1)); // sheet close animation

    expect(repository.setCalls.single, (
      model: 'hermes-4-70b',
      providerSlug: 'nous',
    ));
    // Sheet closed after the clean apply.
    expect(find.text('Nous Portal'), findsNothing);
    // The successful switch refreshed model.options.
    expect(repository.optionsCalls, greaterThanOrEqualTo(2));
  });
}
