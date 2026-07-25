# Phase 5 wire shapes (source-grounded from /z/projects/hermes-agent)

Working notes for implementation. Field names/types are grounded in the Python
gateway source; only use what's here. Envelopes per 03-mvp-wire-shapes.md.

## RPC: cron.manage (P5-01) — server.py:17127

Action multiplexer. Params: `action` (str, default "list"), `name` (str — used
as the JOB ID for remove/pause/resume, and as display name for add),
`schedule` (str, add only), `prompt` (str, add only).

- action=list → `{success: bool, count: int, jobs: [job]}`
- action=add → `{success, job_id, name, skill?, skills[], schedule, repeat, deliver, next_run_at, job, message}`
- action=remove → `{success, message, removed_job:{id,name,schedule}}`
- action=pause/resume → `{success, job}`
- ambiguous/not-found (inside _ok, not an rpc error):
  `{success:false, error, matches:[{id,name,schedule,next_run_at}]}`

job object fields: `job_id` (str, THE id — not `id`), `name` (str), `skill`
(str?), `skills` ([str]), `prompt_preview` (str, truncated 100 chars),
`model` (str?), `provider` (str?), `base_url` (str?), `schedule` (str, human
readable, "?" fallback), `repeat` (str), `deliver` (str, "local"),
`next_run_at` (str?), `last_run_at` (str?), `last_status` (str?),
`last_delivery_error` (str?), `enabled` (bool), `state` (str, e.g.
"scheduled"/"paused"), `paused_at` (str?), `paused_reason` (str?), and
conditionally `script`/`no_agent`/`enabled_toolsets`/`workdir`.
NOTE: no boolean `paused` — pause state = `state == "paused"` and/or `enabled == false`.

## RPC: prompt.background (P5-02) — server.py:12054

Requires session. Params: `session_id` (str, required), `text` (str, required
non-empty else err 4012). Result: `{task_id: str}` (task_id = "bg_" + 6 hex).

EVENT `background.complete` (emitted on the parent session_id):
`payload = {task_id: str, text: str}` (text = final response, or "error: ...").
Wire: `{"type":"background.complete","session_id":"<parent>","payload":{"task_id","text"}}`

## RPC: process.list / kill / stop / shell.exec (P5-03) — server.py:13757-13816, 17374

- process.list — requires session. Params: `session_id`. Result:
  `{processes: [entry]}`. entry: `session_id` (str, THE process id),
  `command` (str), `cwd` (str), `pid` (int?), `started_at` (str),
  `uptime_seconds` (int), `status` (str "running"/"exited"), `output_preview`
  (str), `output_tail` (str, up to 4000 chars), plus conditional
  `session_scoped`/`watch_patterns`/`watch_hit`/`notify_on_complete`/
  `exit_code` (int?)/`detached`.
