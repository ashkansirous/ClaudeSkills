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
- [`scaffold-monorepo`](skills/scaffold-monorepo/SKILL.md) — bootstrap a polyglot monorepo skeleton (folders, root README/CLAUDE.md/AGENTS.md/.gitignore, root `docker-compose.yml` for local dev, git init, optional GitHub remote).
- [`scaffold-csharp-api`](skills/scaffold-csharp-api/SKILL.md) — drop a layered C# .NET Web API under `/backend` (Domain / Application / Infrastructure / Api projects) with a health endpoint, Dockerfile, and xUnit tests; version fetched live via context7.
- [`scaffold-react-app`](skills/scaffold-react-app/SKILL.md) — drop a TypeScript + React Vite app under `/frontend` with ESLint and a thin-`App.tsx` health page (page + hook + api client) wired to the backend; versions fetched live via context7.
- [`scaffold-iac`](skills/scaffold-iac/SKILL.md) — scaffold Terraform under `/infra` for GCP or AWS (provider chosen at invocation time), with remote state, container hosting, static site, secrets, and OIDC for CI.
- [`scaffold-github-actions`](skills/scaffold-github-actions/SKILL.md) — generate GitHub Actions workflows under `.github/workflows/` for whichever monorepo components exist; builds and pushes backend/ai-service images to GHCR (via `GITHUB_TOKEN`), syncs the frontend static bundle, OIDC for cloud deploy.
- [`scaffold-genai-service`](skills/scaffold-genai-service/SKILL.md) — scaffold a GenAI/LLM service under `/ai-services/<name>/` with the Anthropic SDK and prompt caching wired up.
- [`implement-infrastructure`](skills/implement-infrastructure/SKILL.md) — add resources/modules to an existing Terraform setup; detects GCP vs AWS and fetches current provider docs via context7.
- [`implement-backend`](skills/implement-backend/SKILL.md) — implement backend features as vertical slices in the existing /backend (C# or Python); fetches current framework docs via context7.
- [`implement-frontend`](skills/implement-frontend/SKILL.md) — implement UI features in the existing /frontend React + TypeScript app; detects libraries already in use, enforces ESLint.
- [`implement-tests`](skills/implement-tests/SKILL.md) — write tests for existing code in any stack (xUnit / pytest / Vitest / Playwright / etc.); detects the framework and applies its idioms.
- [`implement-e2e-tests`](skills/implement-e2e-tests/SKILL.md) — write end-to-end UI tests with Playwright (page-object model, accessible-name selectors, trace-on-failure); prefers the Playwright MCP when registered, falls back to standalone `@playwright/test` otherwise.

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
