# Cron jobs: prompts on a schedule

A cron job is a prompt flit runs on a schedule, unattended. Each run is a
new session in the job's project, so you can open it, keep chatting in it,
rate it or fork it like any other session.

## Job files

Each job is a Markdown file in `crons_dir` (default `crons/`, next to
`config.yaml`). The YAML frontmatter says when and how the job runs, and
the body is the prompt. The file name without `.md` is the job's name:
`morning-ci.md` is `morning-ci`.

```yaml
---
schedule: weekdays at 8:30     # required; see Schedules
project: flit                  # name or id; default Scratch
dir: ~/projects/flit           # default the project's directory
role: qa                       # a role from roles_dir
model: {provider: local, model: qwen3-4b, effort: off}
enabled: true                  # default true
ask: deny                      # deny (default) or wait
ask_timeout: 1h                # with ask: wait; default 1h
yolo: false                    # default false
timezone: Europe/Berlin        # default the server's
catch_up: 1h                   # default 1h; 0 never catches up
keep_runs: 50                  # default 50
---
Check CI on main and the open PRs. Report anything red, with the failing step.
```

Only `schedule` is required, plus a non-empty prompt. As in `config.yaml`,
unknown keys are errors. A job file with errors never runs. The error
shows in the app, in `flit cron list` and in the server log; the other
jobs are not affected.

flit rereads the directory every few seconds, so new, changed and removed
files take effect without a restart.

A job in Scratch with no `dir` runs in a directory of its own,
`<data dir>/cron/<job>`.

## Schedules

- **Cron syntax**: five fields (minute, hour, day of month, month, day of
  week), e.g. `30 8 * * 1-5`, `*/15 * * * *`, `0 9 1 * *`. Lists, ranges,
  steps, and month and day names work. Also `@hourly`, `@daily`, `@weekly`,
  `@monthly` and `@yearly`.
- **Intervals**: `every 30m`, `every 2h`, `every minute`, `every hour`.
  These count from midnight, so `every 30m` runs on the hour and the half
  hour. The interval can be 1 minute to 24 hours.
- **Days and a time**: `daily at 9:00`, `weekdays at 8:30`,
  `weekends at 10`, `mondays at 10`, `mon, wed and fri at 17:30`,
  `daily at 7pm`.
- **Once**: `in 20m`, `in 2h`, `in 1d`, or `at 2026-10-22 09:00`. After it
  runs, flit sets `enabled: false` in the file. `in ...` counts from when the
  file was last saved, so the `cron` tool writes these as `at <time>`.

Times are the server's local time unless `timezone` (an IANA name) is set.

## How a run works

- The session is titled `<job> · <date time>` and starts with a `cron_run`
  event that says which job and schedule started it. The prompt you see as
  the first message has a short preamble: nobody is watching, finish with a
  short report, and reply exactly "nothing to report" if there is nothing
  to report.
- **The model** is the job's `model`, else its role's, else
  `agent.tasks.cron`, else the chat default. Nothing about a run needs a
  big model.
- **Overlap**: if a run is still going when the job is due again, that slot
  is recorded as skipped. Runs never stack.
- **Missed runs** (flit was off, the laptop was asleep): when flit starts, a
  job that missed its last slot within `catch_up` runs once, however many
  slots it missed. The same holds while flit runs: after a long sleep, it
  runs once and then goes back to its schedule.
- **Results**: each run is recorded with a state: ok, needs attention
  (something was refused), failed (the turn ended in an error or was
  interrupted) or skipped. The summary is the first line of the final reply.
- **Old runs**: the sessions of the newest `keep_runs` runs stay in the
  session list. Older ones are archived. They leave the list but are not
  deleted, so `flit export` and ratings still see them.

## Permission prompts while unattended

Nobody is there to click Allow. The normal rules still apply first, in the
same order as always: deny rules, allow rules, the read-only list, yolo
mode, and the safety check (see [shell.md](shell.md)). Only what would
still ask is affected:

- `ask: deny` (the default): the command is refused at once. The model is
  told it isn't allowed in an unattended run and to mention it in its
  report. The run goes on and ends as **needs attention**, listing the
  refused commands.
- `ask: wait`: the prompt is held, and you can answer it from the app as
  usual. If nobody answers within `ask_timeout`, it is refused as above.
- `yolo: true` runs every command that no deny rule matches, the same as
  yolo mode in a session. Deny rules always win.

## Creating jobs from a chat: the `cron` tool

Sessions have a `cron` tool that lists, creates, edits, removes and runs
jobs. You can say "every other weekday morning before nine, check the
nightly build". The model turns that into one of the supported schedule
forms and tells you what it picked. **Creating, editing and removing a job
always asks you first**, even in yolo mode, because it schedules work that
runs later with nobody watching. When the tool edits a file, it rewrites
the file, and comments in it are lost.

## In the app

The project side pane on desktop has a Cron section, and phones have a
Crons screen. Each job shows its schedule in words, its next run, and its
last run's state and summary, with Run now and an enable/disable switch.
Opening a job lists its runs, and each run opens its session. Sessions
that are cron runs carry a badge.

While the app is connected, it shows a local notification when a run
finishes with a report, needs attention or fails. It uses the existing
notification settings. Runs with nothing to report stay quiet.

## Notifications when the app is closed: ntfy

flit has no push service. For results on your phone when the app isn't
running, point `notify.ntfy` at an [ntfy](https://ntfy.sh) topic: ntfy.sh
(pick a long random topic name) or your own server. This is off by
default.

```yaml
notify:
  ntfy: https://ntfy.sh/flit-7f3c9a1e2b
  ntfy_headers:
    Authorization: Bearer ${NTFY_TOKEN}   # ${VAR} is read from the environment
```

flit posts a run that finished with a report, needs attention, or failed.
Runs with nothing to report are not posted.

## API and CLI

`CronService` has `ListCronJobs`, `GetCronJob`, `RunCronJob`,
`SetCronJobEnabled` (it rewrites `enabled:` in the file and keeps the rest)
and `ListCronRuns`. `Session.cron_job` names the job a session ran for.
`ListSessions` leaves archived sessions out unless you set
`include_archived`.

From a shell on the server's machine:

```sh
flit cron list            # jobs, schedules, next and last runs
flit cron run morning-ci  # run now and wait for the result (--no-wait to not wait)
```
