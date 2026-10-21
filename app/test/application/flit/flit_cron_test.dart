import 'package:flit/application/flit/flit_cron.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/application/notifications/notification_providers.dart';
import 'package:flit/core/platform/notifications.dart';
import 'package:flit/domain/models/flit_cron.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

FlitCronRun _run(
  String id,
  FlitCronRunState state, {
  bool finished = true,
  bool quiet = false,
  String summary = 'report',
  List<String> refused = const <String>[],
}) => FlitCronRun(
  id: id,
  job: 'nightly',
  state: state,
  finishedAt: finished ? DateTime(2026, 10, 21, 3) : null,
  quiet: quiet,
  summary: summary,
  refusedCommands: refused,
);

final class _Repo extends Fake implements FlitRepository {
  List<FlitCronRun> runs = <FlitCronRun>[];
  int listed = 0;

  @override
  Future<List<FlitCronRun>> listCronRuns({
    String name = '',
    int limit = 50,
  }) async {
    listed++;
    return runs;
  }

  @override
  Future<List<FlitCronJob>> listCronJobs() async => const <FlitCronJob>[];
}

final class _Notifications implements NotificationService {
  final List<(int, String, String)> shown = <(int, String, String)>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async => shown.add((id, title, body));

  @override
  Future<void> cancel(int id) async {}

  @override
  bool get isSupported => true;
}

class _On extends NotificationsEnabledNotifier {
  @override
  bool build() => true;
}

void main() {
  test('only finished runs worth telling about are notified, once', () {
    final runs = <FlitCronRun>[
      _run('ok', FlitCronRunState.ok),
      _run('quiet', FlitCronRunState.ok, quiet: true),
      _run('attention', FlitCronRunState.needsAttention),
      _run('failed', FlitCronRunState.failed),
      _run('skipped', FlitCronRunState.skipped),
      _run('running', FlitCronRunState.running, finished: false),
      _run('seen', FlitCronRunState.failed),
    ];
    expect(cronRunsToNotify(runs, <String>{'seen'}).map((r) => r.id), <String>[
      'ok',
      'attention',
      'failed',
    ]);
  });

  test('titles and bodies say what happened', () {
    final attention = _run(
      'a',
      FlitCronRunState.needsAttention,
      summary: 'CI is red',
      refused: <String>['git push'],
    );
    expect(cronRunNotificationTitle(attention), 'nightly needs attention');
    expect(cronRunNotificationBody(attention), 'CI is red Refused: git push');
    expect(
      cronRunNotificationTitle(_run('f', FlitCronRunState.failed)),
      'nightly failed',
    );
    expect(cronRunNotificationTitle(_run('o', FlitCronRunState.ok)), 'nightly');
  });

  test(
    'the notifier skips runs from before it started, then notifies',
    () async {
      final repo = _Repo()
        ..runs = <FlitCronRun>[_run('old', FlitCronRunState.failed)];
      final service = _Notifications();
      final container = ProviderContainer(
        overrides: [
          flitRepositoryProvider.overrideWithValue(repo),
          notificationServiceProvider.overrideWithValue(service),
          notificationsEnabledProvider.overrideWith(_On.new),
          flitCronPollIntervalProvider.overrideWithValue(
            const Duration(hours: 1),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(flitCronNotifierProvider);
      final notifier = container.read(flitCronNotifierProvider.notifier);
      await pumpEventQueue();
      expect(repo.listed, 1);
      expect(service.shown, isEmpty, reason: 'old runs are not news');

      repo.runs = <FlitCronRun>[
        _run('new', FlitCronRunState.needsAttention, summary: 'Look at CI'),
        _run('going', FlitCronRunState.running, finished: false),
        _run('old', FlitCronRunState.failed),
      ];
      await notifier.check();
      expect(service.shown.map((s) => s.$2), <String>[
        'nightly needs attention',
      ]);

      // Finishing later is still news; nothing twice.
      repo.runs = <FlitCronRun>[
        _run('going', FlitCronRunState.ok, summary: 'Done'),
        ...repo.runs.where((r) => r.id != 'going'),
      ];
      await notifier.check();
      await notifier.check();
      expect(service.shown.map((s) => s.$2), <String>[
        'nightly needs attention',
        'nightly',
      ]);
      expect(container.read(flitCronNotifierProvider), 2);
    },
  );
}
