# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal Claude Code config repo. It owns three things, all synced from one place to every machine I work on:

- **Skills** — one per top-level folder containing a `SKILL.md`.
- **Shared user instructions** — `home/CLAUDE.md`, merged into `~/.claude/CLAUDE.md` at install time.
- **Shared user settings** — `home/settings.json`, deep-merged into `~/.claude/settings.json` at install time.

There is no build system, test suite, or runtime code. The install scripts are the only "code" in the repo.

## Repository layout

```
install.ps1          # Windows installer
install.sh           # macOS / Linux / WSL installer
home/
  CLAUDE.md          # merged into ~/.claude/CLAUDE.md (marker-bracketed)
  settings.json      # deep-merged into ~/.claude/settings.json
skills/
  <skill-name>/
    SKILL.md         # symlinked into ~/.claude/skills/<skill-name>/
```

`SKILL.md` requires YAML frontmatter with `name` and `description`, followed by the skill body. The `description` field is load-bearing: it is the only signal Claude Code uses to decide whether to invoke the skill, so it must name the trigger conditions explicitly (e.g. "Use when user wants to stress-test a plan, get grilled on their design, or mentions 'grill me'"). Vague descriptions cause the skill to never fire.

## Distribution model

Users clone the repo to `~/.claude/skills-repo` and run `install.ps1` (Windows) or `install.sh` (Unix). The script is idempotent — re-run after `git pull` to pick up new skills and propagate updates to `home/CLAUDE.md` / `home/settings.json`. Claude Code must be restarted afterwards; the skill loader does not hot-reload.

Merge semantics on install:

- **Skills** — symlinked. On Windows, tries `SymbolicLink` first and falls back to `Junction` when Developer Mode / elevation is unavailable; both behave identically for the loader.
- **`home/CLAUDE.md`** — wrapped between `<!-- BEGIN ClaudeSkills shared instructions -->` / `<!-- END ClaudeSkills shared instructions -->` and either replaced (if markers exist) or appended (if they don't). Anything outside the markers in the user's local `~/.claude/CLAUDE.md` is preserved.
- **`home/settings.json`** — JSON deep-merge. Local values win on scalar conflict; arrays are unioned and de-duplicated. Nothing in the local file is ever deleted.

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with the frontmatter shown above.
2. Add a bullet for it under "Skills" in `README.md`.
3. Commit and push. On each install site: `git pull`, re-run the install script, restart Claude Code.

## Changing shared instructions or settings

Edit `home/CLAUDE.md` or `home/settings.json`, commit, push. On each install site: `git pull`, re-run the install script.
