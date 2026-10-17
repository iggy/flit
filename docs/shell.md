# Shell commands: when flit asks

The agent's `shell` tool runs commands with `sh -c` (`cmd /C` on Windows).
Before each command, flit decides whether to run it, ask you, or refuse.
These rules exist to cut down on prompts; they are **not a sandbox**.

## How a command is checked

flit parses the command as a shell script and splits it into its parts:
the commands joined by `&&`, `||`, `;` and pipes, and the commands inside
`for`, `while` and `if`. `cd /src/app && git log --oneline | head -20` is
three parts. Then, in order:

1. **Deny rules win.** If any `shell.deny` pattern matches the whole
   command or any part of it (including parts inside `$(...)`), the command
   is refused. Nothing overrides this, not even yolo mode.
2. **Yolo mode** (see below) runs everything else.
3. **Things the rules can't see through** fall to `shell.default` (asking,
   by default): redirecting output to a file (`>`, `>>`, `&>`), `$(...)`
   and backticks, process substitution, function definitions, and setting
   variables like `PATH`, `LD_PRELOAD` or `GIT_*` in front of a command.
   Redirects that only read or discard are fine: `< file`, here-documents,
   `2>&1`, `>&2`, `> /dev/null`.
4. **Every part allowed** means the command runs without asking. A part is
   allowed when it matches a `shell.allow` pattern, is on the built-in
   read-only list, or matches a pattern you allowed for the session. `cd` is
   always allowed. The order of the parts doesn't matter.
5. Otherwise the **safety check** rates the command, if one is configured
   (see below), and then flit asks you. The prompt offers "allow for this
   session" for the parts that weren't already allowed.

Patterns use `*` for any run of characters and are matched against each
part as written, e.g. `go test*` or `npm run *`.

## The read-only list

With `shell.read_only: true` (the default), these run without asking:

- `cd`, `pwd`, `ls`, `cat`, `head`, `tail`, `wc`, `grep`, `egrep`, `fgrep`,
  `echo`, `printf`, `stat`, `du`, `df`, `which`, `type`, `whoami`, `uname`,
  `basename`, `dirname`, `realpath`, `readlink`, `true`, `false`, `test`,
  `[`, `diff`, `cmp`, `comm`, `cut`, `tr`, `nl`, `column`, `paste`, `fold`,
  `rev`, `seq`, `sleep`, `jq`, `ps`, `md5sum`, `sha1sum`, `sha256sum`,
  `sha512sum`, `continue`, `break`.
- With argument checks: `find` (no `-exec`, `-execdir`, `-ok`, `-delete`,
  `-fprint*`, `-fls`), `rg` (no `--pre`), `sort` (no `-o`), `uniq` (no
  output file), `tree` (no `-o`), `file` (no `-C`), `date` (no `-s`),
  `sed` (only `sed -n 1,80p file`-style line printing), `command -v`.
- `git` with a read-only subcommand: `status`, `log`, `show`, `diff`,
  `grep`, `blame`, `rev-parse`, `ls-files`, `ls-tree`, `cat-file`,
  `shortlog`, `describe`, `show-ref`, `merge-base`, `rev-list`,
  `for-each-ref`, `diff-tree`, `name-rev`, `count-objects`, `cherry`,
  `merge-tree`, `whatchanged`, `version`, plus listing forms of `branch`,
  `tag`, `remote`, `stash list/show`, `worktree list`, `reflog`, `config
  --get/--list` and `hash-object` without `-w`. `-C dir` and `--no-pager`
  are fine; `-c`, `--output` and `grep -O` are not.

Programs with argument checks need their arguments spelled out: `find
$DIR -name x` asks, because flit can't know what `$DIR` holds.

Turn the list off with `shell.read_only: false` to decide everything with
your own `allow` patterns.

## Yolo mode

In yolo mode every command runs except those matching `shell.deny`. Each
session has its own switch: the ⚡ button in the app's session bar (it asks
before turning on), or `SessionService.SetYolo`. `shell.yolo: true` makes
new sessions start with it on. Turning it on or off is recorded in the
session's event log.

## The safety check

A small, fast model can rate commands before you're asked. Configure the
`permission` task:

```yaml
agent:
  tasks:
    permission: {provider: local, model: qwen3-4b, effort: off}
```

For a command the rules would ask about, flit sends the command, the
project directory and the working directory to that model, which answers
`safe`, `ask` or `block` with a reason:

- **safe**: the command runs without asking.
- **block**: the command is refused, and the agent is told why.
- **ask**: you're asked, and the prompt shows the model's reason.

If the model doesn't answer within 60 seconds, or its answer can't be read,
you're asked as if there were no check. Deny rules, yolo mode and allowed
commands skip the check. Without a `permission` task there is no check.

Each verdict is a `permission_check` event in the session log, and each
check's model call is recorded with task `permission`, so both appear in
[`flit export`](export.md).

## Effort per task

Any task (and `agent` itself) can set `effort`: `low`, `medium`, `high` (or
a level the model names), or `off`.

- `off` turns thinking off on llama.cpp (`chat_template_kwargs:
  {enable_thinking: false}`) and is ignored by other providers.
- Levels are sent as `reasoning_effort`, except to models the catalog
  knows don't reason (llama.cpp always gets it).

A quick model with `effort: off` suits the `permission` task.
