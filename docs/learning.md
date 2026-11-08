# Memory and manual self-learning

flit keeps lessons between sessions in plain Markdown files, and can propose
new ones by reading a finished session. Nothing is written until you accept
it: learning is manual on purpose.

## Memory layers

| Layer   | File                                         | In the prompt of            |
|---------|----------------------------------------------|-----------------------------|
| user    | `<data_dir>/memory/user.md`                  | every session               |
| project | `<data_dir>/memory/projects/<project id>.md` | sessions in that project    |
| role    | the role's `memory_file` (see roles)         | sessions with that role     |

Each file is re-read before every model call, so edits apply right away.
The user and project files are cut to `learning.memory_max_bytes` (6000 by
default) at a line boundary; the prompt then says how many bytes are
missing. The head of the file is kept, so keep the lessons that matter most
near the top (or ask `flit learn` to remove stale ones). The role memory
keeps its own, larger cap.

A lesson is a top-level Markdown list item. The ones flit writes look like

```markdown
- **When running the tests:** use `python3 -m unittest`; pytest isn't installed. _(evidence: ses_01a15d96 T2)_
```

that is: the cue (when it applies), the lesson (what to do), and the
evidence (the session and its turns). The files are yours to edit; anything
that isn't a list item is kept and shown to the model as it is.

## Learning from a session

```sh
flit learn <session id>            # a unique prefix works; flit debug session lists them
flit learn --dry-run <session id>  # show the proposals, store and write nothing
flit learn --yes <session id>      # accept everything
flit learn --pending [session id]  # review proposals already waiting (e.g. from the app)
```

In the app, use "Learn from this session" in a session's menu, or type
`/learn` in the chat. Both open a review sheet with Accept, Edit and Reject
for each proposal.

The learning pass sends the learning model:

- the session's active branch as a compact transcript, with turns numbered
  `T1`, `T2`, …: user messages, the agent's replies, tool calls and their
  results, interrupts, and your ratings and notes. Long texts are cut to their
  head and tail, harder and harder until it fits the budget; if it still
  doesn't fit, turns in the middle are left out.
- the memory layers it may change, with entries numbered `U1`, `P1`, `R1`, …
  so it can update or remove them;
- the names and descriptions of the session's skills.

It asks for a JSON list of proposals:

| field | meaning |
|-------|---------|
| `action` | `add`, `update` or `remove` |
| `target` | `user`, `project`, `role` or `skill` |
| `entry` | the entry to update or remove (`P2`) |
| `cue`, `lesson`, `evidence` | the lesson |
| `skill`, `description`, `body` | for skills: name, when to use it, Markdown instructions |

"Nothing worth keeping" (`{"proposals": []}`) is a normal answer, and should
be the usual one.

Small local models don't always follow the format, so the answer is read
leniently: JSON inside prose or code fences, trailing commas, YAML instead of
JSON, a bare list or a single object, and a few alternative field names are
all accepted. If nothing can be read, the model is asked once more.

Proposals are then checked. Ones without a lesson, ones pointing at entries
that don't exist, updates that change nothing, and lessons already in memory
are left out (`flit learn` says why). A pass keeps at most 8. The rest are
stored as pending, replacing the session's earlier pending proposals.

### Where accepted proposals go

- Memory entries are appended to, or changed in, their file. If you edited
  the entry by hand since the proposal was made, accepting it fails rather
  than guessing.
- New skills go to `.agents/skills/<name>/SKILL.md` at the git root of the
  session's working directory, or to the first of `skills_dirs` if it isn't
  in a repo. A proposal for an existing skill updates that skill's SKILL.md
  (a built-in skill is overridden by a new one in the repo). flit never
  deletes skills; a proposal to remove one is dropped with a note.

## Learned facts

Separately from `flit learn`, flit works out small facts about a project's
environment by itself. There are no model calls and no proposals to review:
after each turn it reads that session's shell commands from the event log.

Each command is split into its parts (with the same splitter the shell rules
use), and each part is classified by what it is for (running tests, building
or checking, a package tool, an interpreter, fetching) and how it was spelled,
without its arguments. Its outcome comes from the exit code and the output:
command not found, a missing module, a missing variable, a refused host.

