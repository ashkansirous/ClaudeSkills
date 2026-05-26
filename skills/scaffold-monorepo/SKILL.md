---
name: scaffold-monorepo
description: Bootstrap a fresh monorepo skeleton (folder layout, root README/CLAUDE.md/AGENTS.md/.gitignore, git init, optional GitHub remote). Use when the user says "scaffold a monorepo", "start a new project", "init the repo", "bootstrap the project", or invokes `/scaffold-monorepo`.
---

This skill bootstraps the empty skeleton for a polyglot monorepo. It does
**not** scaffold any individual component (backend, frontend, IaC, etc.) —
those have their own skills (`scaffold-csharp-api`, `scaffold-react-app`,
`scaffold-iac`, `scaffold-github-actions`, `scaffold-genai-service`).

Run this **once** at the start of a new project, in an empty (or
near-empty) working directory.

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

3. **Write root files** (follow the conventions in the shared
   `home/CLAUDE.md` "Project scaffolding" section):

   - `README.md` — project name, one-line description, layout diagram,
     and a "Getting started" section that lists the component
     scaffolding skills the user will run next.
   - `CLAUDE.md` — project-specific guidance: this is a monorepo,
     backend lives in `/backend` (C# .NET), frontend in `/frontend` (TS
     + React), infra in `/infra` (Terraform), AI services in
     `/ai-services`. Each component has its own README.
   - `AGENTS.md` — body is exactly `@CLAUDE.md` (single line).
   - `.gitignore` — combine `Node.gitignore`, `VisualStudio.gitignore`,
     `Python.gitignore`, `Terraform.gitignore` from
     [github/gitignore](https://github.com/github/gitignore), plus OS
     noise (`.DS_Store`, `Thumbs.db`) and editor swap files. Match the
     existing IDE-folder convention; if none, ignore both `.vscode/`
     and `.idea/`.

4. **Initialize git** if `.git/` is not already present:

   ```bash
   git init -b main
   git add .
   git commit -m "chore: scaffold monorepo skeleton"
   ```

5. **Ask the user once** whether to create the GitHub remote now:

   - **Yes** → `gh repo create <name> --private --source=. --remote=origin --push`. Prefer `--private` unless the user says otherwise.
   - **No** → leave it local; remind them they can run `gh repo create` later.

6. **Tell the user what's next.** List the component scaffolding skills
   they can run in any order, and recommend starting with whichever
   component delivers the first vertical slice (per the vertical-slices
   rule in `home/CLAUDE.md`).

## Verification

- `tree -L 2` shows the four component folders and `.github/workflows/`.
- `git log --oneline` shows the initial scaffold commit.
- Root files exist and the `.gitignore` covers all four stacks.
