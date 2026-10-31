# Webhooks: sessions started by events

A webhook lets something outside flit start work: GitHub sends an event
(a PR was opened, an issue was filed), and flit runs a prompt about it,
unattended. Each delivery is a new session in the hook's project, like a
[cron](cron.md) run, so you can open it, keep chatting in it, rate it or
fork it like any other session.

GitHub is the only source so far.

## Hook files

Each hook is a Markdown file in `webhooks_dir` (default `webhooks/`, next
to `config.yaml`). The YAML frontmatter says what the hook accepts and how
it runs, and the body is the prompt. The file name without `.md` is the
hook's name, and its URL is `<public_url>/webhooks/<name>`:
`flit-prs.md` takes deliveries at `https://flit.example.com/webhooks/flit-prs`.

```yaml
---
source: github                  # required
secret: ${FLIT_GITHUB_SECRET}   # required; ${VAR} is read from the environment
events: [pull_request.opened, pull_request.reopened, pull_request.ready_for_review]
repos: [iggy/flit]              # default any
ignore_senders: ["*[bot]"]      # default none
project: flit                   # name or id; default Scratch
dir: ~/projects/flit            # default the project's directory
role: reviewer                  # a role from roles_dir
model: {provider: local, model: qwen3-coder, effort: medium}
enabled: true                   # default true
ask: deny                       # deny (default) or wait
ask_timeout: 1h                 # with ask: wait; default 1h
yolo: false                     # default false
concurrency: 1                  # runs of this hook at once; default 1
keep_runs: 50                   # default 50
---
A pull request was opened. Check it out, build it and run the tests.
Read the diff. Say whether it is ready to merge, and if not, what is
missing. Don't push or comment on GitHub; just report.
```

`source`, `secret`, `events` and a non-empty prompt are required. As in
`config.yaml`, unknown keys are errors. A hook file with errors takes no
deliveries: they get a 503, and the error is in the server log.

flit reads the hook file on every delivery, so new, changed and removed
files take effect at once, without a restart.

- **events**: `pull_request` matches every action of that event,
  `pull_request.opened` only that one, and `"*"` everything. The names are
  GitHub's [event names](https://docs.github.com/en/webhooks/webhook-events-and-payloads).
  Pick the events in GitHub's settings too: GitHub only sends what the hook
  there subscribes to, and flit drops the rest.
- **repos** keeps an organization-wide hook to some repositories
  (`owner/name`).
- **ignore_senders** drops events caused by these logins. `*x` matches
  logins ending in `x`, so `"*[bot]"` drops Dependabot and friends.
- A hook in Scratch with no `dir` runs in a directory of its own,
  `<data dir>/webhooks/<hook>`.

## Setting it up on GitHub

1. Make flit reachable from the internet at `/webhooks/` (see below) and
   set `public_url`. flit logs each hook's URL when it starts.
2. Pick a long random secret, e.g. `openssl rand -hex 32`, and give it to
   flit, either in the file or in the environment flit runs with.
3. In the repository (or organization): Settings, Webhooks, Add webhook.
   Payload URL is the hook's URL, content type `application/json` (form
   encoded works too), the same secret, and pick the events.
4. GitHub sends a `ping` right away. flit answers `pong`, and Recent
   Deliveries shows it in green.

## Exposing only /webhooks/

Everything else flit serves needs the token, but `/webhooks/` doesn't: each
delivery has to carry a valid signature made with the hook's secret
(`X-Hub-Signature-256`) instead, and a wrong or missing one gets a 401. It
is the one path meant to be reachable from the internet. Keep the rest
private: put a reverse proxy in front that forwards only `/webhooks/`, e.g.
with Caddy:

```
flit.example.com {
	handle /webhooks/* {
		reverse_proxy 127.0.0.1:7433
	}
	respond 404
}
```

Cloudflare Tunnel, Tailscale Funnel and the like work the same way: route
only the `/webhooks/` path to flit.

## How a run works

- The session is titled `<hook> · <what happened>`, e.g.
  `flit-prs · PR #12 opened in iggy/flit: Fix the thing (by someone)`, and
  starts with a `webhook_run` event naming the hook, event, action and
  delivery.
- **The prompt** is the hook's body, with a preamble like a cron run's
  (nobody is watching, finish with a short report, reply exactly "nothing
  to report" if there is nothing to report), followed by the event: the
  main facts (number, title, author, branches, description, link) and the
  payload with GitHub's API links left out. The model is told that this
  part came from whoever triggered the event and is data, not
  instructions.
- **The model** is the hook's `model`, else its role's, else
  `agent.tasks.webhook`, else `agent.tasks.cron`, else the chat default.
- **Concurrency**: up to `concurrency` runs of a hook go at once. Later
  deliveries wait their turn in order (up to 50; beyond that they are
  recorded as skipped). Waiting deliveries don't survive a restart: they
  are recorded as failed, and you can redeliver them from GitHub.
- **Redeliveries**: a delivery id (`X-GitHub-Delivery`) whose run is
  going or finished is ignored, so GitHub's retries don't run twice. If the
  run failed or was skipped, redelivering it from GitHub runs it again.
- **Results** are recorded like cron runs: ok, needs attention (something
  was refused), failed or skipped, with the first line of the final reply
  as the summary. `notify.ntfy` gets the same notifications as for cron
  runs.
- **Old runs**: the sessions of the newest `keep_runs` runs stay in the
  session list; older ones are archived (not deleted).

### Worktrees

A run works in the project's directory, so a review that checks out the PR
branch would switch your checkout. Turn on per-session worktrees for the
project (see [git.md](git.md#worktrees)) and each run gets a worktree of its own.

## Permission prompts while unattended

The same as for cron runs (see [cron.md](cron.md#permission-prompts-while-unattended)):
the normal rules apply first, and only what would still ask is affected.
`ask: deny` refuses it at once, `ask: wait` holds the prompt for you to
answer from the app for up to `ask_timeout`, and `yolo: true` runs every
command no deny rule matches.

Be careful with `yolo` on public repositories: anyone can open a PR or an
issue, and its text ends up in the prompt. Deny rules still apply.

Beware of loops, too: a hook on `issue_comment` that comments on the issue
as you will trigger itself. Use `ignore_senders` with the account flit acts
as, or don't let it comment.

## Answers flit sends

| Status | When |
|---|---|
| 202 | Accepted: the run started or is waiting its turn (`{"status": "running", "run": "whr_..."}`) |
| 200 | `pong` for a ping, or ignored: hook disabled, event or repo not wanted, ignored sender, delivery already received |
| 401 | Signature missing or wrong |
| 404 | No such hook |
| 503 | The hook file has errors, or flit is shutting down |

## Not yet

- Showing hooks and their runs in the app and the CLI (the runs are in the
  `webhook_runs` table, and their sessions are in the session list).
- A generic source: any JSON POST, handed to the model along with the
  hook's prompt to decide what to do.
- Other forges' signatures (GitLab, Gitea/Forgejo).
