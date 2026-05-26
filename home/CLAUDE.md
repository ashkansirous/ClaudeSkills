# Shared user instructions

These apply to every project on machines where ClaudeSkills is installed. Synced from `~/.claude/skills-repo/home/CLAUDE.md` via the repo's install script.

## Planning workflow

When the user explicitly kicks off planning with one of the phrases `let's plan ...`, `start a plan for ...`, or `plan this ...`, follow these six steps:

1. **Clarify intent.** Use the `RefineScope` skill to interview the user about goals and main purpose (at most 4 questions, then recommendations for the rest) until you reach shared understanding. Skip only if intent is already crystal clear from the user's message.
2. **Branch.** Create a new branch from `main` named `plan/<short-slug>` derived from the topic.
3. **Write the plan.** Save it to `plan.md` at the repo root. Overwrite if it exists — `plan.md` is branch-scoped.
4. **Reflect the plan.** If the plan introduces new conventions, commands, or behaviors, update `CLAUDE.md`. If it changes user-facing behavior or install steps, update `README.md`. If neither applies, leave them alone.
5. **Commit and push.** One commit per logical step (the plan itself, then each reflection). Push the branch with `-u` to set upstream.
6. **Open a PR** against `main`. Title from the plan slug. Body = a 1-3 line summary plus a checklist of in-scope items from the plan.

Confirm with the user before pushing or opening the PR.

## Task breakdown: vertical slices over horizontal layers

When breaking work into chunks — whether writing `plan.md`, writing `scope.md`, or creating tasks — default to **vertical slices** over **horizontal layers**.

A vertical slice is the smallest end-to-end change that produces user-visible value. For a full-stack feature, that means: migration + entity + repository + service + API endpoint + UI for **one** thing, all the way through, before starting the next slice. A horizontal slice would be: ten migrations, then ten repositories, then ten services. Vertical is preferred — each slice is independently shippable and exercises the whole stack, surfacing integration problems early.

Apply this:

- In `plan.md` — order chunks by slice, not by layer. The first chunk should be the smallest end-to-end thing that works.
- In `scope.md` — describe the first slice as the unit of work.
- In `TaskCreate` lists — each task should advance one slice end-to-end where possible.

Exceptions: pure infrastructure with no user-visible surface yet (e.g. a shared lib with no consumers), or refactors that explicitly touch one layer across many call sites. Name the exception in the plan when it applies.

## Commit and push defaults

When the user asks you to commit and push changes, default to a feature branch and PR — **never push directly to `main`**. This applies to every request, not just the planning workflow above. The planning workflow is one specific instance of this rule.

1. Create a branch from `main` named `feat/<slug>`, `fix/<slug>`, or `chore/<slug>` based on the change.
2. Commit on the branch.
3. Push the branch with `-u`.
4. Open a PR against `main` with `gh pr create` so the user can review on GitHub.

Push directly to `main` only when the user explicitly asks for it (e.g. "commit straight to main", "push to main directly", "skip the PR"). A generic "yes" in response to "should I commit and push?" is **not** authorization to skip the PR flow — assume PR.

## Project scaffolding

For every project you touch:

- **README.md** — if missing, create one. Keep it up to date as the project evolves.
- **CLAUDE.md** — if missing, create one with project-specific guidance.
- **AGENTS.md** — if missing, create one whose entire body is `@CLAUDE.md` so other agents read the same instructions as Claude Code.
- **.gitignore** — if missing, create one using a template that matches the project's stack. Combine the appropriate templates from [github/gitignore](https://github.com/github/gitignore) for each language/framework in use (e.g. `Node.gitignore` for TypeScript/React, `Python.gitignore`, `VisualStudio.gitignore` for C#/.NET). Always include OS noise (`.DS_Store`, `Thumbs.db`) and editor swap files; for IDE folders (`.vscode/`, `.idea/`), match the project's existing convention. Update it as new tooling is introduced.

## Language and stack defaults

Before writing code, inspect the solution/folder for an existing language, framework, and toolchain. Match what you find — do **not** infer the language from examples the user pastes into the prompt.

If no language is established yet in the project:

- **Frontend** — always TypeScript + React. No need to ask.
- **Backend** — either Python or C#. Always ask the user which one before scaffolding.

Use the latest stable versions:

- C# 15 on .NET 10
- Python 3.14
- TypeScript 6
- React 19

## Code quality

- Every method does exactly one thing.
- Method length: 3–30 lines. Do **not** write one-line methods unless the user explicitly asks for one.
- Frontend code must pass ESLint. Run the linter and fix violations before declaring a task done.

## Build pipelines

Default CI/CD is GitHub Actions. Implement build pipelines as GitHub workflows under `.github/workflows/` unless the user specifies a different platform.
