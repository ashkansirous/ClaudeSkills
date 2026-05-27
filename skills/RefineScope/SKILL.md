---
name: RefineScope
description: Interview the user with at most 4 high-leverage questions about a plan or design, then recommend answers for the remaining open decisions for the user to approve in one batch. Use when the user wants a fast clarification pass before planning or scoping work, or mentions "refine scope", "refine the scope", "RefineScope", "quick clarify", or invokes `/RefineScope`.
---

Walk the design tree for the user's plan and identify every open decision.

## When to use this skill

Invoke this skill **only**:

- When the user has a plan or design and wants a fast clarification
  pass before committing to it.
- As the "clarify intent" step at the start of the planning workflow in
  `home/CLAUDE.md`.

Do **not** invoke this skill:

- For a free-form chat that has not yet produced a candidate plan or
  design — ask the user to share their plan first.
- When the user has already approved a plan — they want execution, not
  more questions.

## Process

Pick at most 4 questions to ask the user. Choose the ones with the highest
information gain — i.e. answers that resolve or constrain the most other
open decisions. Never exceed 4 questions, no matter how complex the plan.

If a question can be answered by exploring the codebase, explore the
codebase instead of asking.

For every remaining open decision, write a single recommendation block in
this format:

> Here are the questions I came up with the suggestion. Are you ok with them?
>
> **<question>**
> <recommended answer>
> Alternatives: <other options>. I recommend <answer> because <reason>.
> Second choice: <runner-up> because <reason>.

Wait for the user's approval. Once they confirm, if the conversation
does not already have a good, descriptive name, tell the user to run
`/rename` and suggest a specific topic-relevant name based on what was
just discussed. `/rename` is a UI-only command and cannot be invoked
from the agent, so do not try to invoke it yourself — just prompt the
user.

Example phrasing: "This thread doesn't have a good name yet. Run
`/rename` and call it something like `creating to-scope skill`."

Then the skill is done — hand control back to the caller. Do not write
plan.md or take further action.

If the plan has 4 or fewer total decisions, just ask all of them and skip
the recommendation block.
