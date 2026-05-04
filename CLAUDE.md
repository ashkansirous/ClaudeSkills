# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal collection of Claude Code skills. There is no build system, test suite, or runtime code — every skill is a markdown file that the Claude Code skill loader reads at startup.

## Repository layout

Each top-level directory is one skill and contains a single `SKILL.md`:

```
<skill-name>/
  SKILL.md
```

`SKILL.md` requires YAML frontmatter with `name` and `description`, followed by the skill body. The `description` field is load-bearing: it is the only signal Claude Code uses to decide whether to invoke the skill, so it must name the trigger conditions explicitly (e.g. "Use when user wants to stress-test a plan, get grilled on their design, or mentions 'grill me'"). Vague descriptions cause the skill to never fire.

## Distribution model

Skills are not installed by package manager. Users clone this repo to `~/.claude/skills-repo` and run the install snippet from `README.md`, which loops over every subdirectory containing a `SKILL.md` and links it into `~/.claude/skills/`. The snippet is idempotent — re-run it after `git pull` to pick up any new skills added to the repo. On Windows it tries `SymbolicLink` first and falls back to `Junction` when Developer Mode / elevation is unavailable; both behave identically for the skill loader.

Claude Code must be restarted after installing a new skill — the loader does not hot-reload.

## Adding a new skill

1. Create `<skill-name>/SKILL.md` at the repo root with the frontmatter shown above.
2. Add a bullet for it under "Skills" in `README.md`. The install snippet auto-discovers any folder with a `SKILL.md`, so no other README edits are needed.
3. Commit and push. Each install site then needs `git pull` + re-run of the install snippet + Claude Code restart.
