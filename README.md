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
    RefineScope/
      SKILL.md           # symlinked into ~/.claude/skills/RefineScope/
    <next-skill>/
      SKILL.md
```

## Skills

- [`RefineScope`](skills/RefineScope/SKILL.md) — interview me with at most 4 high-leverage questions about a plan/design, then recommend answers for the rest in one batch (the "clarify intent" step of the planning workflow).
- [`to-scope`](skills/to-scope/SKILL.md) — synthesize current context into a lightweight `scope.md` at the repo root; precursor to the full `plan.md` workflow.
- [`scaffold-monorepo`](skills/scaffold-monorepo/SKILL.md) — bootstrap a polyglot monorepo skeleton (folders, root README/CLAUDE.md/AGENTS.md/.gitignore, git init, optional GitHub remote).
- [`scaffold-csharp-api`](skills/scaffold-csharp-api/SKILL.md) — drop a C# .NET 10 Web API under `/backend` with a health endpoint, Dockerfile, and xUnit tests.
- [`scaffold-react-app`](skills/scaffold-react-app/SKILL.md) — drop a TypeScript 6 + React 19 Vite app under `/frontend` with ESLint and a sample page that hits the backend health endpoint.
- [`scaffold-iac`](skills/scaffold-iac/SKILL.md) — scaffold Terraform under `/infra` for GCP or AWS (provider chosen at invocation time), with remote state, container hosting, static site, secrets, and OIDC for CI.
- [`scaffold-github-actions`](skills/scaffold-github-actions/SKILL.md) — generate GitHub Actions workflows under `.github/workflows/` for whichever monorepo components exist; OIDC cloud auth, no long-lived secrets.
- [`scaffold-genai-service`](skills/scaffold-genai-service/SKILL.md) — scaffold a GenAI/LLM service under `/ai-services/<name>/` with the Anthropic SDK and prompt caching wired up.

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