| Family | A session confirms it when | Example |
|--------|----------------------------|---------|
| `form_repair` | a spelling fails with command not found, a missing module or permission denied, and another spelling of the same thing works later in the same turn | `pytest` → `python -m pytest`, `tsc` → `npx tsc` |
| `boundary` | every fetch to a host fails with a network error (localhost doesn't count) | `pypi.internal` refuses connections |
| `env_value` | a run fails asking for a variable, and a later run that sets it works | `DJANGO_ENV=test` |

An error only counts against a part it can be pinned on: the part is the only
real command in the chain, or the error names it. `make` failing because a
recipe's `cc` is missing says nothing about `make`.

Values of variables that might be secret (by name or by shape) are never kept:
the fact then only says the variable must be set.

### Lifecycle

A fact is *forming* until 3 different sessions confirm it, then *active*.

An active fact goes into the system prompt only while it is still useful: the
failure must have occurred, or been prevented, in at least 40% of the sessions
that exercised it, over at least 4 sessions. "Prevented" means the session
carried the fact and used the working spelling. So a new fact is usually first
injected on the fourth session, and one nobody needs any more drops out.

A spelling or variable fact *retires* after 2 contradicting sessions in a row
(the "wrong" spelling works now); a session that says nothing either way breaks
the streak. A boundary retires as soon as its host answers. A retired fact
starts over if the failure comes back. A fact you forget stays forgotten.

Facts are stored per project. The Scratch project holds unrelated directories,
so there they apply per directory. Only the per-session verdicts are stored and
the state is worked out from them, so config changes apply right away.

Injected facts sit right after the memory layers, as cue and lesson, without
their evidence:

```markdown
- **When running the tests:** use `python -m pytest`; `pytest` fails here with a missing module error.
```

They only ever state what works here, never that something can be skipped or
is finished.

### Commands

```sh
flit facts [--project X]   # active, forming and retired facts, with evidence
flit facts forget <id>     # retire one for good (a unique id prefix works)
flit facts --rebuild       # work everything out again from the event logs
```

`flit.v1.LearningService` has `ListLearnedFacts` and `ForgetLearnedFact`.

## Configuration

```yaml
agent:
  tasks:
    # The model for the learning pass. Without it, the session's own model
    # (then the chat model) is used.
    learning: {provider: local, model: qwen3-coder, effort: off}

learning:
  # Each memory file (user, project) is cut to this many bytes in the
  # system prompt. 0 means no cap.
  memory_max_bytes: 6000
  # Longest transcript sent to the learning model. 0 means about half the
  # model's context window, or 24000 bytes when that is unknown.
  transcript_max_bytes: 0
  # on: learn facts and add them to the prompt. propose: learn and list
  # them only. off: neither.
  facts: on
  # Caps on the facts in the prompt. 0 means no cap.
  facts_max: 10
  facts_max_bytes: 1500
  # Sessions that must confirm a fact before it is active.
  facts_promote_sessions: 3
  # Contradicting sessions in a row that retire a spelling or variable fact.
  facts_retire_sessions: 2
  # The injection gate: the share of exercising sessions in which the
  # failure occurred or was prevented, and the fewest to measure it over.
  facts_fire_rate: 0.4
  facts_fire_min_sessions: 4
```

The learning call is recorded with the session's other model calls (task
`learning`), so `flit export` includes it.

## API

`flit.v1.LearningService`: `Learn` runs a pass and returns its proposals,
`ListLearnProposals` lists pending (or all) proposals, and
`AcceptLearnProposal` (optionally with edited `text`) and
`RejectLearnProposal` decide one. See `proto/flit/v1/learning.proto`.

## Not yet

- Only relevant entries could be chosen per session, instead of the whole
  file within a budget.
- `flit learn` runs only when you ask for it.
- Learned facts read only the main agent's shell calls, not subagents'.
- Learned facts have no families yet for empty probes (a repo with no remote)
  or argument repairs (test labels of the wrong shape).
- The app has no screen for learned facts.
