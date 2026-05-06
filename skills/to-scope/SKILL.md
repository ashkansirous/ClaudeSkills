---
name: to-scope
description: Synthesize the current conversation context and codebase understanding into a lightweight scope.md at the repo root. Precursor to the full plan.md workflow. Use when user wants to write a scope document, mentions "to scope", "scope this", "write the scope", or asks for a synthesized scope of the current work.
---

This skill synthesizes the current conversation context and codebase
understanding into a `scope.md` at the repo root. It is a lightweight
precursor to the full planning workflow that produces `plan.md` — write
`scope.md` first, then escalate to `plan.md` once the scope is settled.

Do NOT interview the user. Synthesize from what you already know from the
conversation and the codebase. If something is genuinely missing,
explore the codebase before asking.

## Process

1. From the current conversation and a quick read of the repo, draft the
   three sections below in your head.

2. Show the user a short summary of each section (one or two lines per
   section is enough) and ask them to confirm or correct before you
   write the file.

3. Once confirmed, write `scope.md` at the repo root using the template
   below. Overwrite if it already exists — `scope.md` is branch-scoped,
   the same as `plan.md`.

4. Do NOT create a branch, commit, push, or open a PR. Branching and PR
   handling belong to the downstream `plan.md` workflow, not here.

5. After writing, if the conversation does not already have a good,
   descriptive name, tell the user to run `/rename` and suggest a
   specific topic-relevant name based on the scope you just wrote.
   `/rename` is a UI-only command and cannot be invoked from the agent,
   so do not try to invoke it yourself — just prompt the user.

   Example phrasing: "This thread doesn't have a good name yet. Run
   `/rename` and call it something like `scoping the auth rewrite`."

## Template

```markdown
# Scope

## Goals

What we are trying to achieve, from the user's perspective. A short
bulleted list — each item one sentence.

## Approach

The shape of the solution at a high level. Not a full design — just
enough that a reader knows roughly what we are going to build or change.
Bullet points are fine.

## Out of Scope

Things explicitly NOT being done in this piece of work, especially
things a reader might reasonably assume are included.

## Notes

(Optional.) Anything else worth recording — open questions, links,
constraints, prior art. Omit the section if there is nothing to put in
it.
```
