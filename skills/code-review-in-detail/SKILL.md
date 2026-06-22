---
name: code-review-in-detail
description: Deep, uncapped multi-agent code review of the current diff (or a named PR/branch/range) that writes two files — a readable summary-code-review.md and an exhaustive detailed-code-review.md with line numbers, suggested fixes, and the reason for each. Reports EVERY real issue (no 10-finding cap), in the detailed narrative style of the built-in /review, and additionally covers test/coverage gaps, hygiene/scope-creep in non-code files, undocumented assumptions, and a remediation plan. If a scope.md and/or plan.md (or PR/issue description) is present, it also checks whether the changes actually implement the intended task. Use when the user runs /code-review-in-detail, or asks for a "detailed code review", "thorough review", "review in detail", or wants the review written to files they can open in VS Code.
---

This skill performs a **deep, exhaustive** code review and writes the result to
**two files at the repo root**:

- `summary-code-review.md` — a readable, VS-Code-friendly overview (narrative +
  severity buckets + intent check + a remediation plan).
- `detailed-code-review.md` — **every** issue found, each with `file:line`, a
  concrete suggested change, and the reason for that suggestion.

It is the heavier sibling of the built-in `/review` and `/code-review`. It keeps
the multi-agent finder→verify engine for depth and false-positive filtering, but
with five deliberate differences the user asked for:

1. **No finding cap.** Report as many real issues as exist — never truncate to 10.
2. **Detailed, useful reporting** in the style of `/review` — context, impact,
   and remediation, not just a terse list.
3. **Broader coverage.** Explicitly hunt the classes a pure correctness pass
   drops: missing/insufficient tests, scope-creep and hygiene in **non-code**
   files (READMEs, config, CI, lockfiles), formatting/style nits, and
   undocumented assumptions. Do **not** exclude non-code files from scope.
4. **Intent alignment.** If a `scope.md`, `plan.md`, PR description, or linked
   issue exists, check whether the diff actually implements the intended task and
   report on it.
5. **File output.** Write the two markdown files above (do not post a GitHub
   comment unless the user explicitly asks).

---

## Phase 0 — Gather scope and intent

1. **Get the diff under review.** In order of preference:
   - If the user named a PR number / branch / path, review that target
     (`gh pr diff <n>`, or `git diff <base>...<branch>`, or scope to the path).
   - Else `git diff @{upstream}...HEAD`; if that is empty, `git diff main...HEAD`
     or `git diff HEAD~1`.
   - **Always also** run `git diff HEAD` and fold in uncommitted working-tree
     changes — reviews often run before the commit.
   - If the diff lives on another branch, check it out (`git checkout <branch>`)
     so finder agents can read enclosing functions and trace callers, then
     **restore the original branch when done** (note it first; restore even if a
     step fails).
   - Record the exact range and HEAD sha — they go in the report header.

2. **Do NOT narrow scope to code files.** Binary blobs (e.g. `*.db`, images) can
   be noted as "opaque/unreviewable" but everything textual — READMEs, configs,
   CI workflows, lockfiles, docs — is in scope.

3. **Find the intent sources.** Look for, in this order, and load whatever exists:
   - `scope.md` and/or `plan.md` at the repo root.
   - The PR description / title (`gh pr view <n>`), and any linked/closing issues.
   - A task description the user gave in this conversation.
   If none exist, say so in the report and skip the intent-alignment verdict (but
   still do everything else).

---

## Phase 1 — Find candidates (parallel finder agents, up to ~8 each)

Launch these finder angles **in parallel** via the Agent tool (use the `Explore`
agent type). Each returns up to ~8 candidates as JSON with
`file`, `line`, `severity` (blocking/significant/minor), `category`, a one-line
`summary`, a concrete `failure_scenario`, and a `suggested_fix`. Pass every
candidate with a nameable failure scenario through — do **not** self-censor
half-believed ones; that is what Phase 2 is for. There is **no per-angle cap**
beyond ~8 for manageability; if an angle genuinely has more, it may return more.

**Correctness angles**

- **A — line-by-line diff scan.** Read every hunk, then Read the enclosing
  function (bugs on unchanged lines of a touched function are in scope). Hunt
  inverted/wrong conditions, off-by-one, null/undefined deref, missing `await`,
  falsy-zero checks, wrong-variable copy-paste, swallowed errors, unsafe casts,
  enum/default hazards, time-dependence, numeric/decimal mistakes.
- **B — removed-behavior auditor.** For every deleted/replaced line, name the
  invariant it enforced and find where the new code re-establishes it. Flag
  removed guards, dropped error paths, narrowed validation, lost test coverage.
- **C — cross-file tracer.** For each changed signature/symbol, Grep callers and
  callees; flag broken call sites, new preconditions, changed return shapes, new
  exceptions, ordering/timing dependencies, and DI/wiring breakage.

**Quality angles**

- **D — reuse.** New code that re-implements an existing helper. Name the
  existing one to call instead.
- **E — simplification.** Redundant/derivable state, copy-paste variants, deep
  nesting, dead code. Name the simpler form.
- **F — efficiency.** Redundant I/O/compute, N+1 queries, sequential independent
  work, blocking work on hot/async paths, materialize-then-filter. Name the
  cheaper alternative.
- **G — altitude.** Is each change at the right layer, or a special-case bandaid
  on shared infra? Prefer generalizing the mechanism. Flag leaky layering and
  caller-supplied data that should be derived from domain state.

