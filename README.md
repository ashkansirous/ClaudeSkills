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

The install snippets below loop over every subdirectory containing a `SKILL.md` and link it into `~/.claude/skills/`. They are idempotent — re-run after `git pull` to pick up any new skills added to the repo without editing the snippet.

### PowerShell (Windows)

```powershell
git clone https://github.com/ashkansirous/ClaudeSkills.git "$env:USERPROFILE\.claude\skills-repo"
$skillsDir = "$env:USERPROFILE\.claude\skills"
if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }
Get-ChildItem "$env:USERPROFILE\.claude\skills-repo" -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
  ForEach-Object {
    $target = Join-Path $skillsDir $_.Name
    if (Test-Path $target) { return }
    try   { New-Item -ItemType SymbolicLink -Path $target -Target $_.FullName -ErrorAction Stop | Out-Null }
    catch { New-Item -ItemType Junction     -Path $target -Target $_.FullName | Out-Null }
  }
```

`SymbolicLink` requires **Developer Mode** (Settings → Privacy & security → For developers) or an **elevated** PowerShell; without either, the script transparently falls back to `Junction`, which works without elevation and behaves identically for the skill loader.

### Bash (macOS / Linux / WSL / Git Bash)

```bash
git clone https://github.com/ashkansirous/ClaudeSkills.git ~/.claude/skills-repo
mkdir -p ~/.claude/skills
for dir in ~/.claude/skills-repo/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name=$(basename "$dir")
  target=~/.claude/skills/"$name"
  [ -e "$target" ] && continue
  ln -s "${dir%/}" "$target"
done
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
4. On each machine where the repo is installed: `git pull` in `~/.claude/skills-repo`, re-run the install snippet above (it skips existing skills and links any new ones), then restart Claude Code.
