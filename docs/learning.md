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
- Learning runs only when you ask for it.
