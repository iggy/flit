# Phase 4 — Config, models & workspaces

**Goal:** make the app a place you can *configure* Hermes, not just talk to it —
provider keys, agent knobs, tools/MCP, projects.

**Reference:** `reference/02-rpc-index.md` §Config, §Models, §Tools, §Projects;
wire §9 (config.set for model).

## Provider & model management

### P4-01 — Provider key entry
`model.save_key` (add/update a provider API key) and `model.disconnect` (clear).
Wire into the Phase 1 model picker's "needs key" state so a provider can be
authenticated in-app. Secure entry; never log keys.

### P4-02 — Agent knobs
`config.set` for `reasoning` (effort), `fast` (service tier), `personality`/
`prompt` (system prompt / persona). A settings surface reading current values
from `session.info` / `config.get`.

## Tools & MCP

### P4-03 — Tools browser
`tools.list` / `tools.show` / `toolsets.list` — browse available tools and
toolsets with descriptions.

### P4-04 — Configure tools
`tools.configure` (multiplexer: enable/disable/reset toolsets) reflecting the
result (`enabled_toolsets`, `changed`, `missing_servers`, `info`).

### P4-05 — MCP & env reload
`reload.mcp` (with the `confirm_required` result flow) and `reload.env`. Surface
newly discovered MCP tools.

## Config editor

### P4-06 — Config viewer/editor
`config.show` (grouped human-readable), `config.get`/`config.set` for arbitrary
keys. A guarded editor (credential-warning result field), matching the desktop
settings page. `setup.status` / `setup.runtime_check` / `verification.status`
for a health panel.

## Projects (workspaces)

### P4-07 — Projects list & switch
`projects.list` / `projects.get` / `projects.set_active` / `projects.for_cwd` — a
workspace dropdown (the closest in-session analog to profiles, and one that
*does* work live). Show the active project.

### P4-08 — Project CRUD & folders
`projects.create` / `update` / `add_folder` / `remove_folder` / `set_primary` /
`archive` / `delete`; `projects.tree` (file tree), `projects.project_sessions`
(sessions in a project), `discover_repos`/`record_repos`.

**Exit criteria:** you can add a provider key, tune reasoning/persona, enable
tools, reload MCP, edit config, and manage projects/workspaces — all in-app.

> Open question #2 (roadmap): a dedicated `model.set` RPC would simplify P1-11/
> P4-01. Revisit with the Hermes team.
