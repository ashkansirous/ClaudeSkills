---
name: scaffold-monorepo
description: Bootstrap a fresh polyglot monorepo skeleton — folder layout (/backend, /frontend, /infra, /ai-services, /.github/workflows), root README/CLAUDE.md/AGENTS.md/.gitignore, git init, and optional GitHub remote. Run ONCE at the start of a new project in an empty working directory. Triggers: "scaffold a monorepo", "start a new project", "init the repo", "bootstrap the project", or invocation as `/scaffold-monorepo`.
---

This skill bootstraps the empty skeleton for a polyglot monorepo. It does
**not** scaffold any individual component (backend, frontend, IaC, etc.) —
those have their own skills (`scaffold-csharp-api`, `scaffold-react-app`,
`scaffold-iac`, `scaffold-github-actions`, `scaffold-genai-service`).

## When to use this skill

Invoke this skill **only**:

- At the very start of a new project, in an empty (or near-empty) working
  directory.
- When the user wants the monorepo *shell* — folders, root files, git
  init — before any component code exists.

Do **not** invoke this skill:

- If the working directory already has scaffolded components (run the
  component skills directly instead).
- For adding a new component to an existing monorepo — those are
  separate skills.

## Fetch current docs before running — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not**
run `git init`, `gh repo create`, or write any tracked file in this
skill until you have logged context7 queries against:

- `gh` CLI (for the optional `gh repo create` step) — query
  `/cli/cli` or similar.
- `github/gitignore` templates — for the `.gitignore` step.
- The Compose file spec — query `/compose-spec/compose-spec` (or
  `/docker/compose`) — for the root `docker-compose.yml` schema
  (top-level `services`, `build`, `volumes`, `develop.watch`, etc.).
  The spec dropped the `version:` key and changed several fields; do
  not write it from memory.

State the library IDs you're about to query before calling, so the
user sees the rule being followed. Do this even if you think you know
the commands; tooling changes faster than training data, and "I know
git" is exactly the rationalization the rule exists to defeat.

## Process

1. **Safety check.** Verify the working directory is empty or only
   contains files like `.git`, `.idea`, `.vscode`, `README.md` from a
   freshly cloned empty repo. If anything else exists, stop and ask
   before overwriting.

2. **Create the folder skeleton:**

   ```
   backend/
   frontend/
   infra/
   ai-services/
   .github/workflows/
   ```

   Leave them empty — component skills will fill them.

3. **Write root files** (follow `home/CLAUDE.md` "Project scaffolding"):

   - `README.md` — project name, one-line description, layout diagram,
     and a "Getting started" section listing the component scaffolding
     skills. Include a "Local development" line: `docker compose up`
     boots the whole stack once components are scaffolded.
   - `CLAUDE.md` — project-specific guidance: this is a monorepo;
     backend in `/backend`, frontend in `/frontend`, infra in `/infra`,
     AI services in `/ai-services`. Each component has its own README.
   - `AGENTS.md` — body is exactly `@CLAUDE.md` (single line).
   - `.gitignore` — combine the gitignore templates from
     [github/gitignore](https://github.com/github/gitignore) for every
     stack in this monorepo (Node, VisualStudio, Python, Terraform),
     plus OS noise (`.DS_Store`, `Thumbs.db`) and editor swap files.
     Ignore both `.vscode/` and `.idea/` unless the user has a
     pre-existing convention.
   - `docker-compose.yml` — the local-dev orchestration file (see step
     4). Per `home/CLAUDE.md` "Dockerization & build artifacts", this
     exists from day one and component scaffolds fill in their
     services.

4. **Write the root `docker-compose.yml`.** It starts essentially
   empty — a `services:` map with commented placeholders — and each
   component scaffold uncomments / adds its own entry:

   ```yaml
   # Local dev for the whole stack. `docker compose up` once components exist.
   # Each component scaffold fills in its service:
   #   scaffold-csharp-api      -> backend         (build: ./backend)
   #   scaffold-genai-service   -> <service-name>  (build: ./ai-services/<name>)
   #   scaffold-react-app       -> frontend        (node dev container, no Dockerfile)
   services: {}
   ```

   Notes that belong in a comment at the top of the file:
   - No top-level `version:` key — the current Compose spec dropped it.
   - Backend-type services use `build: ./<dir>` pointing at the
     component's `Dockerfile`.
   - The frontend has **no** production Dockerfile (it ships as a
     static bundle); in compose it runs as a stock `node:lts-alpine`
     dev container with a bind mount — `scaffold-react-app` adds that
     entry.
   - No database/cache service by default; add one only when a
     component needs it.

5. **Initialize git** if `.git/` is not already present:

   ```bash
   git init -b main
   git add .
   git commit -m "chore: scaffold monorepo skeleton"
   ```

6. **Ask the user once** whether to create the GitHub remote now:

   - **Yes** → `gh repo create <name> --private --source=. --remote=origin --push`. Prefer `--private` unless told otherwise.
   - **No** → leave it local; mention they can run `gh repo create`
     later.

7. **Tell the user what's next.** List the component scaffolding skills
   they can run, and recommend starting with whichever delivers the
   first vertical slice (per the vertical-slices rule in
   `home/CLAUDE.md`).

## Verification

- `tree -L 2` shows the four component folders and `.github/workflows/`.
- `git log --oneline` shows the initial scaffold commit.
- Root files exist and `.gitignore` covers every stack in the monorepo.
- `docker-compose.yml` exists at the root and passes
  `docker compose config` (an empty/placeholder `services:` map is
  valid — it fills in as components are scaffolded).
