# Reference: Phase 6 wire shapes (memory, learning & rollback)

Concrete JSON-RPC frames for the learning journey, insights, project facts,
and git rollback/checkpoints. Grounded in the gateway handlers
(`hermes-agent/tui_gateway/server.py`, `agent/learning_graph.py`,
`agent/learning_graph_render.py`, `agent/learning_mutations.py`,
`agent/coding_context.py`, `tools/checkpoint_manager.py`). **Python wins.**

Envelope reminders:
- request: `{"jsonrpc":"2.0","id":"<str>","method":"<str>","params":{...}}`
- response: `{"jsonrpc":"2.0","id":"<str>","result":{...}}` or error.

---

## Learning / journey

### `learning.frames` (P6-01)
Params: `{"cols": int=80, "rows": int=24, "frames": int=48}`.

The gateway pre-renders a terminal animation (`frames[]` = ANSI grids) FOR THE
TUI. **The Flutter client ignores the `frames` grid entirely** and renders from
the structured fields instead. Request `frames: 2` to minimize payload (the
field is required; 2 is the minimum the renderer accepts).

Result (`render_frames`, server.py:17154):
```jsonc
{
  "frames": [ ... ],          // ANSI grid animation — IGNORE in Flutter
  "legend": [                 // build_legend
    {"glyph": "●", "style": "skill",  "label": "skills (12)"},
    {"glyph": "◆", "style": "memory", "label": "memories (4)"}
  ],
  "categories": [             // category_legend — colored skill categories
    {"glyph": "●", "color": "#RRGGBB", "label": "coding (5)"},
    {"glyph": "·", "color": "",        "label": "+3"}          // overflow row
  ],
  "buckets": [                // _bucket_rows — THE TIMELINE (oldest → newest)
    {
      "index": 0,
      "label": "Jul 2026",    // period label
      "date": "3 Jul 2026",   // formatted representative date, or "unknown"
      "skills": 3,
      "memories": 1,
      "total": 4,
      "category": "coding",   // dominant skill category, or null
      "color": "#RRGGBB",     // category color, or null
      "nodes": [              // _bucket_nodes — chronological within bucket
        {
          "id": "refactor-helper",           // skill: name; memory: "memory:<source>:<idx>"
          "glyph": "●",                       // ● skill, ◆ memory
          "label": "refactor-helper",         // truncated to ≤26 chars
          "fullLabel": "refactor-helper",     // untruncated
          "meta": "agent · 3 Jul 2026",       // source · date line
          "body": "",                          // memory chunk body (skills: "")
          "style": "skill"                     // "skill" | "memory"
        }
      ]
    }
  ],
  "summary": [                // build_summary — human lines
    "12 learned skills · 4 memories · 6 skill links",
    "2 memory↔skill links · busiest day 3 Jul 2026 · 4 learned"
  ],
  "axis": {"start": "oldest", "end": "now"},   // or formatted dates
  "count": 16,                // total node count
  "cols": 80,
  "rows": 24
}
```
Empty state: `buckets: []`, `count: 0`.

### `learning.detail` (P6-02)
Params: `{"id": "<node id>"}`. The id is a bucket node id (skill name, or
`memory:<source>:<idx>`).

Result (`node_detail`, server.py:17178):
```jsonc
// success:
{"ok": true, "kind": "skill", "id": "refactor-helper",
 "label": "refactor-helper", "content": "<full SKILL.md text>"}
// memory: kind "memory", label = first line (≤80 chars), content = raw chunk.
// failure:
{"ok": false, "message": "skill 'x' not found"}
```

### `learning.edit` (P6-02)
Params: `{"id": "<node id>", "content": "<new full text>"}`.
Result (`edit_node`, server.py:17200):
```jsonc
{"ok": true,  "message": "updated 'refactor-helper'"}
{"ok": false, "message": "edit failed"}
```

### `learning.delete` (P6-02)
Params: `{"id": "<node id>"}`. Skills are ARCHIVED (restorable via CLI),
memories are removed.
Result (`delete_node`, server.py:17189):
```jsonc
{"ok": true,  "message": "archived 'x' — restore with: hermes curator restore x"}
{"ok": false, "message": "'x' is pinned — unpin it first (…)"}
```

---

## Insights

### `insights.get` (P6-03)
Params: `{"days": int=30}` (rolling window).
Result (`insights.get`, server.py:16465):
```jsonc
{"days": 30, "sessions": 42, "messages": 318}
```
Error code `5017` when the analytics DB is unavailable — surface as an error.

---

## Project facts

### `project.facts` (P6-04)
Params: `{"cwd": "<path>"}` (optional; server resolves a default when omitted).
In Flutter, pass the selected project's `primary_path`.

Result (`project.facts`, server.py:6521 → `project_facts_for`):
```jsonc
{
  "facts": {                       // null when cwd is NOT a code workspace
    "root": "/home/me/repo",
    "manifests": ["pubspec.yaml", "package.json"],
    "packageManagers": ["dart", "npm"],
    "verifyCommands": ["flutter analyze", "flutter test"],
    "contextFiles": ["CLAUDE.md", "AGENTS.md"]
  }
}
```
`{"facts": null}` is a normal (non-error) result — render an empty state.

---

## Rollback / checkpoints (git safety net)

All three are SESSION-SCOPED: pass `{"session_id": "<live id>"}` (from
`activeSessionProvider.liveId`). The gateway derives the cwd + checkpoint store
from the session.

### `rollback.list` (P6-05)
Params: `{"session_id": "<live id>"}`.
Result (`rollback.list`, server.py:16493):
```jsonc
{
  "enabled": true,               // false → checkpointing off; checkpoints: []
  "checkpoints": [               // most recent first
    {"hash": "<full 40-char>", "timestamp": "2026-07-25T10:30:00+00:00",
     "message": "<checkpoint reason>"}
  ]
}
```
NOTE: the handler projects to exactly `hash` / `timestamp` / `message` (it drops
the manager's `short_hash`/`reason`/stat fields). Do not expect those.

### `rollback.diff` (P6-05)
Params: `{"session_id": "<live id>", "hash": "<hash>"}`.
Result (`rollback.diff`, server.py:16570):
```jsonc
{
  "stat": "<git --stat summary>",
  "diff": "<raw unified diff, truncated to 4000 chars>",
  "rendered": "<ANSI colorized diff>"     // OPTIONAL — Flutter renders `diff`, ignores this
}
```
Error `4014` when `hash` is missing.

### `rollback.restore` (P6-06)
Params: `{"session_id": "<live id>", "hash": "<hash>", "file_path": "<path>"}`.
`file_path` is OPTIONAL — omit for a full restore; include to restore one file.

Full restore is REJECTED (error `4009`) while a turn is running — the UI should
require an idle session before offering full restore. File-scoped restore is
always allowed.

Result (`rollback.restore`, server.py:16523):
```jsonc
// full restore:
{"success": true, "restored_to": "<8-char hash>", "reason": "<checkpoint reason>",
 "directory": "/home/me/repo", "history_removed": 4}   // # of chat turns dropped
// file-scoped restore adds "file": "<path>" and NO history_removed.
// failure:
{"success": false, "error": "Checkpoint 'x' not found"}
```
Requires a STRONG confirm dialog before calling (destructive; rewrites git +
drops chat history).
