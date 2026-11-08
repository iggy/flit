# Running with llama.cpp

flit works with any OpenAI-compatible server, but llama.cpp gets extra
treatment because it's the usual choice for local models.

## Server setup

- Start `llama-server` with `--jinja` so tool calls work.
- Add `--slot-save-path DIR` to let flit save and restore each session's
  prompt cache (see below).
- Router mode is supported: the model picker can load and unload models.

```yaml
providers:
  - name: local
    base_url: http://localhost:8080/v1
```

## What flit does with it

- **Says why a call is waiting**: every slot busy with other requests, the
  model asleep or loading.
- **Shows prompt cache use**: how much of each prompt came from llama.cpp's
  cache.
- **Keeps each session's prompt cache between turns** (`llamacpp.kv_cache`,
  for servers started with `--slot-save-path`), so a long session doesn't
  re-read its whole prompt after other requests used the server. Save files
  are reused least-recently-used first (`llamacpp.kv_cache_files`, default 4);
  each holds a whole context and can be gigabytes, and llama.cpp can't delete
  them, so flit sticks to `flit-kv-0.bin` .. `flit-kv-<n-1>.bin`.
- **Answer now**: while a model is thinking, the app offers to cut the
  thinking short, on models where llama.cpp can do that.
- **Exact token counts** for [compaction](sessions.md#compaction) (its
  `input_tokens` endpoint and the slots' real `n_ctx`).
- **Prompt progress**: flit asks llama.cpp for it, so a long prompt keeps the
  [stall watchdog](troubleshooting.md#stalled-model-calls) fed and the app can
  show how far it has got.
- **Diagnoses stalls**: see [troubleshooting.md](troubleshooting.md).

## Tips

- One big model at a time? Set `concurrency: 1` on the provider and a higher
  number for small models. See [models.md](models.md#limiting-concurrent-requests).
- Use a small model (`agent.tasks`) for command rating, compaction and
  cron jobs. See [models.md](models.md#effort-favorites-and-per-task-models).
