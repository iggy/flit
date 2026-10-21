# Exporting sessions (`flit export`)

flit records every model call it makes, with enough detail to reproduce
the request exactly, and every rating given in the app. `flit export`
writes these as JSONL (one JSON object per line) for building fine-tuning
and evaluation datasets.

```sh
flit export --out corpus.jsonl                      # everything
flit export --rating good --records turn --redact   # good turns, safe to share
flit export --since 2026-10-01 --project app --model llama/qwen3-coder
```

Run it on the machine running `flit serve` (it reads `flit.db` in the data
dir directly; it's safe while the server runs).

## What is recorded

For each model call, in `flit.db`:

- the exact messages sent (system prompt, history, tool results) and the
  tool schemas, stored as content-addressed blobs so a long conversation
  doesn't store the same messages again on every call;
- the request parameters: model and `reasoning_effort` (flit sends no
  sampling parameters, so the provider's defaults apply; recorded as
  `"sampling": "provider defaults"`);
- the response: text, reasoning (`reasoning_content`) and tool calls, the
  finish reason, token usage, speed metrics, and any error;
- the flit version, the session's role, and the skills that were offered;
- the session, project, and turn (the user message that started it).

Ratings (👍/👎 in the app, or the `Rate` RPC) are stored with the model
call and turn they rate, the model that produced the rated reply, the
rating client, and the optional note.

Recording started with flit M4. Earlier sessions have their conversation
and ratings in the event log but no exact request records, so they don't
appear in exports.

## Opting a project out

Projects are included by default. To leave one out (for example, client
work), turn off **Include in exports** for it in the app, or call
`ProjectService.SetProjectExport`. Opted-out projects are skipped by every
export, whatever the filters.

## Flags

| Flag | Meaning |
| --- | --- |
| `--out FILE` | Write here instead of stdout. |
| `--since DATE`, `--until DATE` | Only records created in `[since, until)`. `YYYY-MM-DD` (local time) or RFC 3339. |
| `--project P` | Only this project, by id or name. |
| `--model M` | Only this model, as `model` or `provider/model`. |
| `--rating R` | `good`, `bad`, or `rated` (any rating). Without it, unrated records are included. |
| `--records LIST` | Comma-separated record types to write: `session`, `turn`, `model_call`. Default: all. |
| `--redact` | Replace paths and secrets; see below. |

## Record types

Every record has `type` and `format_version` (currently `1`). Messages use
the OpenAI chat format: `{"role": "system"|"user"|"assistant"|"tool",
"content": ..., "tool_calls": [...], "tool_call_id": ...}`, and `tools` is
the OpenAI tools array. Assistant messages may carry `reasoning_content`.

### `model_call`

One call to a model: the training example "this exact request produced
this response".

```json
{
  "type": "model_call", "format_version": 1,
  "id": "msg_…", "session_id": "ses_…", "turn_id": "msg_…", "branch_id": "br_…", "task": "chat",
  "project": {"id": "proj_…", "name": "app"},
  "created_at": "2026-10-14T15:30:00Z",
  "provider": "llama", "model": "qwen3-coder", "reasoning_effort": "low",
  "flit_version": "0.4.0", "role": "reviewer", "skills": ["release-notes"],
  "params": {"model": "qwen3-coder", "reasoning_effort": "low", "stream": true, "sampling": "provider defaults"},
  "messages": [ {"role": "system", "content": "…"}, {"role": "user", "content": "…"} ],
  "tools": [ {"type": "function", "function": {"name": "read", "description": "…", "parameters": {…}}} ],
  "response": {"role": "assistant", "content": "…", "tool_calls": [ … ]},
  "finish_reason": "tool_calls",
  "usage": {"prompt_tokens": 1200, "completion_tokens": 80, "total_tokens": 1280},
  "metrics": {"time_to_first_token_ms": 340, "prompt_tokens_per_second": 1100, "generation_tokens_per_second": 38, "source": "llama.cpp"},
  "error": "",
  "ratings": [ … ],
  "turn_ratings": [ … ]
}
```

`ratings` are ratings that point at this call (a turn rating given on this
reply, or a model rating on it); `turn_ratings` are all turn ratings of the
turn the call belongs to. `task` is `chat` for the agent's own calls,
`permission` for the shell safety check (see [shell.md](shell.md)) and
`compaction` for summarizing a long conversation (below), and `explore` or
`build` for a subagent's calls (below); its `params`
include `chat_template_kwargs` when effort was `off` on llama.cpp.

#### Compaction

Every call is exported exactly as it was sent, so after a conversation is
compacted its `chat` calls carry the summary at the end of the system
message (under "Earlier in this session") and only the turns kept after it,
not the older messages. The summarization call itself is exported as its
own `model_call` with `task: "compaction"`: its messages are the system
prompt, tools and conversation up to the cut, as the chat calls saw them,
followed by a user message asking for the summary, and its `response` is
the summary. Its `turn_id` is the turn it happened in, or empty when it
ran between turns (`/compact` on an idle session). It is never part of a
`turn` record.

#### Subagents

A subagent (the agent tool) has its own conversation, so its calls are
exported as `model_call` records with `task: "explore"` or `"build"`: each
one's messages are the subagent's system prompt, its task as the user
message, and its own tool calls and results so far; the `response` includes
its `tool_calls`. They carry the `turn_id` of the turn that ran them and are
never part of a `turn` record. In that turn, the agent's call to the `agent`
tool and its result (the subagent's report) appear like any other tool call.

### `turn`

A whole turn as one conversation: the last call's request followed by its
response, so it includes every tool call and tool result in between.

```json
{
  "type": "turn", "format_version": 1,
  "turn_id": "msg_…", "branch_id": "br_…", "branch_head": true, "session_id": "ses_…", "project": {…},
  "created_at": "…", "provider": "llama", "model": "qwen3-coder", "reasoning_effort": "low",
  "model_calls": ["msg_…", "msg_…"],
  "messages": [ …system, user, assistant(tool_calls), tool, …, assistant(final)… ],
  "tools": [ … ],
  "finish_reason": "stop",
  "permission_checks": [
    {"tool_call_id": "c1", "command": "make build", "verdict": "safe", "reason": "builds the project",
     "provider": "llama", "model": "qwen3-4b", "model_call_id": "msg_…"}
  ],
  "ratings": [ … ]
}
```

A turn's conversation comes from its `chat` calls only (so a turn that was
compacted part way through shows the summary and the steps kept after it).
`branch_head` marks the last turn of a branch (see below): its `messages`
are that branch's whole conversation, as far as compaction left it.
`permission_checks`
are the safety check's verdicts (`safe`, `ask`, `block` or `error`) on the
turn's shell commands; each one's model call is a separate `model_call`
record with `task: "permission"`.

### `session`

A summary of a session: its turns, the models used, and all its ratings
(each with the `turn_id`/`model_call_id`/`branch_id` it rates; model
ratings given without a reply have neither).

```json
{
  "type": "session", "format_version": 1,
  "session_id": "ses_…", "project": {…}, "working_dir": "/home/me/app",
  "created_at": "…", "turns": ["msg_…"], "models": ["llama/qwen3-coder"],
  "ratings": [ … ],
  "branches": [
    {"id": "", "head_turn_id": "msg_…"},
    {"id": "br_…", "parent_id": "", "fork_seq": 41, "kind": "retry", "message_id": "msg_…",
     "head_turn_id": "msg_…", "head_branch_id": "br_…"}
  ]
}
```

### Branches

A session can fork: "retry from here" and "edit and resend" start a new
branch of the conversation (see [branches.md](branches.md)). In exports:

- Records carry `branch_id`, the branch the call or turn ran on. It is
  left out for the root branch, so a session that never forked exports as
  before.
- A turn is a user message answered on one branch. A retry answers the
  same user message again on another branch, so two `turn` records can
  share a `turn_id`; `(turn_id, branch_id)` identifies a turn.
- Turns before a fork are shared by the branches and written once, with
  their own ratings. Ratings are never copied onto other branches' turns
  or calls.
- **One conversation per branch**: the `turn` record with `branch_head`
  is the branch's last turn, and its messages run from the root (or the
  latest compaction summary on the branch's path) to the end of that
  branch. Keep only those (`jq 'select(.type == "turn" and
  .branch_head)'`) to get every branch as its own conversation without
  the shorter prefixes. A session that never forked has one head: its
  last turn.
- The `session` record lists `branches` when the session forked: each
  with its parent, `fork_seq` (the parent's events up to this seq are
  part of the branch), `kind` (`retry` or `edit`), the user message it
  was made from, and its head turn (`head_branch_id` names an ancestor
  when the branch has no turn of its own yet). The root branch has the
  empty id.
- A compaction belongs to the branch it ran on: branches forked before
  it keep their full history, branches forked after it inherit it. Its
  `model_call` record (task `compaction`) carries that `branch_id`.
- Filters (`--since`, `--model`, …) apply first: heads are the last turns
  among the exported calls.

### Ratings

```json
{"target": "turn"|"model", "rating": "good"|"bad", "note": "…", "client": "Pixel 9",
 "provider": "llama", "model": "qwen3-coder", "created_at": "…"}
```

## Redaction (`--redact`)

Meant for data that may become public. It replaces:

- each session's working directory with `<workdir>`, your home directory
  with `<home>`, and flit's data and config directories with
  `<flit-data>` / `<flit-config>` (other absolute paths, like `/usr/bin`,
  are left alone);
- strings that look like secrets with `<redacted>`: private key blocks,
  OpenAI/Anthropic-style `sk-…` keys, GitHub and GitLab tokens, Slack
  tokens, AWS access key ids, Google API keys, flit tokens, JWTs, bearer
  tokens, and values after `api_key`/`secret`/`token`/`password`/`auth`
  followed by `:` or `=`.

Redaction is pattern-based and can't catch everything (a password in
prose, a customer's name). Review an export before publishing it.
