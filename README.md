# ClaudeSkills

My personal Claude Code config — skills, shared `~/.claude/CLAUDE.md` instructions, and shared `~/.claude/settings.json` — synced from one repo I clone everywhere.

## Layout

```
ClaudeSkills/
  install.ps1            # Windows installer
  install.sh             # macOS / Linux / WSL installer
  home/
    CLAUDE.md            # merged into ~/.claude/CLAUDE.md (marker-bracketed)
    settings.json        # deep-merged into ~/.claude/settings.json
  skills/
    grill-me/
      SKILL.md           # symlinked into ~/.claude/skills/grill-me/
    <next-skill>/
      SKILL.md
```

## Skills

- [`grill-me`](skills/grill-me/SKILL.md) — interview me about a plan/design until we reach shared understanding.
- [`quick-grill`](skills/quick-grill/SKILL.md) — fast variant of grill-me: at most 4 questions, then recommendations for the rest.
- [`to-scope`](skills/to-scope/SKILL.md) — synthesize current context into a lightweight `scope.md` at the repo root; precursor to the full `plan.md` workflow.

## Install

Clone once, then run the install script. Re-run after `git pull` to pick up new skills and propagate config changes — the script is idempotent.

### Windows (PowerShell 7+)

```powershell
git clone https://github.com/ashkansirous/ClaudeSkills.git "$env:USERPROFILE\.claude\skills-repo"
& "$env:USERPROFILE\.claude\skills-repo\install.ps1"
```

### macOS / Linux / WSL / Git Bash

```bash
git clone https://github.com/ashkansirous/ClaudeSkills.git ~/.claude/skills-repo
bash ~/.claude/skills-repo/install.sh
```

The Bash installer needs [`jq`](https://jqlang.github.io/jq/) for the `settings.json` merge.

Restart Claude Code afterwards so the skill loader picks up new entries.

## What the install script does

- **Skills** — symlinks each `<name>/` folder containing a `SKILL.md` into `~/.claude/skills/`. On Windows it tries `SymbolicLink` first (needs Developer Mode or elevation) and falls back to `Junction` otherwise; both behave identically for the skill loader.
- **`home/CLAUDE.md`** — merged into `~/.claude/CLAUDE.md` between `<!-- BEGIN ClaudeSkills shared instructions -->` and `<!-- END ClaudeSkills shared instructions -->` markers. Re-runs replace the block; anything outside the markers is left untouched.
- **`home/settings.json`** — JSON deep-merged into `~/.claude/settings.json`. Local values win on scalar conflict; arrays (e.g. `permissions.allow`) are unioned and de-duplicated. Nothing in your local settings is ever deleted.

## Adding a new skill

1. `mkdir skills/<skill-name>/`.
2. Write `skills/<skill-name>/SKILL.md` with frontmatter:

   ```markdown
   ---
   name: <skill-name>
   description: <one sentence — when should Claude use this?>
   ---

   <skill body>
   ```

3. Add a bullet for it under **Skills** above.
4. Commit and push.
5. On each install site: `git pull` in `~/.claude/skills-repo`, re-run the install script, restart Claude Code.
