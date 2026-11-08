# Skills

Skills in the [Agent Skills](https://agentskills.io) format are directories
with a `SKILL.md` that teach the agent a procedure. The model sees each
skill's name and description and loads its instructions and files only when
needed, so skills cost almost nothing until used.

## Where skills come from

- **The repo a session works in**: `.agents/skills/`, and `.claude/skills/`
  for compatibility, at the working directory and at the git root.
- **Global skills**: `skills/` next to the config (`skills_dirs` in the
  config changes the list).

A repo skill wins over a global one with the same name.

## Using a skill

A message starting with `/<skill>` asks for that skill. The app's composer
suggests skills when you type `/`.

## Built in

flit ships two:

- **/init** surveys the repo and writes or updates its `AGENTS.md`, asking
  before it changes an existing one.
- **/grill-me** interviews you about a new project one question at a time
  (goals, users, scope, non-goals, stack, constraints, risks, what "done"
  means), pushes back on vague answers, and writes the agreed plan to
  `PROJECT.md` once you confirm it.

See also [learning.md](learning.md): flit can propose a new skill after a
session.
