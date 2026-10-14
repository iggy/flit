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
  "id": "msg_…", "session_id": "ses_…", "turn_id": "msg_…",
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
turn the call belongs to.

### `turn`

A whole turn as one conversation: the last call's request followed by its
response, so it includes every tool call and tool result in between.

```json
{
  "type": "turn", "format_version": 1,
  "turn_id": "msg_…", "session_id": "ses_…", "project": {…},
  "created_at": "…", "provider": "llama", "model": "qwen3-coder", "reasoning_effort": "low",
  "model_calls": ["msg_…", "msg_…"],
  "messages": [ …system, user, assistant(tool_calls), tool, …, assistant(final)… ],
  "tools": [ … ],
  "finish_reason": "stop",
  "ratings": [ … ]
}
```

### `session`

A summary of a session: its turns, the models used, and all its ratings
(each with the `turn_id`/`model_call_id` it rates; model ratings given
without a reply have neither).

```json
{
  "type": "session", "format_version": 1,
  "session_id": "ses_…", "project": {…}, "working_dir": "/home/me/app",
  "created_at": "…", "turns": ["msg_…"], "models": ["llama/qwen3-coder"],
  "ratings": [ … ]
}
```

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
