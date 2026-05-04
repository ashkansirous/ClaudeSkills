# ClaudeSkills

My personal collection of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills.

## Layout

Each top-level directory is one skill, containing a `SKILL.md` with YAML frontmatter (`name`, `description`) and the skill body — Anthropic's standard skill layout.

```
ClaudeSkills/
  grill-me/
    SKILL.md
  <next-skill>/
    SKILL.md
```

## Skills

- [`grill-me`](grill-me/SKILL.md) — interview me about a plan/design until we reach shared understanding.

## Install

Clone the repo once, then symlink each skill folder into `~/.claude/skills/`. `git pull` keeps the live skills current.

### PowerShell (Windows)

```powershell
git clone https://github.com/ashkansirous/ClaudeSkills.git "$env:USERPROFILE\.claude\skills-repo"
New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\.claude\skills\grill-me" `
  -Target "$env:USERPROFILE\.claude\skills-repo\grill-me"
```

Symbolic links on Windows require either **Developer Mode** enabled (Settings → Privacy & security → For developers) or an **elevated** PowerShell. If neither is available, copy instead and re-copy after each `git pull`:

```powershell
Copy-Item -Recurse `
  "$env:USERPROFILE\.claude\skills-repo\grill-me" `
  "$env:USERPROFILE\.claude\skills\grill-me"
```

### Bash (macOS / Linux / WSL / Git Bash)

```bash
git clone https://github.com/ashkansirous/ClaudeSkills.git ~/.claude/skills-repo
ln -s ~/.claude/skills-repo/grill-me ~/.claude/skills/grill-me
```

Restart Claude Code after installing so the skill loader picks up the new entries.

## Adding a new skill

1. `mkdir <skill-name>/` at the repo root.
2. Write `<skill-name>/SKILL.md` with frontmatter:

   ```markdown
   ---
   name: <skill-name>
   description: <one sentence — when should Claude use this?>
   ---

   <skill body>
   ```

3. Commit and push.
4. On each machine where the repo is installed: `git pull` in `~/.claude/skills-repo`, then symlink (or copy) the new folder into `~/.claude/skills/` and restart Claude Code.
