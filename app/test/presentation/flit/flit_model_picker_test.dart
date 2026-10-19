import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_model_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 18);

List<FlitModel> _models() => <FlitModel>[
  const FlitModel(provider: 'or', id: 'zeta', favorite: true),
  FlitModel(provider: 'local', id: 'used-old', lastUsed: _t0),
  FlitModel(
    provider: 'local',
    id: 'used-new',
    lastUsed: _t0.add(const Duration(hours: 1)),
    state: FlitModelState.loaded,
    loaded: true,
  ),
  const FlitModel(
    provider: 'local',
    id: 'idle',
    state: FlitModelState.unloaded,
  ),
  FlitModel(
    provider: 'or',
    id: 'alpha',
    favorite: true,
    lastUsed: _t0.add(const Duration(hours: 2)),
  ),
];

final class _Repo extends Fake implements FlitRepository {
  List<FlitModel> models = _models();
  final List<String> calls = <String>[];

  @override
  Future<List<FlitModel>> listModels() async => models;

  @override
  Future<void> setFavorite(
    String provider,
    String model, {
    required bool favorite,
  }) async {
    calls.add('star $provider/$model $favorite');
    models = <FlitModel>[
      for (final m in models)
        if (m.provider == provider && m.id == model)
          FlitModel(provider: m.provider, id: m.id, favorite: favorite)
        else
          m,
    ];
  }

  @override
  Future<FlitModel> setModelLoaded(
    String provider,
    String model, {
    required bool load,
  }) async {
    calls.add('${load ? 'load' : 'unload'} $provider/$model');
    return FlitModel(
      provider: provider,
      id: model,
      state: load ? FlitModelState.loaded : FlitModelState.unloaded,
    );
  }
}

void main() {
  test('sections: favorites, recent (not starred, newest first), all', () {
    final sections = flitModelSections(_models(), '');
    String names(int i) => sections[i].models.map((m) => m.id).join(',');
    expect(sections.map((s) => s.title), <String>[
      'Favorites',
      'Recent',
      'All models',
    ]);
    expect(names(0), 'alpha,zeta');
    expect(names(1), 'used-new,used-old');
    expect(sections[2].models, hasLength(5));

    final filtered = flitModelSections(_models(), 'USED');
    expect(filtered.single.title, '');
    expect(filtered.single.models.map((m) => m.id), <String>[
      'used-old',
      'used-new',
    ]);
    expect(flitModelSections(const <FlitModel>[], ''), isEmpty);
  });

  test('recent keeps the latest few', () {
    final many = <FlitModel>[
      for (var i = 0; i < 9; i++)
        FlitModel(
          provider: 'p',
          id: 'm$i',
          lastUsed: _t0.add(Duration(minutes: i)),
        ),
    ];
    final recent = flitModelSections(many, '')[0];
    expect(recent.title, 'Recent');
    expect(recent.models.map((m) => m.id), <String>[
      'm8',
      'm7',
      'm6',
      'm5',
      'm4',
    ]);
  });

  testWidgets('star, unload and load from the picker', (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [flitRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFlitModelPicker(
                context,
                provider: 'local',
                model: 'idle',
                effort: '',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);

    // Only router models have load buttons.
    const zeta = FlitModel(provider: 'or', id: 'zeta');
    const usedNew = FlitModel(provider: 'local', id: 'used-new');
    const idle = FlitModel(provider: 'local', id: 'idle');
    expect(find.byKey(flitLoadKey(zeta)), findsNothing);
    expect(find.byKey(flitLoadKey(usedNew)), findsWidgets);

    await tester.tap(find.byKey(flitLoadKey(usedNew)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(flitLoadKey(idle)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(flitStarKey(zeta)).first);
    await tester.pumpAndSettle();
    expect(repo.calls, <String>[
      'unload local/used-new',
      'load local/idle',
      'star or/zeta false',
    ]);
    // The list was re-read: zeta isn't a favorite any more.
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(flitStarKey(zeta)).first,
              matching: find.byType(Icon),
            ),
          )
          .icon,
      Icons.star_border,
    );
  });
}
