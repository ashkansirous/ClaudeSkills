# Shared user instructions

These apply to every project on machines where ClaudeSkills is installed. Synced from `~/.claude/skills-repo/home/CLAUDE.md` via the repo's install script.

## Planning workflow

When the user explicitly kicks off planning with one of the phrases `let's plan ...`, `start a plan for ...`, or `plan this ...`, follow these six steps:

1. **Clarify intent.** Use the `grill-me` skill to interview the user about goals and main purpose until you reach shared understanding. Skip only if intent is already crystal clear from the user's message.
2. **Branch.** Create a new branch from `main` named `plan/<short-slug>` derived from the topic.
3. **Write the plan.** Save it to `plan.md` at the repo root. Overwrite if it exists — `plan.md` is branch-scoped.
4. **Reflect the plan.** If the plan introduces new conventions, commands, or behaviors, update `CLAUDE.md`. If it changes user-facing behavior or install steps, update `README.md`. If neither applies, leave them alone.
5. **Commit and push.** One commit per logical step (the plan itself, then each reflection). Push the branch with `-u` to set upstream.
6. **Open a PR** against `main`. Title from the plan slug. Body = a 1-3 line summary plus a checklist of in-scope items from the plan.

Confirm with the user before pushing or opening the PR.

## Project scaffolding

For every project you touch:

- **README.md** — if missing, create one. Keep it up to date as the project evolves.
- **CLAUDE.md** — if missing, create one with project-specific guidance.
- **AGENTS.md** — if missing, create one whose entire body is `@CLAUDE.md` so other agents read the same instructions as Claude Code.

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
