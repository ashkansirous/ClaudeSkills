# Plan: `plan-to-issues` skill

## Context

The repo has a planning chain — `to-scope` writes `scope.md`, the planning
workflow in `home/CLAUDE.md` writes `plan.md` — but no link that turns a
settled plan into trackable work. This skill adds that link: it projects
`plan.md`/`scope.md` onto GitHub's primitives so the work becomes discrete,
assignable, trackable items. GitHub has no literal "stories/tasks", so we map
**vertical slice → parent Issue (story)** and **step → native sub-issue
(task)**, and surface everything on a **Projects (v2) board**.

This is a config-repo change only: one new `SKILL.md`, a README bullet. No
runtime code.

## Decisions (confirmed with the user)

1. **Mapping** — vertical slice = parent Issue (story); step = native
   sub-issue (task). Milestones only if the plan groups slices into releases.
2. **Project board** — yes: add every issue to a Projects v2 board, set
   `Status` and a `Slice` field.
3. **Safety** — chat summary + confirm before any `gh` write; no preview file.

## Changes

- [x] Create `skills/plan-to-issues/SKILL.md` (frontmatter with trigger-naming
  description; body: intro → When to use → Preconditions (HARD: plan.md exists,
  gh auth, context7/`gh` docs for issue/sub-issue/project commands) → Process
  (parse → metadata → pick board → idempotency check → chat-confirm → create
  stories/sub-issues/board items → write-back & report) → Verification).
- [x] Add a `plan-to-issues` bullet under **Skills** in `README.md`, after
  `to-scope` (same planning chain).
- [x] Write this `plan.md` at the repo root.
- [ ] Branch `feat/plan-to-issues`, commit (plan.md, then skill + README),
  push `-u`, open PR against `main` — after user confirms.

## Out of scope

- No preview artifact file (user chose chat-summary-and-confirm).
- No auto-assignment of people; no estimates/points unless the plan has them.
- Skill does not write/modify plan content (aside from optional issue-number
  write-back for traceability).
- GitHub only — no Jira/Linear/etc.

## Verification

- `SKILL.md` has valid `name`/`description` frontmatter; description names the
  trigger phrases.
- README bullet renders and links correctly.
- After `install.ps1` + Claude Code restart, the skill is invocable; a real run
  against a test repo creates stories + sub-issues on a board, with no
  duplicates on re-run.