**Coverage angles (the classes a pure correctness pass drops — include these)**

- **H — tests & coverage.** Were tests added for the new behavior? Were existing
  tests merely edited to compile rather than to validate (and do they still
  assert the right thing)? Are there non-deterministic/time-dependent or flaky
  tests? Untested branches, error paths, edge cases? Name the missing tests.
- **I — hygiene, scope & docs.** Review **non-code and whole-PR** concerns:
  scope-creep (unrelated files, stray README/CI/config churn), formatting nits
  (mixed tabs/spaces, missing trailing newline), undocumented assumptions,
  schema/data committed only as opaque binaries, secrets/keys, missing or stale
  docs, lockfile/dependency surprises, commit/PR hygiene. Cross-check against any
  CLAUDE.md in the touched directories.

---

## Phase 2 — Intent alignment (only if an intent source was found)

Launch one agent that takes the intent source(s) from Phase 0 and the diff, and
returns, per goal / acceptance criterion:

- the criterion text,
- a verdict — **Met / Partially met / Not met / Not attempted**,
- evidence (the file/line that implements it, or a note that nothing does),
- plus any **out-of-scope additions** the diff makes that the task did not ask for.

This becomes the "Does it do what was asked?" section of the summary.

---

## Phase 3 — Verify (recall-biased, no cap)

Dedup near-duplicates (same defect + location + reason → keep one). For each
surviving candidate, run **one** verifier agent. It returns exactly one verdict:

- **CONFIRMED** — constructible from the code; cite the line.
- **PLAUSIBLE** — realistic but state-dependent (rare-but-reachable paths, races,
  falsy-zero, boundary off-by-one, lost anchors). Default here when unsure.
- **REFUTED** — provably wrong (quote the line), impossible (show the
  invariant), already handled (cite the guard), or pure style with no effect.

Keep **CONFIRMED and PLAUSIBLE**. Drop **REFUTED**. **Do not cap the count** —
keep every survivor. Sort by severity (blocking → significant → minor), and
within severity by confidence.

---

## Phase 4 — Write the two files

Write both files to the **repo root**, overwriting if they exist. After writing,
tell the user the two paths and give a 2–3 line spoken summary (counts per
severity + the intent verdict).

### `summary-code-review.md`

```markdown
# Code Review — Summary

**Target:** <PR #n / branch / diff range>  ·  **HEAD:** <short-sha>
**Reviewed:** <files changed> files, +<add>/−<del>
**Generated by:** code-review-in-detail

## Verdict
<2–4 sentences: overall health, whether it is safe to merge, the single most
important thing to fix.> 

## Does it do what was asked?
<Only if an intent source exists. A table of criteria → verdict; otherwise the
line "No scope.md / plan.md / PR description found — intent check skipped.">

| Goal / acceptance criterion | Verdict | Notes |
|---|---|---|
| … | Met / Partial / Not met | … |

Out-of-scope additions: <list, or "none">.

## Findings by severity
**🔴 Blocking (<n>)** — must fix before merge
- <one line each, with `file:line`>

**🟠 Significant (<n>)** — should fix
- …

**🟡 Minor / cleanup (<n>)**
- …

## Tests & coverage
<What is/ isn't tested, broken or flaky tests, the missing tests to add.>

## Hygiene & scope
<Scope-creep, non-code churn, formatting, undocumented assumptions, docs.>

## Path to done
1. <ordered, concrete remediation steps>
2. …

---
Full line-by-line detail with suggested fixes: **detailed-code-review.md**
```

### `detailed-code-review.md`

Every issue, no cap. Group by severity (then by file). Each entry uses this shape:

```markdown
### [<SEV>] <short title>
- **Location:** `path/to/file.ext:123`  (`function/symbol`)
- **Category:** correctness | reuse | simplification | efficiency | altitude | tests | hygiene
- **Problem:** <what is wrong, 1–3 sentences>
- **Failure scenario:** <concrete inputs/state → wrong output/crash/cost>
- **Suggested change:**
  ```diff
  - <current>
  + <proposed>
  ```
  (or a precise prose instruction when a diff is awkward)
- **Why this fix:** <the reasoning — what invariant it restores / what it
  simplifies / what it saves, and any trade-off>
- **Confidence:** CONFIRMED | PLAUSIBLE
```

Start `detailed-code-review.md` with a one-line header echoing the target/sha and
a count of issues per severity, and include an **Intent alignment** section
(expanded from Phase 2) before the issue list when an intent source exists.

---

## Rules & notes

- **Never cap findings.** If the diff genuinely has 30 issues, report 30.
- **Match the diff's own conventions** when proposing fixes (naming, style,
  surrounding idioms).
- **Be honest about uncertainty** — mark PLAUSIBLE vs CONFIRMED; never inflate.
- **Restore git state** if you checked out another branch.
- **Do not** post GitHub comments, commit, or push unless the user explicitly
  asks — this skill's deliverable is the two local files.
- If the working tree is clean and no PR/branch/range was given and no diff can
  be found, tell the user there is nothing to review rather than inventing scope.
- Severity guide: **Blocking** = wrong output, crash, data loss, breaks
  build/tests, or fails the task's intent. **Significant** = real bug on a
  reachable-but-rarer path, notable perf/layering problem, or a missing test for
  important behavior. **Minor** = cleanup, style, docs, small inefficiency.
