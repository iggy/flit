---
name: init
description: Survey this repository and write or update its AGENTS.md (the instructions coding agents read). Use when the user runs /init or asks for an AGENTS.md.
---

# /init: write or update AGENTS.md

AGENTS.md sits at the repository root and tells coding agents how to work
here. flit reads it into your instructions at the start of every turn, so
everything in it costs context: keep it short and specific to this repo.

## 1. Survey the repo

Look before writing; don't guess.

- `list` the root and the main source directories (depth 2 or so).
- Read the README and any existing agent instructions: AGENTS.md,
  CLAUDE.md, .cursorrules, .cursor/rules/, .github/copilot-instructions.md,
  CONTRIBUTING.md.
- Read the build and dependency files (go.mod, package.json, pubspec.yaml,
  Cargo.toml, pyproject.toml, Makefile, Taskfile.yaml, justfile, ...) and
  the CI workflows (.github/workflows/, .gitlab-ci.yml, ...): they say how
  the project is really built, tested and linted.
- Skim a few representative source and test files for conventions:
  layout, naming, error handling, how tests are written.
- If it's a git repo, `git_log` shows recent work and commit style.

## 2. Draft AGENTS.md

Include only what an agent couldn't work out in a minute and would get
wrong otherwise:

- What the project is, in one or two sentences, and its layout if it
  isn't obvious (monorepo parts, where code vs generated code lives).
- Exact commands to build, test (all, and one test), lint/format and run,
  with the directory to run them from. Take them from CI and build files.
- Rules and conventions the code follows that aren't obvious: generated
  files not to edit, codegen steps, dependency policies, required checks.
- Gotchas: things that break in surprising ways.

Leave out generic advice ("write clean code"), things any agent knows, long
file-by-file tours, and anything you couldn't confirm in the repo. Prefer
short bullets and code blocks for commands. Aim for well under 200 lines.

## 3. Write it

- If there is no AGENTS.md at the repo root, write it.
- If AGENTS.md already exists, do NOT overwrite it straight away. Merge
  what's there with what you found (keep the user's own rules unless they
  are wrong), then end your turn: summarize what you'd add, change or
  remove and ask the user whether to write it. Write it only after they
  say yes, applying any changes they ask for.
- If the repo has a CLAUDE.md but no AGENTS.md, use CLAUDE.md as the
  starting point and say so; don't delete or change CLAUDE.md.

Text after `/init` in the user's message is extra guidance from the user
(e.g. what to focus on); follow it.

Finish with a short summary of what you wrote.
