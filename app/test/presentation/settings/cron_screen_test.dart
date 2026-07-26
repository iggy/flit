// P5-01 acceptance: the cron screen renders jobs, shows paused chip, and
// tapping delete calls remove.

import 'package:flit/application/cron/cron_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/cron_job.dart';
import 'package:flit/presentation/settings/cron_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/cron/cron_providers_test.dart'
    show FakeCronRepository;

Widget _wrap(FakeCronRepository repository) {
  return ProviderScope(
    overrides: [cronRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: CronScreen()),
  );
}

const _job1 = CronJob(
  id: 'job_123',
  name: 'Daily report',
  skills: <String>['dataviz'],
  promptPreview: 'Generate status...',
  schedule: 'every day at 9am',
  repeat: 'daily',
  deliver: 'slack',
  nextRunAt: '2026-07-26T09:00:00Z',
  lastStatus: 'success',
  enabled: true,
  state: 'scheduled',
);

const _job2 = CronJob(
  id: 'job_456',
  name: 'Weekly backup',
  skills: <String>[],
  promptPreview: 'Backup files...',
  schedule: 'every monday',
  repeat: 'weekly',
  deliver: 'email',
  enabled: false,
  state: 'paused',
);

void main() {
  testWidgets('renders jobs with schedule, next run, and last status', (
    tester,
  ) async {
    final repository = FakeCronRepository(jobs: const <CronJob>[_job1, _job2]);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Daily report'), findsOneWidget);
    expect(find.text('Schedule: every day at 9am'), findsOneWidget);
    expect(find.text('Next run: 2026-07-26T09:00:00Z'), findsOneWidget);
    expect(find.text('Last status: success'), findsOneWidget);

    expect(find.text('Weekly backup'), findsOneWidget);
    expect(find.text('Schedule: every monday'), findsOneWidget);
  });

  testWidgets('shows paused chip for paused jobs', (tester) async {
    final repository = FakeCronRepository(jobs: const <CronJob>[_job1, _job2]);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Job 1 is not paused.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Daily report'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('Paused'),
      ),
      findsNothing,
    );

    // Job 2 is paused (enabled=false, state=paused).
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Weekly backup'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('Paused'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping delete opens confirm dialog and calls remove', (
    tester,
  ) async {
    final repository = FakeCronRepository(jobs: const <CronJob>[_job1]);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Open the popup menu.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    // Tap the "Delete" menu item.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm dialog appears.
    expect(find.text('Delete scheduled task'), findsOneWidget);
    expect(find.text('Delete "Daily report"?'), findsOneWidget);

    // Tap "Delete" button in dialog.
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // Repository.remove was called.
    final removeCall = repository.calls.firstWhere((c) => c.action == 'remove');
    expect(removeCall.action, 'remove');
    expect(removeCall.jobId, 'job_123');
  });

  testWidgets('pause action calls the controller', (tester) async {
    // Start with a non-paused job.
    final repository = FakeCronRepository(jobs: const <CronJob>[_job1]);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Open the popup menu.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    // Tap "Pause".
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    // Repository.pause was called.
    final pauseCall = repository.calls.firstWhere((c) => c.action == 'pause');
    expect(pauseCall.action, 'pause');
    expect(pauseCall.jobId, 'job_123');
  });

  testWidgets('resume action calls the controller', (tester) async {
    // Start with a paused job.
    final repository = FakeCronRepository(jobs: const <CronJob>[_job2]);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Open the popup menu.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    // Tap "Resume".
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    // Repository.resume was called.
    final resumeCall = repository.calls.firstWhere((c) => c.action == 'resume');
    expect(resumeCall.jobId, 'job_456');
  });

  testWidgets('empty state when no jobs are reported', (tester) async {
    await tester.pumpWidget(_wrap(FakeCronRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No scheduled tasks'), findsOneWidget);
  });

  testWidgets('error state shows failure message', (tester) async {
    final repository = FakeCronRepository()
      ..error = const GatewayNetworkException('unreachable');
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load scheduled tasks'), findsOneWidget);
  });

  testWidgets('add button opens dialog and calls add', (tester) async {
    final repository = FakeCronRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Tap the FAB.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Dialog appears.
    expect(find.text('Add scheduled task'), findsOneWidget);

    // Fill in the fields.
    await tester.enterText(
      find.widgetWithText(TextField, 'Name (optional)').first,
      'Test job',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Schedule').first,
      'every day at 3pm',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Prompt').first,
      'Test prompt',
    );

    // Tap "Add" button in dialog.
    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();

    // Repository.add was called.
    final addCall = repository.calls.firstWhere((c) => c.action == 'add');
    expect(addCall.action, 'add');
    expect(addCall.prompt, 'Test prompt');
    expect(addCall.schedule, 'every day at 3pm');
    expect(addCall.name, 'Test job');
  });

  testWidgets('add dialog requires prompt and schedule', (tester) async {
    final repository = FakeCronRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Tap the FAB.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Leave fields empty and tap "Add".
    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pumpAndSettle();

    // Dialog should still be open (no call to repository).
    expect(find.text('Add scheduled task'), findsOneWidget);
    expect(repository.calls.length, 1); // only the initial list
  });
}
