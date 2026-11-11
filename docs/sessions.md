# Sessions, tools and long conversations

A session is a conversation with the agent in one working directory. This
page covers how sessions behave in detail. For the short version, see the
[README](../README.md#how-sessions-work).

- [Tools](#tools)
- [Queued messages](#queued-messages)
- [Subagents](#subagents)
- [Compaction](#compaction)
- [The event log](#the-event-log)
- Related: [shell approval rules](shell.md), [conversation branches](branches.md),
  [git changes](git.md), [language server diagnostics](lsp.md)

## Tools

The agent has `read`, `write`, `patch`, `list`, `grep` and `shell` tools; file
tools can't leave the working directory. `AGENTS.md` and `CLAUDE.md` in the
working directory are added to the system prompt.

Beyond those: **git** tools (status, diff, log, commit; nothing pushes),
**web_fetch**, **web_search** through a SearXNG instance (`web.search`; paid
search APIs aren't supported), a `todo` list, a `status` tool that sets the
one-line status shown on the session's card, a `cron` tool, the `agent` tool
for subagents, [MCP](mcp.md) tools and [skills](skills.md).

Shell commands are split into their parts (chains, pipes, loops) and run
without asking when every part is allowed: by `shell.allow` patterns, the
built-in read-only list (`ls`, `cat`, `grep`, `git log`, ...), or "allow for
this session". `shell.deny` always wins. Anything else follows
`shell.default` (`ask` by default), which pauses the turn until a client
answers the prompt. A session can switch to yolo mode (everything but deny
matches runs), and an optional small model can rate commands before you're
asked. These rules reduce prompts; they are not a sandbox. See
[shell.md](shell.md).

Long commands run as **background jobs** (the agent asks with `background:
true`, or a command moves there after `shell.background_after`, 60s by
default). The agent's `job` tool checks on, waits for or cancels them, and
when one ends the agent gets a notice, starting a turn if none is running.
See [background jobs](shell.md#background-jobs).

## Queued messages

You can keep typing while the agent works: a message sent mid-turn is
queued and joins the conversation at the agent's next step (after the
current model call or tool, before the next call), or starts the next turn
if the agent was finishing. Queued messages show in every client and can be
edited or cancelled until then. Stop keeps them queued; they go out first
with your next message (or press Send with an empty box).

## Long turns

A turn runs until the agent is done or you stop it; there is no step cap.
Every `agent.long_turn_steps` model calls (default 50) flit records a
`long_turn` event: the app shows a note in the chat and a local
notification (with notifications on), and `notify.ntfy`, if set, gets a
post. The turn goes on; the note is for you to look in and decide whether
it is working hard or going round in circles. Subagents do the same every
`agent.subagents.long_turn_steps` calls (default 20).

## Subagents

The agent can hand a self-contained task to a **subagent** with the `agent`
tool. A subagent starts with an empty context (a short system prompt and the
task), works until it's done (see [long turns](#long-turns)), and only its
final report goes back
into the agent's context, which keeps that context small. There are two
kinds:

- **explore** only reads: `read`, `list`, `grep`, `git_status`/`diff`/`log`,
  `web_fetch`/`web_search`, and `shell` limited to the built-in read-only
  commands (`shell.deny` still applies; allow patterns, "allow for this
  session" and yolo don't widen it). Write tools and MCP tools aren't
  offered, and it never asks you anything.
- **build** has the session's tools (MCP servers included) and the
  project's `AGENTS.md`. Its shell commands go through the session's rules,
  safety check, yolo mode and prompts exactly like the agent's own; prompts
  show in the session as usual.

Subagents can't start subagents, and don't get `todo`, `status` or skills. They run on
`agent.tasks.explore` / `agent.tasks.build` when set, otherwise on the
session's model. Stopping the turn stops the subagent. Everything a subagent
does is in the session's event log (`subagent_started`, its events wrapped in
`subagent_event`, `subagent_done`), so it replays; the app shows it as a card
with the kind, model and status that expands to its tool calls and report.
`agent.subagents.enabled: false` turns the tool off.

## Compaction

Long conversations are compacted so they keep fitting the model's context.
Before a model call that would fill `agent.compaction.threshold` of the
context window (0.8), flit has a model (`agent.tasks.compaction`, or the
session's own) summarize the older part, and from then on sends the summary,
in the system prompt, plus the latest `agent.compaction.keep_turns` turns
(2) word for word. A single turn too big for that is cut between its steps
instead, keeping the request it's working on. Token counts are exact on
llama.cpp (its `input_tokens` endpoint, and the slots' real `n_ctx`) and
estimated elsewhere (about 4 characters a token); a model whose window the
catalog doesn't know isn't compacted automatically (set `context_length` in
`models.yaml`). `/compact` in the app (or the `Compact` RPC) does it on
demand, with optional instructions (`/compact keep the API details`). The
summary is capped at `agent.compaction.max_summary_tokens` (4096); if it
fails, the session carries on with its full history. Nothing is deleted:
the log records each compaction (summary, the last event it covers, tokens
before and after, model, automatic or not), the app marks it in the chat
with the older messages greyed out above, and a saved llama.cpp prompt cache
from before it is dropped instead of restored. `agent.compaction.auto:
false` leaves only `/compact`.

## The event log

Everything a session does is stored as numbered events in `flit.db` in the
data dir. A client can attach from any event number, replay, and then follow
live, so reconnecting never loses anything. That's also why every paired
device sees the same conversation.
