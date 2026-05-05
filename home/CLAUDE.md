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
