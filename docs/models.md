# Models, providers and roles

flit talks to any OpenAI-compatible chat completions endpoint: llama.cpp's
`llama-server` (start it with `--jinja` so tool calls work), vLLM, Ollama's
`/v1`, OpenAI, OpenRouter and so on. This page covers everything about
choosing and tuning models. For the short version, see the
[README](../README.md#models).

- [Providers](#providers)
- [Limiting concurrent requests](#limiting-concurrent-requests)
- [Model discovery and corrections](#model-discovery-and-corrections)
- [Effort, favorites and per-task models](#effort-favorites-and-per-task-models)
- [Prompt appends](#prompt-appends)
- [Roles](#roles)
- [What every model call reports](#what-every-model-call-reports)

## Providers

Configure as many as you like and pick a default:

```yaml
providers:
  - name: local
    base_url: http://localhost:8080/v1
  - name: openai
    base_url: https://api.openai.com/v1
    api_key_env: OPENAI_API_KEY
agent:
  provider: local
  model: qwen3-coder
```

flit identifies itself as `flit/<version>`. A provider's `headers:` are sent
with every request to it and replace flit's own, e.g. a different
`User-Agent` for an endpoint that filters on it; `${VAR}` in a value is read
from the environment.

## Limiting concurrent requests

`concurrency` caps how many requests flit sends to each of a provider's models
at once, counted across all sessions, subagents, compaction, safety checks and
learning; calls over the limit wait their turn (the app shows "Waiting for a
turn on this model"), and stopping the turn stops the wait. A model under
`models:` can set its own, which wins; unset or 0 means no limit. Changes
apply live to the next call, without stopping calls already running.

```yaml
providers:
  - name: local                 # one big model at a time...
    base_url: http://localhost:8080/v1
    concurrency: 1
    models:
      qwen3-4b:
        concurrency: 8          # ...but a small one can take more
  - name: openrouter            # cloud: no limit
    base_url: https://openrouter.ai/api/v1
    api_key_env: OPENROUTER_API_KEY
```

## Model discovery and corrections

flit asks each provider's `/models` endpoint what it offers (with adapters for
OpenRouter, llama.cpp, including router mode, and gomodel) to learn context
windows and tool/reasoning support. There is no built-in model list. If a
provider reports something wrong or nothing at all, correct it in
`models.yaml` next to the config:

```yaml
local:                 # provider name
  qwen3-coder:         # model id
    context_length: 131072
    tools: true
    reasoning: true
    efforts: [low, medium, high]
```

## Effort, favorites and per-task models

Each session has a model and a reasoning effort, both switchable mid-session.
The model picker lists your favorites (star a model) and recently used models
first; both are kept on the server, so every device sees the same ones. For a
llama.cpp router, the picker can also load and unload models.

`agent.tasks` in the config can set a model per kind of work:

| Task | Used for |
|---|---|
| `chat` | new sessions |
| `permission` | rating shell commands before you're asked |
| `compaction` | writing the summary when a conversation is compacted |
| `explore`, `build` | the two kinds of [subagent](sessions.md#subagents) |
| `cron`, `webhook` | unattended runs that don't pick a model |
| `learning` | [manual self-learning](learning.md) |
| `planning`, `search` | features to come |

Small, fast models are plenty for `permission`, `compaction`, `cron` and
`explore`:

```yaml
agent:
  tasks:
    chat:       {provider: local, model: qwen3-coder, effort: medium}
    permission: {provider: local, model: qwen3-4b, effort: off}
    compaction: {provider: local, model: qwen3-4b, effort: off}
    explore:    {provider: local, model: qwen3-4b, effort: low}
```

## Prompt appends

Extra system prompt text per provider (`providers[].prompt_append`, applies
to all its models) or per model (`agent.model_prompt_appends`, keyed
`"provider/model"`). Useful for nudging a particular model.

## Roles

Roles are Markdown files in `roles/` next to the config. The body is added to
the system prompt; YAML frontmatter can set a default model and effort and a
memory file whose contents are included each turn:

```markdown
---
description: Careful reviewer
model: some-big-model
effort: high
memory_file: NOTES.md
---
Review changes for correctness first, style second.
```

flit ships four roles: `frontend-dev`, `backend-dev`, `pm` and `qa`. They set
no model, so sessions use the configured one. A file in `roles/` with the
same name (e.g. `roles/qa.md`) replaces the built-in role.

A session's role can be switched while it runs (e.g. plan as `pm`, then
build as `backend-dev`): tap the role in the chat's status strip, or type
`/role name` (`/role` alone opens the picker). From the next model call the
system prompt and memory file are the new role's; the model and effort follow
the new role's defaults unless you changed them in the session. Earlier
messages stay as they are, and the chat marks where the role changed.

## What every model call reports

Every model call reports context use, time to first token, and prompt and
generation speed (llama.cpp's own timings when it sends them, otherwise
measured by flit). The app shows these along with the model, effort and task
state, and the agent's todo list.