- process.kill — requires session. Params: `session_id`, `process_id` (str,
  required non-empty else 4012; value = an entry's session_id). Not found → 4044.
  Result polymorphic by `status`: killed →
  `{status:"killed", session_id, completion_reason, termination_source, output}`;
  already_exited → `{status:"already_exited", exit_code?, output, ...}`;
  not_found → `{status:"not_found", error}`; error → `{status:"error", error}`.
- process.stop — no session, no params. Result: `{killed: int}`.
- shell.exec — Params: `command` (str, required non-empty else 4004). NO cwd/
  timeout params (cwd fixed, 30s timeout). Result: `{stdout: str, stderr: str,
  code: int}`. Blocked → 4005; timeout → 5002; error → 5003.

## RPC: plugins.manage (P5-08) — server.py:17295

Action multiplexer. Params: `action` (str, default "list").
- action=list → `{plugins:[row], user_count:int, bundled_count:int}`.
  row: `name` (str), `version` (str), `description` (str), `source` (str, one
  of "bundled"/"user"/"entrypoint"), `status` (str, one of "disabled"/
  "enabled"/"not enabled"). NOTE: no `enabled` bool — activation is `status`.
- action=toggle → Params: `name` (str, required else 4019), `enable` (bool,
  default false). Result: `{ok:true, unchanged:bool, name:str, plugin: row?}`.

## RPC: skills.manage / skills.reload (P5-09) — server.py:17211 / 17270

- skills.manage action=list → `{skills: {category: [skill-name-str]}}`
  (grouped by category; each skill is just a NAME string).
- action=search (param `query`) → `{results:[{name,description}]}`.
- action=browse (params `page` int, `page_size` int) →
  `{items:[{name,description,source,trust,identifier}], page, total_pages, total}`.
- action=inspect (param `query`=identifier) → `{info:{name,description,source,
  identifier,tags[],skill_md_preview?}}`.
- action=install (param `query`) → `{installed:true, name}`.
- skills.reload — no params. Result: `{output: str, result:{added:[{name,
  description}], removed:[{name,description}], unchanged:[str], total:int,
  commands:int}}`.

## Kanban REST (P5-05/06/07) — prefix /api/plugins/kanban/, most take ?board=<slug>

Auth handled by GatewayRestClient. Timestamps are int epoch seconds.

### P5-05 task authoring & flow
- POST /tasks — body CreateTaskBody: `title`* (str), `body?`, `assignee?`,
  `tenant?`, `priority` (int, 0), `workspace_kind` (str, "scratch"),
  `workspace_path?`, `parents` ([str], []), `triage` (bool, false),
  `idempotency_key?`, `max_runtime_seconds?` (int), `skills?` ([str]),
  `goal_mode` (bool), `goal_max_turns?` (int), `model_override?`,
  `provider_override?`. Response: `{task: Task?}` (+ optional `{warning}`).
- PATCH /tasks/{id} — body UpdateTaskBody (all optional): `status?`
  ("running" rejected 400), `assignee?` (""/null unassigns), `priority?` (int),
  `title?`, `body?`, `result?`, `block_reason?`, `summary?`, `metadata?`
  (dict), `model_override?`, `provider_override?`, `clear_model_override`
  (bool). Response: `{task: Task?}`. 409 on conflict/invalid transition.
- DELETE /tasks/{id} → `{deleted:true, task_id}`.
- POST /tasks/bulk — body: `ids`* ([str]), `status?`, `assignee?`,
  `priority?` (int), `archive` (bool), `result?`, `summary?`, `metadata?`,
  `reclaim_first` (bool), `model_override?`, `provider_override?`,
  `clear_model_override` (bool). Response: `{results:[{id,ok,error?}]}`.
- POST /tasks/{id}/comments — body: `body`* (str), `author?` ("dashboard").
  Response `{ok:true}`.
- POST /tasks/{id}/specify — body `{author?}` → `{ok,task_id,reason,new_title}`.
- POST /tasks/{id}/decompose — body `{author?}` →
  `{ok,task_id,reason,fanout:bool,child_ids:[str],new_title}`.
- POST /tasks/{id}/reassign — body `{profile?, reclaim_first:bool, reason?}` →
  `{ok:true,task_id,assignee?}`. 409 if running without reclaim_first.
- POST /tasks/{id}/reclaim — body `{reason?}` → `{ok:true,task_id}`. 409 if not claimable.
- GET /tasks/{id}/log — query `tail?` (int) → `{task_id,path,exists:bool,
  size_bytes:int,content:str,truncated:bool}`.
- GET /tasks/{id} detail — response `{task: Task, comments:[Comment],
  events:[Event], attachments:[Attachment], links:{parents:[str],children:[str]},
  child_results:[{id,title,status,latest_summary?,result?}], runs:[Run]}`.
- POST /links `{parent_id,child_id}` → `{ok:true}`; DELETE /links (QUERY params
  parent_id,child_id) → `{ok}`.

Task object (asdict, key fields): `id`,`title`,`body?`,`assignee?`,`status`,
`priority`(int),`created_at`(int),`started_at?`,`completed_at?`,`workspace_kind`,
`tenant?`,`result?`,`skills?`([str]),`session_id?`,`current_run_id?`, +injected
`age:{created_age_seconds?,started_age_seconds?,time_to_complete_seconds?}`,
`latest_summary?`; on board/detail also `link_counts:{parents,children}`,
`comment_count:int`, `progress:{done,total}?`.
Comment: `{id:int,task_id,author,body,created_at:int}`.
Event: `{id:int,task_id,kind,payload:dict?,created_at:int,run_id:int?}`.
Attachment: `{id:int,task_id,filename,content_type?,size:int,uploaded_by?,stored_path,created_at:int}`.
Run: `{id:int,task_id,profile?,step_key?,status,worker_pid?,started_at:int,
ended_at?,outcome?,summary?,metadata:dict?,error?, ...}`.

### P5-06 boards & fleet
- GET /boards — query `include_archived` (bool) → `{boards:[BoardMeta], current:str}`.
  BoardMeta: `slug,name,description,icon,color,default_workdir?,created_at?,
  archived:bool,db_path` + injected `is_current:bool, counts:{status:int},
  total:int, default_workspace_kind:str`.
- POST /boards — body `{slug*, name?, description?, icon?, color?,
  default_workdir?, switch:bool}` → `{board:BoardMeta, current}`.
- PATCH /boards/{slug} — body `{name?,description?,icon?,color?,default_workdir?}`
  (slug immutable) → `{board:BoardMeta}`.
- DELETE /boards/{slug} — query `delete` (bool) →
  `{result:{slug,action:"archived"|"deleted",new_path}, current}`.
- POST /boards/{slug}/switch → `{current:str}`.
- GET /stats → `{by_status:{status:int}, by_assignee:{assignee:{status:int}},
  oldest_ready_age_seconds:int?, now:int}`.
- GET /workers/active → `{workers:[Worker], count:int, checked_at:int}`.
  Worker: `{run_id:int,task_id,task_title,task_status,task_assignee?,profile?,
  worker_pid:int,started_at:int,claim_lock?,claim_expires?,last_heartbeat_at?,
  max_runtime_seconds?}`.
- GET /diagnostics — query `severity?` → `{diagnostics:[{task_id,task_title?,
  task_status?,task_assignee?,diagnostics:[Diagnostic]}], count:int}`.
  Diagnostic: `{kind,severity("warning"|"error"|"critical"),title,detail,
  actions:[{kind,label,payload,suggested:bool}],first_seen_at:int,
  last_seen_at:int,count:int,run_id:int?,data:dict}`.
- GET /runs/{id} → `{run:Run}`. GET /runs/{id}/inspect → live psutil stats
  (`{run_id,alive:bool,pid?,...}`). POST /runs/{id}/terminate — body `{reason?}`
  → `{ok:true,run_id,task_id}`. 409 already ended.
- POST /dispatch — query `dry_run` (bool), `max` (int, 8) → asdict(DispatchResult):
  `{reclaimed:int,promoted:int,spawned:[[task_id,assignee,workspace_path]],
  skipped_unassigned:[str],auto_assigned_default:[str],skipped_nonspawnable:[str],
  crashed:[str],auto_blocked:[str],timed_out:[str],stale:[str],rate_limited:[str],...}`.

### P5-07 orchestration & assignees
- GET /assignees → `{assignees:[{name:str,on_disk:bool,counts:{status:int}}]}`.
- GET /profiles → `{profiles:[{name,is_default:bool,model,provider,description,
  description_auto:bool,skill_count:int}]}` (string fields default "").
- PATCH /profiles/{name} — body `{description?}` ("" clears) →
  `{ok:true,profile,description}`.
- POST /profiles/{name}/describe-auto — body `{overwrite:bool}` →
  `{ok,profile,reason,description}`.
- GET /orchestration → `{orchestrator_profile,default_assignee,auto_decompose:bool,
  auto_promote_children:bool,resolved_orchestrator_profile,resolved_default_assignee,
  active_profile}`.
- PUT /orchestration — body (all optional) `{orchestrator_profile?,
  default_assignee?,auto_decompose?,auto_promote_children?}` → same shape as GET.
- GET /home-channels — query `task_id?` → `{home_channels:[{platform,chat_id,
  thread_id,name,subscribed:bool}]}`.
- POST/DELETE /tasks/{id}/home-subscribe/{platform} →
  `{ok:true,task_id,home_channel:{platform,chat_id,thread_id,name}}`.

## Deferred this pass (per user)
- P5-04 live WS feed to /api/plugins/kanban/events → keep poll-on-focus refresh.
- Kanban attachments upload/download (multipart + FileResponse) → follow-up.
