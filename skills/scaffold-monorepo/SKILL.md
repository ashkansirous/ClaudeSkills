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

## Fetch current docs before running

Before doing anything else, use the **context7 MCP** to pull the current
docs for any tool this skill will touch — at minimum:

- `gh` CLI (for the optional `gh repo create` step) — query
  `/cli/cli` or similar.
- `github/gitignore` templates — for the `.gitignore` step.

Do this even if you think you know the commands; tooling changes faster
than training data.

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
     skills.
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

4. **Initialize git** if `.git/` is not already present:

   ```bash
   git init -b main
   git add .
   git commit -m "chore: scaffold monorepo skeleton"
   ```

5. **Ask the user once** whether to create the GitHub remote now:

   - **Yes** → `gh repo create <name> --private --source=. --remote=origin --push`. Prefer `--private` unless told otherwise.
   - **No** → leave it local; mention they can run `gh repo create`
     later.

6. **Tell the user what's next.** List the component scaffolding skills
   they can run, and recommend starting with whichever delivers the
   first vertical slice (per the vertical-slices rule in
   `home/CLAUDE.md`).

## Verification

- `tree -L 2` shows the four component folders and `.github/workflows/`.
- `git log --oneline` shows the initial scaffold commit.
- Root files exist and `.gitignore` covers every stack in the monorepo.
