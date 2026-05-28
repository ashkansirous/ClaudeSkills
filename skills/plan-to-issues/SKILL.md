---
name: plan-to-issues
description: Project a settled plan.md/scope.md onto GitHub as a story/task hierarchy — vertical slices become parent Issues, their steps become native sub-issues, and everything is added to a Projects (v2) board. Use when the user wants to "create stories and tasks", "break this into GitHub issues", "make the issues", "push the plan to GitHub", or "to issues". Requires an existing plan.md at the repo root.
---

This skill reads the `scope.md` and `plan.md` at the repo root, derives a
**story → task** tree from them, shows that tree in chat for confirmation,
and then creates the work on GitHub: each vertical slice becomes a parent
**Issue** ("story"), each step within the slice becomes a native **sub-issue**
("task"), and every issue is added to a **Projects (v2) board** with its
`Status` and `Slice` fields set.

It is the next link after the planning chain: `to-scope` → `scope.md`, the
planning workflow → `plan.md`, then **this skill** → GitHub issues. It does
not write or change the plan's content — it only projects it onto GitHub.

## When to use this skill

Use it **only**:

- When a settled `plan.md` exists at the repo root and the user wants to
  break the work into trackable GitHub items.
- When the user says things like "create stories and tasks", "break this
  into GitHub issues", "make the issues", "push the plan to GitHub", or
  "to issues".

Do **not** use it:

- To *write* the plan — that is the planning workflow (`home/CLAUDE.md`) and
  `to-scope`. If there is no `plan.md`, stop and point the user there.
- For non-GitHub trackers (Jira, Linear, …) — this skill is GitHub-only.

## Preconditions (HARD — check before doing anything)

1. **`plan.md` exists at the repo root.** Ideally `scope.md` too. If `plan.md`
   is missing, stop and tell the user to run `to-scope` / the planning
   workflow first. Do not invent a plan.
2. **The repo has a GitHub remote and `gh` is authenticated.** Verify with
   `gh auth status` and `gh repo view`. If not, stop and surface it.
3. **context7 / `gh` docs precondition.** `gh` flags and the sub-issue /
   Projects v2 APIs shift between versions — do **not** assume command shapes
   from memory. Before issuing any command, confirm the current mechanism for:
   - `gh issue create` (labels, milestone, body);
   - **linking sub-issues** — native sub-issues are created via the REST
     endpoint `gh api repos/{owner}/{repo}/issues/{number}/sub_issues`
     (field `sub_issue_id`) or the GraphQL `addSubIssue` mutation. There is
     **no** `gh issue create --parent` flag — verify the current path;
   - `gh project list` / `gh project item-add` / `gh project item-edit` and
     setting field values (Projects v2 is **GraphQL-only** under the hood).

   Query context7 for the `cli/cli` (the `gh` CLI) docs and, if needed, the
   GitHub REST/GraphQL docs before writing the commands.

## Process

1. **Read & parse.** Read `scope.md` + `plan.md`. Map each **vertical slice**
   (from `scope.md`'s Approach / `plan.md`'s Changes) to a **story**, and each
   numbered change/step under that slice to a **task**. Story titles should
   read as user-visible value, e.g. `Slice 1: user can log in` — not
   `add migration`. Tasks are the steps that deliver the slice.

2. **Derive metadata.** Plan to apply labels `story` and `task` (optionally a
   per-slice label like `slice-1`). Add a **Milestone** only if the plan
   groups slices into releases — otherwise skip it.

3. **Pick the board.** Run `gh project list` for the owner. Let the user
   choose an existing Projects v2 board or create one. Ensure it has a
   `Status` field (Todo / Doing / Done) and a `Slice` single-select field;
   create the `Slice` field if it is missing.

4. **Idempotency check.** Before creating anything, run `gh issue list
   --search "<title>"` for each story/task title to find items a previous run
   already created. Mark those as "exists — will reuse" so you neither
   duplicate them nor recreate their links.

5. **Chat summary + confirm.** Print the full tree in chat — every story, its
   tasks, the labels, the milestone (if any), the target board, and which
   items already exist. **Wait for the user's explicit approval. Nothing hits
   GitHub before this.** (Per the user's standing preference, this skill uses
   a chat summary, not a preview file.)

6. **Create — only after approval, in this order:**
   a. Ensure labels exist — `gh label create <name> --force` (idempotent).
   b. Create the **story** issues with `gh issue create` (title, body from the
      slice's goal, `story` + slice labels, milestone if any). Capture each
      issue number.
   c. Create the **task** issues, then link each as a **sub-issue** of its
      story via the verified `gh api .../sub_issues` mechanism. Skip linking
      for any that the idempotency check flagged as already linked.
   d. Add every issue (stories and tasks) to the chosen project with
      `gh project item-add`, then set `Status=Todo` and `Slice=<n>` with
      `gh project item-edit`.

7. **Write back & report.** Optionally annotate `plan.md` by appending the
   created issue number next to each slice/task (traceability + safer
   re-runs). Then print a summary with links to the issues and the board.

## Verification

- `gh issue list` shows the stories; `gh issue view <n>` shows the linked
  sub-issues under each story.
- `gh project item-list <number>` shows every issue on the board with
  `Status` and `Slice` populated.
- **Re-running the skill produces no duplicates** — the idempotency check in
  step 4 must hold.
