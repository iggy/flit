# Reference: Kanban plugin REST surface

The kanban plugin is the **reference plugin integration** — it shows how a
plugin surfaces to a client. It exposes **no JSON-RPC**; its entire surface is a
FastAPI router mounted by the dashboard web server under the prefix
`/api/plugins/kanban/` (`_mount_plugin_api_routes`,
`hermes_cli/web_server.py:17281`, include at `:17389`; router in
`plugins/kanban/dashboard/plugin_api.py`). Same origin and same token as
`/api/ws`, so one connection config covers both.

**Auth:** same as other sensitive REST — `X-Hermes-Session-Token` header (token
mode) or session cookie (OAuth mode).

**Board scoping:** most endpoints take a `?board=<slug>` query. Omit for the
current board.

## The board model

`GET /api/plugins/kanban/board` returns the whole board in one call:

```jsonc
{
  "columns": [                       // fixed order:
    {"name":"triage",   "tasks":[ /* task */ ]},
    {"name":"todo",     "tasks":[]},
    {"name":"scheduled","tasks":[]},
    {"name":"ready",    "tasks":[]},
    {"name":"running",  "tasks":[]},
    {"name":"blocked",  "tasks":[]},
    {"name":"review",   "tasks":[]},
    {"name":"done",     "tasks":[]}
    // + "archived" when ?include_archived=true
  ],
  "tenants": ["…"],
  "assignees": ["default","research"],   // profile names
  "latest_event_id": 4211,               // cursor for the live feed (below)
  "now": 1783200000
}
```

Each task dict = the `Task` dataclass plus derived fields: `age`,
`latest_summary` (200-char preview), `link_counts {parents,children}`,
`comment_count`, `progress {done,total}|null`, optional `diagnostics`/
`warnings`. Query params on `/board` (`plugin_api.py:378-407`): `tenant`,
`include_archived`, `board`, `workflow_template_id`, `current_step_key` — flit
sends none of the last two yet
(`../updates/gateway-0.18-to-0.20-optional.md` §6).

## Live updates

`WS /api/plugins/kanban/events` — tails the append-only `task_events` table with
a `since` cursor (seed it from `latest_event_id`). This is the **client push
channel** for board changes. (Note: `gateway/kanban_watchers.py` is a *separate*
server-internal loop that delivers terminal events as chat messages to
platforms — not a client feed.)

## Endpoint catalog (grouped)

### Tasks
| Method | Path | Purpose |
|---|---|---|
| GET | `/tasks/{id}` | Detail drawer: task + comments + events + attachments + links + runs |
| POST | `/tasks` | Create. Body `CreateTaskBody {title*, body?, assignee?, tenant?, priority, workspace_kind, parents[], triage, skills?, ...}` |
| PATCH | `/tasks/{id}` | Update status/assignee/priority/title/body/result/block_reason (+ handoff summary) |
| DELETE | `/tasks/{id}` | Delete |
| POST | `/tasks/bulk` | One patch → many ids. Body `{ids[]*, status?, assignee?, priority?, archive?, ...}`; returns per-id `{id, ok, error?}` |
| POST | `/tasks/{id}/comments` | Add comment `{body*, author}` |
| POST | `/tasks/{id}/specify` | LLM flesh-out a triage task → todo |
| POST | `/tasks/{id}/decompose` | LLM decompose into child tasks |
| POST | `/tasks/{id}/reassign` | Reassign to a profile (409 if running without `reclaim_first`) |
| POST | `/tasks/{id}/reclaim` | Release a stuck claim |
| GET | `/tasks/{id}/log` | Worker stdout/stderr log (`?tail=<bytes>`) |
| POST | `/tasks/{id}/estimate` | Token/complexity estimate + one-line why for a stored task (`plugin_api.py:1811`); no client yet — see required-doc §8 |
| POST | `/estimate` | Same estimate for ad-hoc text, before the task exists (`plugin_api.py:1804`) |

### Links & attachments
| Method | Path | Purpose |
|---|---|---|
| POST/DELETE | `/links` | Create/remove parent↔child link |
| GET/POST | `/tasks/{id}/attachments` | List / upload (multipart, 25MB cap) |
| GET/DELETE | `/attachments/{id}` | Download bytes / delete |

### Boards
| Method | Path | Purpose |
|---|---|---|
| GET | `/boards` | List boards (+ current, counts) |
| POST | `/boards` | Create board (idempotent) `{slug*, name?, ...}` |
| PATCH | `/boards/{slug}` | Update display metadata (slug immutable) |
| DELETE | `/boards/{slug}` | Archive (or `?delete=true`) |
| POST | `/boards/{slug}/switch` | Set active board pointer |

### Fleet / runs / workers
| Method | Path | Purpose |
|---|---|---|
| GET | `/stats` | HUD stats (by_status, by_assignee, oldest_ready_age) |
| GET | `/assignees` | Profiles + counts (on_disk flag) |
| GET | `/diagnostics` | Fleet distress signals (crashes, stuck, hallucinations) |
| GET | `/workers/active` | Currently-running workers (pid, heartbeat, claim) |
| GET | `/runs/{id}` · `/runs/{id}/inspect` | Run lookup / deep inspect |
| POST | `/runs/{id}/terminate` | Terminate a running worker |
| POST | `/dispatch` | Manual dispatcher nudge (`?dry_run`, `?max`) |

### Profiles & orchestration (kanban's own views)
| Method | Path | Purpose |
|---|---|---|
| GET | `/profiles` | Roster for assignee/orchestrator pickers |
| PATCH | `/profiles/{name}` | Set/clear profile description |
| POST | `/profiles/{name}/describe-auto` | Auto-generate description via LLM |
| GET/PUT | `/orchestration` | Orchestration knobs (orchestrator_profile, auto_decompose, …) |
| GET | `/config` | `dashboard.kanban.*` defaults |
| GET | `/home-channels` | Configured home channels |
| POST/DELETE | `/tasks/{id}/home-subscribe/{platform}` | Sub/unsub task terminal events to a chat channel |

## MVP scope for kanban

The MVP kanban view (Phase 1) needs only: `GET /board` (render columns +
tasks), `GET /tasks/{id}` (tap a card → drawer), `PATCH /tasks/{id}` (move a card
between columns / change status), and ideally the `/events` WS for live updates.
Everything else is Phase 5.
