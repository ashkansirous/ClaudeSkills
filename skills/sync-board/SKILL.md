---
name: sync-board
description: Move GitHub Projects v2 board items between Todo / In Progress / Done. Use when starting work on a tracked issue, finishing it before merge, or bulk-correcting the board after it drifted out of sync with reality. Triggers - "sync the board", "move issue to in progress", "mark #N in progress", "mark #N done", "/sync-board".
---

A thin helper around `gh project item-edit` so the board stays in sync without
hand-looking-up project, field, and option IDs every time `Status` needs to
change.

## When to use this skill

Invoke this skill when:

- You're starting work on a tracked issue and want to set `Status=In Progress`
  before the first commit (per the `home/CLAUDE.md` "Keeping the project
  board in sync" rule and `plan-to-issues` "Keeping the board honest").
- You finished work on an issue and want to set `Status=Done` directly,
  without waiting for the closed-issue workflow to fire on PR merge.
- The board has drifted (e.g. you shipped a slice while everything was still
  in `Todo`) and you want to bulk-set `Status` for a list of issues.

Do **not** invoke this skill for:

- Creating issues — that's `plan-to-issues`.
- Editing fields other than `Status` — use `gh project item-edit` directly or
  extend this skill.
- Closing the underlying issues themselves — that's `gh issue close` or a PR
  merging with proper closing references.

## Preconditions (HARD)

1. **`gh` is authenticated** and has the `project` scope. `gh auth status`
   must list `project` (or `read:project` for read-only). If missing, tell
   the user to run `gh auth refresh -s project` and stop.
2. **A Projects v2 board exists** for the repo's owner. If `gh project list
   --owner <login>` is empty, point the user at `plan-to-issues` (which
   creates the board) and stop.

## Process

1. **Resolve the board.** Run `gh project list --owner <login>`. If there's
   exactly one project, use it. If multiple, ask the user which to target.
   Capture both:
   - the project **number** (used by most `gh project` subcommands), and
   - the project **node ID** (`gh project view <num> --owner <login>
     --format json --jq '.id'`, used by `gh project item-edit
     --project-id`).

2. **Resolve `Status` field + option IDs** with one call:

   ```bash
   gh project field-list <num> --owner <login> --format json
   ```

   From the JSON, extract:
   - The `Status` field ID — the entry where `name == "Status"` and
     `type == "ProjectV2SingleSelectField"`.
   - Option IDs for `Todo`, `In Progress`, and `Done` (the default option
     names; if the project uses custom names, fall back to the closest
     match and surface that to the user).

   These rarely change for a given project — cache them in conversation
   memory for the rest of the session.

3. **Resolve item IDs** for each input issue number. Either:

   ```bash
   gh project item-list <num> --owner <login> --limit 100 --format json \
     --jq '.items[] | select(.content.number == <N>) | .id'
   ```

   …or fetch all items once and filter in a loop if you're moving many.

   If an issue is **not on the board**, add it first:

   ```bash
   gh project item-add <num> --owner <login> --url <issue-url> --format json \
     --jq '.id'
   ```

   …and surface that fact in the report (don't silently add).

4. **Apply the `Status` change** for each item:

   ```bash
   gh project item-edit --id <item-id> --project-id <project-node-id> \
     --field-id <status-field-id> --single-select-option-id <option-id>
   ```

5. **Verify and report.** Print a final TSV of `number  status` for every
   issue you touched so the user sees the new state. Never report a silent
   success — the whole point is the board reflecting truth visibly.

## Arguments / typical invocations

- `/sync-board start #11` → set #11 to `In Progress`.
- `/sync-board done #11 #12 #13` → set all three to `Done`.
- `/sync-board todo #14` → set #14 back to `Todo` (rare, but useful when
  rolling back a wrongly-marked item).
- `/sync-board` with no args → ask which issues to move and to which
  Status, then proceed.

Issue numbers may be supplied with or without `#`. Multiple issues in one
invocation should batch (one `field-list` + one `item-list` fetch, then
loop the edits).

## Verification

- After running, the printed TSV shows each touched issue at the requested
  `Status`.
- Re-running with the same arguments is a no-op (the second pass sets the
  same option ID; idempotent).
- A spot check against the board UI matches the printed state.
