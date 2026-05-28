---
name: to-plan
description: Produce the full plan.md at the repo root for a piece of work — the heavier sibling of to-scope. Runs the planning workflow end to end: clarify intent (RefineScope), branch, write plan.md (Context / vertical-slice Changes / Out of scope / Verification), reflect new conventions into CLAUDE.md/README, commit, and open a PR. Use when the user says "let's plan", "make a plan", "plan this", "to plan", "write the plan", or wants to turn a settled scope.md into an executable plan.
---

This skill produces **`plan.md` at the repo root** — the project's
source-of-truth plan that the user can read, edit, commit, and tick off
during implementation. It is the heavier sibling of `to-scope` (which writes
the lightweight `scope.md`) and the invokable entry point to the planning
workflow defined in the shared `~/.claude/CLAUDE.md`.

Where it sits in the chain:

- **`to-scope`** → `scope.md` — lightweight synthesis (Goals / Approach /
  Out of Scope / Notes). Optional first pass when the shape is still fuzzy.
- **`to-plan`** → `plan.md` — the full, executable plan (this skill).
- **`plan-to-issues`** → GitHub stories/tasks derived from `plan.md`.

You can run `to-scope` first to settle the rough shape, or skip straight to
`to-plan` for small or well-understood work.

## When to use this skill

Use it:

- Whenever the user asks for a plan, in any phrasing — "let's plan", "make a
  plan", "plan this", "to plan", "write the plan", "start a plan for …". If
  you are unsure whether they want a plan or a quick chat, default to using it
  — a stray `plan.md` is cheap; a lost audit trail is not.
- To escalate a settled `scope.md` into an executable `plan.md`.

Do **not** use it:

- For free-form chat that hasn't produced a candidate piece of work yet —
  discuss first, or run `to-scope`.
- To create the GitHub issues — that's `plan-to-issues`, which runs *after*
  `plan.md` exists.

## Process (the planning workflow)

This mirrors the six-step planning workflow in `~/.claude/CLAUDE.md`; that
file is the canonical version if the two ever drift.

1. **Clarify intent.** Use the `RefineScope` skill — at most 4 high-leverage
   questions, then recommend answers for the rest in one batch. Skip only if
   intent is already crystal clear. If a `scope.md` exists, read it first and
   build on it instead of re-asking what it already settles. Prefer exploring
   the codebase over asking when a question can be answered by reading code.

2. **Branch.** If this is a git repo, create a branch off `main` named
   `plan/<short-slug>` derived from the topic. If it is not a git repo, skip
   the branch (do **not** run `git init` without asking) but still continue.

3. **Write `plan.md` at the repo root** using the template below. This is the
   source of truth — overwrite if it exists (`plan.md` is branch-scoped). If
   the harness also hands you a working plan path (e.g.
   `~/.claude/plans/<slug>.md`), keep the two in sync, but the repo-root
   `plan.md` wins.

4. **Reflect the plan.** If it introduces new conventions, commands, or
   behaviors, update `CLAUDE.md`. If it changes user-facing behavior or
   install steps, update `README.md`. If neither applies, leave them alone.

5. **Commit and push.** Only if this is a git repo. One commit per logical
   step (the plan itself, then each reflection). Push with `-u`. **Confirm
   with the user before pushing.**

6. **Open a PR** against `main`. Only if the repo has a remote. Title from the
   slug; body = a 1–3 line summary plus a checklist of the in-scope items.
   **Confirm with the user before opening the PR.**

## Vertical slices over horizontal layers

Order the **Changes** by vertical slice, not by layer. The first chunk should
be the smallest end-to-end change that produces user-visible value (migration
+ service + endpoint + UI for *one* thing), not "all migrations, then all
services, then all UI". Name the exception in the plan if pure infrastructure
or a cross-layer refactor genuinely warrants a horizontal cut.

## Template

```markdown
# Plan: <title>

## Context

Why this change is being made — the problem or need it addresses, what
prompted it, and the intended outcome. A short paragraph.

## Decisions

Locked choices made with the user (numbered). Omit the section if none.

## Changes

The work as an ordered, checkboxable list of **vertical slices**. The first
item is the smallest end-to-end thing that works; each later slice follows
the same pattern. Use `- [ ]` so the user can tick items off during
implementation.

## Out of Scope

Things explicitly NOT being done — especially things a reader might
reasonably assume are included.

## Verification

How to test the change end to end — commands to run, tests to execute, MCP
tools or manual steps to confirm it works.
```

## Keeping `plan.md` honest

During implementation, tick off slices (`- [x]`) as they complete and record
any scope changes the user agrees to. The plan is the record of what was
built — after implementation it stays in the repo as that record; do not
delete it.

After writing `plan.md`, if the conversation has no good, descriptive name,
tell the user to run `/rename` and suggest a topic-relevant name. `/rename` is
UI-only and cannot be invoked by the agent — just prompt the user.
