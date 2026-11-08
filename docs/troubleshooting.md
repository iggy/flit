# Troubleshooting a stuck turn

## Stalled model calls

Model calls have a watchdog: a call that goes quiet for
`agent.model_first_token_timeout` (10m) before the model starts answering,
or `agent.model_stall_timeout` (2m) once it has, is stopped, and one that
produced nothing yet is retried `agent.model_retries` times (1). With
llama.cpp, flit asks for prompt progress, so a long prompt keeps the
short limit fed and the app can show how far it has got. While a call waits,
the app shows the elapsed time, and after a minute of silence offers Retry
and Stop. Set a limit to `0` to turn it off.

## Where did it get stuck? `flit debug session`

Each call's timeline (sent, first byte, first token, last byte, how
it ended) is in the log. `flit debug session ID` prints a session's
timeline and what never finished, to see whether a stuck turn was waiting
on the model, cut off mid-reply, or stuck in a tool.

## llama.cpp stall diagnostics

When a llama.cpp call stalls, fails or is retried, flit asks the server
what it was doing before giving up on the request (model state, and each
slot sampled twice, 2s apart) and logs it with the call, so the timeline
says which layer was stuck:

- llama.cpp still generating while nothing reached flit: the router, a
  proxy or the network;
- llama.cpp itself making no progress: the model or GPU;
- the model reloaded or gone.

## What is the server doing right now? `flit debug dump`

`flit debug dump` asks the running server (admin token) what it is doing
right now: each session's model call in flight and its phase, the running
tool, the concurrency limits in use, whether each session's lock can be
taken, and, with `--stacks` or when a lock is held, every goroutine's stack.

## Other things to check

- **Server log**: `log.level: debug` in the config (applies live).
- **Can't pair or connect from a phone**: see
  [pairing and remote access](../README.md#pairing-and-remote-access).
- **Tool calls never happen**: with llama.cpp, start the server with
  `--jinja`.
