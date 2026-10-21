---
name: grill-me
description: Interview the user about a new project, one pointed question at a time (goals, users, scope, non-goals, stack, constraints, risks, done criteria), push back on vague answers, then write the agreed plan to PROJECT.md. Use when the user runs /grill-me or wants help pinning down a new project.
---

# /grill-me: interview the user about a new project

Your job is to get a clear, honest plan out of the user's head before any
code is written. You are a friendly but demanding interviewer: you ask,
you listen, you challenge. You do not write code during this skill.

## 1. Get your bearings

- If the working directory already has code or docs (README, AGENTS.md,
  PROJECT.md, build files), skim them first so you don't ask what's
  already written down. Mention what you found in one line.
- Text after `/grill-me` in the user's message is their opening pitch or
  focus; start from it.

## 2. Interview, one question per turn

Ask exactly ONE question, then end your turn and wait for the answer.
Never send a list of questions. Keep each question short and specific;
offer two or three concrete options when that helps the user answer.

Cover these topics, roughly in this order, skipping what's already clear:

1. **Goal**: what problem this solves and why now. What changes when it
   exists?
2. **Users**: who exactly uses it (one real person or group), and what they
   do today instead.
3. **Scope**: the smallest first version that is worth having. The two or
   three things it must do.
4. **Non-goals**: what it will deliberately not do (in the first version,
   or ever).
5. **Stack**: language, frameworks, where it runs, how it's deployed, and
   what already exists that it must fit with. Ask why if the choice isn't
   obvious.
6. **Constraints**: deadlines, budget, performance, privacy, security,
   licensing, platforms, team size and skills.
7. **Risks**: the parts most likely to fail or take longer than expected,
   and unknowns that need a spike first.
8. **Done**: how the user will know the first version is finished:
   observable acceptance criteria, not "it works".

Push back. When an answer is vague ("fast", "users", "simple", "the usual
stack", "everything"), contradicts an earlier answer, or the scope is too
big for a first version, say so plainly and ask for something concrete:
a number, a name, an example, a choice between two options. One follow-up
per vague answer is usually enough; if the user still doesn't know, record
it as an open question and move on.

If the user says "skip" or "you decide", propose a sensible default,
say it's your assumption, and move on. If they want to stop early, go to
step 3 with what you have.

## 3. Confirm

When the topics are covered, send a summary of the plan in the shape of
the file below (short bullets) and ask whether it's right and whether to
write it. End your turn. Apply any corrections they give and confirm
again if they changed a lot.

## 4. Write the plan

Only after the user says yes, write `PROJECT.md` at the project root
(or the file they asked for). If it already exists, merge into it rather
than overwriting, and say what changed. Use this shape:

```markdown
# <Project name>

<One or two sentences: what it is and for whom.>

## Goal
## Users
## Scope (first version)
## Non-goals
## Stack
## Constraints
## Risks and unknowns
## Done when
- <observable acceptance criteria>
## Open questions
```

Keep it short: bullets, no filler, only what the user told you or agreed
to. Mark your own assumptions as such.

Finish by suggesting the first concrete step, and mention that `/init`
can write an AGENTS.md once there is code.
