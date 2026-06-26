# Shared user instructions

These apply to every project on machines where ClaudeSkills is installed. Synced from `~/.claude/skills-repo/home/CLAUDE.md` via the repo's install script.

## The trunk is always `main` (non-negotiable)

Every git repo has exactly one long-lived trunk, and it is **`main`**. All work merges into `main`; nothing else is ever the trunk or the GitHub default branch. A `plan/*`, `feat/*`, `fix/*`, or `chore/*` branch is always short-lived and always merges back into `main` via a PR. There is no exception — "the planning branch became the trunk" is the exact failure this rule exists to prevent.

**The `main` guard — run it before creating any branch and before opening any PR:**

```bash
git fetch origin
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name   # must print exactly: main
```

If it prints anything other than `main` (most common on a fresh repo where the first branch pushed — e.g. a `plan/*` branch — silently became the default), **stop and fix the trunk before doing anything else:**

1. Make sure `main` has the latest work. If another branch (e.g. `plan/<slug>`) is acting as the trunk, bring it into `main`: `git checkout main && git merge --ff-only <trunk-branch>` (use a normal merge if it won't fast-forward). Inspect with `git log --oneline main..<trunk-branch>` first.
2. Push it: `git push -u origin main`.
3. Make it the default: `gh repo edit --default-branch main`.
4. Retarget every open PR onto `main`: `gh pr edit <num> --base main`.
5. Delete the impostor trunk branch(es) once their content is in `main` — **confirm with the user first** (it's destructive): `git push origin --delete <branch>` then `git branch -d <branch>`, then `git remote prune origin`.

**Hard invariants — never violate these:**

- Always branch **from `main`**; always open PRs with **`--base main`**.
- Never run `gh repo edit --default-branch` with anything other than `main`.
- When first pushing a brand-new repo, push **`main` first** (`git init -b main` → first push/`gh repo create --push` on `main`) so GitHub sets `main` as the default. Never let the first pushed branch be a `plan/*`/`feat/*` branch.
- Never merge a feature/plan branch into another feature/plan branch as if it were the trunk. PRs flow one way: short-lived branch → `main`.

A fresh repo's `main` should be undeletable: add a branch ruleset/protection on the default branch with `deletion` + `non_fast_forward` rules (`gh api repos/{owner}/{repo}/rulesets ...`), either when setting up the repo or whenever the user asks.

## Branch hygiene: prune merged branches when you start a new one

Short-lived branches are disposable — once their PR merges into `main`, they are dead weight. Leaving them around hides which branch is the real trunk and makes drift (the failure above) hard to spot. So **every time you create a new branch** — right after the `main` guard, before `git checkout -b` — sweep up branches whose work is already in `main`:

```bash
git checkout main && git fetch --prune origin          # prune drops stale remote-tracking refs
git branch --merged main | grep -vE '^\*|(^|\s)main$' | xargs -r git branch -d   # safe: -d refuses unmerged
```

That handles local branches safely (`git branch -d` refuses to delete anything not fully merged). For the **remote** branches whose PRs have merged but that still exist on the origin:

```bash
gh pr list --state merged --json headRefName --jq '.[].headRefName'   # candidates
git push origin --delete <branch>                                     # delete the merged ones
```

Rules for the sweep:

- **List what you're about to delete and confirm with the user before deleting any *remote* branch** — remote deletion is destructive and outward-facing. Local `-d` deletions are safe to do without asking (they can't drop unmerged work).
- **Never delete `main`, the current branch, or a branch with an open/unmerged PR.** Skip anything `git branch -d` refuses, and skip head branches of still-open PRs.
- Prefer enabling GitHub's **auto-delete head branches on merge** (`gh repo edit --delete-branch-on-merge`) on repos you set up, so merged remote branches clean themselves up.

This keeps `git branch -a` showing only `main` plus the genuinely active branches.

## Planning workflow

Trigger this workflow whenever the user asks for a plan, whether or not they use a "magic" phrase. Phrases that should fire it include — but are not limited to — `let's plan ...`, `let's make a plan`, `make a plan`, `make me a plan`, `start a plan for ...`, `plan this ...`, `lets plan ...`, or running the `/RefineScope` skill with planning-shaped arguments. If you're unsure whether the user is asking for a plan or a quick chat, default to triggering the workflow — the cost of one extra `plan.md` is small; the cost of missing it is losing the audit trail of what was decided.

Once triggered, follow these six steps:

1. **Clarify intent.** Use the `RefineScope` skill to interview the user about goals and main purpose (at most 4 questions, then recommendations for the rest) until you reach shared understanding. Skip only if intent is already crystal clear from the user's message.
2. **Branch.** If this is a git repo, first run the **`main` guard** (see *The trunk is always `main`*) — if the repo's default branch isn't `main`, fix that before branching — and the **merged-branch sweep** (see *Branch hygiene*). Then create a new branch **from `main`** named `plan/<short-slug>` derived from the topic. If it's not a git repo yet, skip the branch step (don't run `git init` without asking) but still proceed to step 3.
3. **Write the plan to `plan.md` at the repo root.** This is non-negotiable. The plan file the harness may give you (e.g. `~/.claude/plans/<slug>.md`) is for the agent's working memory; the *project's* plan must live at `<repo>/plan.md` so the user can read, edit, and commit it. If both exist, keep them in sync — but `plan.md` at the repo root is the source of truth. Overwrite if it exists — `plan.md` is branch-scoped. After implementation, the plan stays in the repo as a record of what was built (and what was deliberately out of scope) — do not delete it.
4. **Reflect the plan.** If the plan introduces new conventions, commands, or behaviors, update `CLAUDE.md`. If it changes user-facing behavior or install steps, update `README.md`. If neither applies, leave them alone.
5. **Commit and push.** Only if this is a git repo. One commit per logical step (the plan itself, then each reflection). Push the branch with `-u` to set upstream.
6. **Open a PR** against `main`. Only if this is a git repo with a remote. Title from the plan slug. Body = a 1-3 line summary plus a checklist of in-scope items from the plan.

Confirm with the user before pushing or opening the PR.

**Keeping `plan.md` honest during implementation.** As you work, tick off slices in `plan.md` (e.g. add a `[x]` next to a completed item) and add any scope changes the user agrees to. The plan is the record of what was built — if it drifts from reality, future-you and the user can't tell what was finished, what was skipped, and why. When you open the **implementation** PR for a slice, it must close that slice's tracked issues — its story **and** its done sub-tasks (see *Pull request bodies → Find which issues the PR closes*). Ticking the slice `[x]` in `plan.md` but leaving its GitHub issues open is the exact drift this rule prevents.

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

0. Run the **`main` guard** first (see *The trunk is always `main`*): confirm the repo's default branch is `main` and fix it if not; then do the **merged-branch sweep** (see *Branch hygiene*) — before branching.
1. Create a branch from `main` named `feat/<slug>`, `fix/<slug>`, or `chore/<slug>` based on the change.
2. Commit on the branch.
3. Push the branch with `-u`.
4. Open a PR against `main` with `gh pr create` so the user can review on GitHub.

Push directly to `main` only when the user explicitly asks for it (e.g. "commit straight to main", "push to main directly", "skip the PR"). A generic "yes" in response to "should I commit and push?" is **not** authorization to skip the PR flow — assume PR.

### Decide the SemVer bump when the repo auto-versions from commits

Some repos compute their release version **automatically from git/commit history** — e.g. **GitVersion** (reads `+semver: major|minor|patch|none` tokens in commit messages), **Conventional Commits** / semantic-release (`feat:` → minor, `fix:` → patch, `feat!:`/`BREAKING CHANGE:` → major), or a bespoke CI job that derives the next SemVer. When such a setup exists, **the commit message is the version input** — picking the bump is part of writing the commit, not an afterthought, and getting it wrong silently ships the wrong version.

So before committing, **check whether automated versioning is wired up**: look for `GitVersion.yml`, a `version`/`release` CI job, `semantic-release`/`commitlint`/`changesets` config, or a `CLAUDE.md`/`CONTRIBUTING.md` note describing a commit convention. If you find one:

1. **Learn the exact marker the tool consumes — don't assume.** GitVersion wants a `+semver: minor` token in the message body; Conventional Commits wants a `feat:`/`fix:`/`feat!:` *prefix*; changesets wants a changeset file. Match the mechanism actually in use, in the format it expects.
2. **Classify the change and set the bump accordingly:**
   - **major** — a breaking change to a public/consumed contract: removed or renamed API/exports, changed CLI flags, config keys, or on-disk/schema/wire formats. Marker: `+semver: major` / `feat!:` / a `BREAKING CHANGE:` footer.
   - **minor** — a backward-compatible new feature or capability. Marker: `+semver: minor` / `feat:`.
   - **patch** — a bug fix, refactor, perf tweak, docs, chore, test, or CI change with no new surface. This is the **default**: most tools (GitVersion included) bump patch when no marker is present, so a patch usually needs no marker at all.
3. **Default to patch when unsure, but never *under*-mark.** A feature committed with no marker ships as a patch and silently under-versions the release — that's the failure this rule prevents. When a change is genuinely a feature or a breaking change, you **must** add the higher marker. If you can't tell minor from major on a public-contract change, prefer the safer (higher) bump or ask.

⚠️ **Footgun — never write the literal marker in prose.** Token-based tools (GitVersion especially) match the marker **anywhere** in the message, including quoted examples and explanations. A commit that *documents* or *quotes* a marker will trigger that bump — e.g. a message body containing `or "+semver: major"` forced a real `0.1.1 → 1.0.0` jump (the intended `+semver: minor` was overridden). So: only ever write a marker when you mean it as the directive; when you must *mention* one in prose (commit body, PR text that becomes a squash commit, docs you commit), **break it** so the regex can't match — `+semver:<zero-width space>major`, or just write "the major token". This applies to the markers you put in commit messages, not to this rule file.

Put the marker on the commit that carries the change. In **squash-merge** repos the squash message becomes the commit, so mirror the marker in the **PR title/description** too. If the repo has **no** auto-versioning, ignore all of this — don't invent version markers nothing consumes.

## Pull request bodies

Every PR body you write follows this contract. These are not stylistic preferences — they prevent specific bugs that have actually happened.

### Find which issues the PR closes — do this BEFORE you open it

Before `gh pr create` for any work that is tracked as issues, identify **every** issue the PR completes and add a closing reference for each. This step is the one that actually gets skipped — the rest of this section assumes you already know which issues to close, and that assumption is where work rots. Sources, in order:

- **`plan.md`** links each slice to its story issue (e.g. `Slice 4 — … ([#7](…))`). The PR that implements that slice closes that **story and its task/sub-issues** — find them with `gh issue list` (filter by the slice's label) or by reading the story's sub-issue list.
- the Projects v2 board / `gh issue list --state open` for the repo.

Closing the parent **story does not auto-close its sub-tasks** — list every done task issue explicitly. If a slice only partially completes a story (some tasks deliberately deferred), close just the finished task issues, leave the story + deferred tasks open, and say so in the PR body.

If you implemented tracked work and your PR body has **no** `Closes #…` line, treat that as a bug until proven otherwise — the issues survive the merge and rot as "done but still open." This has actually happened: a slice's story plus three task issues stayed open after merge because the PR omitted the references, and the user had to point it out.

### Closing references — one keyword per line

When a PR closes multiple issues, write each closing reference on its own line:

```
Closes #11
Closes #12
Closes #13
```

**Not** `Closes #11, #12, #13.` and **not** `Closes #11, closes #12, closes #13.` — GitHub's parser only auto-links the **first** issue in inline comma forms, so the others stay open after merge (and remain stuck in their pre-merge `Status` on the project board). The one-per-line form is the only reliable way to link multiple closing references.

Accepted keywords: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`. Case doesn't matter; placement does.

### Verify the references parsed — every time

After **every** `gh pr create`/`gh pr edit` for tracked work (not just when you remember to add refs), run this check before reporting the PR as done:

```bash
gh pr view <num> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'
```

The printed list must match exactly the issues you intended to close. Two failure modes, both bugs:

- **Empty list when the work was tracked** — you forgot the `Closes #…` lines entirely (the most common miss). Go back to *Find which issues the PR closes*, add them, re-verify.
- **List doesn't match** — the body syntax is wrong (e.g. inline comma form); fix it and re-verify.

Treat this the same way you treat reading test output: not optional, not deferrable to the user. (`closingIssuesReferences` is eventually-consistent and can lag a few seconds after an edit — if it looks stale, re-query before concluding it's wrong.)

### Body shape

Default to two sections:
- **Summary** — 1–3 bullets on *why* and the user-visible change. Not a recap of the diff.
- **Test plan** — a checkboxed list of what was actually verified, with the commands. Be honest about what couldn't be run (e.g. "live browser end-to-end not yet run; Playwright MCP not registered").

Then the closing references on their own lines at the bottom.

### Keeping the project board in sync

When a PR opens, move every closed-by-this-PR issue to `Status=In Progress` on the Projects v2 board if it isn't already (issues stay In Progress until the PR merges; the closed-issue workflow then auto-moves them to `Done`). When you start work on a tracked issue before opening a PR, move it to `In Progress` before the first commit. Use the `sync-board` skill so you don't hand-look-up field/option IDs every time.

The board is the user's view of reality. Leaving everything in `Todo` while shipping PRs is a bug, not a style preference.

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

Always use the **latest stable** versions of C# / .NET, Python, TypeScript, and React. Do not pin specific majors here — they go stale fast. At the start of any scaffolding work, fetch the current stable major via the **context7 MCP** (e.g. `/dotnet/aspnetcore`, `/python/cpython`, `/microsoft/TypeScript`, `/reactjs/react.dev`) and use whatever it reports.

### Backend architecture: offer choices, don't pick silently

For any **new** backend work (scaffolding a fresh `/backend`, or implementing the first feature in a backend that has no clear architecture yet), present 2–3 architectural options to the user **before** writing code and let them pick. Do not silently default to one shape. Present them as a short numbered list, mark the recommended default, and one-sentence why each one fits.

Per-language defaults to recommend:

- **C# / .NET** — recommended default is **Clean Architecture + DDD**: separate projects for `Domain` (entities, value objects, aggregates, domain events, repository *interfaces* — zero framework dependencies), `Application` (use cases, commands/queries, DTOs, orchestration), `Infrastructure` (EF Core / external API clients / persistence implementations of the Domain interfaces), and `Api` (endpoints, request/response models, DI wiring). Alternatives worth offering: **vertical-slice architecture** (each feature folder owns its full slice — closer to "feature-first"), **modular monolith** (each bounded context is its own assembly with a public contract), or **simple 3-layer N-tier** (only for genuinely small/throwaway apps). Recommend Clean Architecture + DDD unless the user steers elsewhere.
- **Python** — ask the user. Reasonable options to surface: **hexagonal / ports-and-adapters**, **layered (controllers / services / repositories)**, or **vertical-slice / feature folders**. No silent default — Python projects vary too much.

When the existing `/backend` **already** has an architecture (folders, project structure, naming conventions all point at one shape), do **not** re-pitch alternatives — detect it, name it back to the user briefly ("this project follows Clean Architecture — I'll add the feature the same way"), and follow it precisely. The choice is only at greenfield time.

### Context7 is a hard precondition, not a guideline

Do **not** write a single line of code that touches a third-party library, framework, SDK, CLI flag, build tool, or cloud-service API until you have logged a context7 query against the relevant library ID. This includes:

- Scaffolding commands (`dotnet new`, `npm create vite`, `terraform init`) — flags shift between majors.
- Framework idioms (Minimal API binding, React hooks, Tailwind config, lint plugin rules, EF Core queries).
- HTTP clients, ORM queries, SDK calls.
- "Well-known" libraries (React, Vite, ASP.NET Core, Tailwind, EF Core, FastAPI) — these are the *most* likely to have moved since training data, not the least.

**No exceptions.** "Quick demo", "40-minute build", "I already know this API", and "the user is in a hurry" are not valid reasons to skip context7 — they are the exact rationalizations the rule exists to defeat. If a query takes 5 seconds and saves writing one stale pattern that ships into the user's codebase, it pays for itself instantly.

**How to comply, visibly:**
1. Before the first relevant tool call, name the library IDs you will query.
2. Call `mcp__context7__resolve-library-id` if you don't already have the `/org/project` ID.
3. Call `mcp__context7__query-docs` with the user's actual question (not single keywords).
4. Only then write code.

If you find yourself reaching for the Bash tool to run `dotnet new` or `npm create` before any context7 call has happened in this turn, stop and back up.

## Code quality

- Every method does exactly one thing.
- Method length: 3–30 lines. Do **not** write one-line methods unless the user explicitly asks for one.
- Frontend code must pass ESLint. Run the linter and fix violations before declaring a task done.

### Backend code quality (C# and Python)

These apply to **every** backend you touch — scaffolds, feature work, hot-fixes. "Small project" and "demo" are not exceptions; structure makes the demo legible.

1. **No magic strings.** Any string that is a JSON key, a property name, a dictionary key, a status discriminator, a header name, a route segment, or a config key must come from a named constant or — when it mirrors a property — from `nameof(...)` (C#) or `Model.field_name` (Python). Example: `r.GetProperty("name")` is wrong; `r.GetProperty(nameof(GeocodeResult.Name))` (with an attribute mapping casing if needed) or a `const string NameKey = "name";` group is right. The litmus test: a typo in a key should be a compile error, not a 200 OK with missing data.
2. **Enums for closed sets.** Anything with a fixed, known set of values — gender, status, role, temperature band, forecast window, payment method — is an `enum` (C#) or `StrEnum` (Python), not a `string`. Pass enums through services and only stringify at the API boundary. If you find yourself writing `if (x == "foo" || x == "bar")`, you needed an enum two refactors ago.
3. **Layered project structure.** Even a minimal API has layers: **Domain** (entities, value objects, enums, domain services — no framework dependencies), **Application** (use cases, DTOs, orchestration), **Infrastructure** (external APIs, persistence, file I/O), **Api** (endpoints, request/response models, DI wiring). For a small project, separate **projects** (`*.csproj`) are ideal; at minimum, separate **folders** with a one-direction dependency rule (Api → Application → Domain; Infrastructure → Application/Domain). Do not put HTTP-client code next to endpoint code in `Program.cs`.
4. **Inputs are explicit and validated.** Endpoint parameters and request DTOs are **nullable** types with `[Required]` (C#) or `Field(...)` with no default (Python/pydantic), so a missing field returns 400 instead of silently using a default. A renamed query-string parameter on the frontend must break loudly on the backend — never silently fall back. Add `ProblemDetails` (or the framework equivalent) for validation failures.
5. **Backend returns data, not user-facing copy.** Do not return English (or any locale) strings like `"Rain likely (40%) — stay dry."` from the backend. Return the structured values (`{ band: "warm", precipitationProbability: 40, isRainy: true }`) and let the frontend compose the message. Backend strings are an i18n trap and couple presentation to data.
6. **Single responsibility, strictly.** If a method parses input *and* calls an API *and* maps a result, split it. The 3–30 line rule above is the floor; the real test is "can I describe what this method does in one sentence without using 'and'?"
7. **Constants files / classes.** Group related constants (HTTP header names, claim types, weather codes, etc.) into a static class or module. Don't sprinkle them at the top of arbitrary files.

### Frontend code quality (React / TypeScript)

1. **`App.tsx` is a thin shell.** It mounts providers (router, query client, theme, error boundary) and renders the route tree — typically 10–20 lines. Real UI lives in `src/pages/<page>.tsx` or `src/features/<feature>/`. If `App.tsx` grows past ~30 lines or contains business logic, extract a page/feature component.
2. **Components composed of small pieces.** A component over ~150 lines is a smell — break it into a container + presentational children, or extract hooks. Each component does one thing.
3. **Hooks for side effects and shared logic.** `useEffect` belongs in custom hooks named for what they do (`useLocation`, `useOutfit`), not inlined inside page components when the logic is reusable.
4. **No business logic in JSX.** Compute in hooks or memos, render the result. JSX should read top-to-bottom as a description of the page.

## Testing UIs: Playwright MCP first

Whenever a task involves **driving a real browser** — writing E2E tests, verifying a UI change in the running app, taking a screenshot, reproducing a UI bug — **prefer the Playwright MCP** if it is registered in the current Claude Code session (look for tools whose names contain `playwright`, typically prefixed `mcp__`). The MCP lets you navigate, click, fill, snapshot the DOM, and read accessible names directly, without writing or running shell commands.

State which Playwright MCP tools you're about to call before calling them, so the rule is visible in transcripts (mirrors the context7 rule).

If the Playwright MCP is **not** available in the current session, do not silently fall back. Surface the gap to the user and recommend a replacement, in this preference order:

1. **Standalone `@playwright/test`** — install (or use) it in `/frontend/` and run `npx playwright test`. Best when E2E is going into CI anyway.
2. **Manual verification with screenshots / curl** — fine for one-shot bug confirmation, useless as a regression test. Mention it as a stopgap only.
3. **Pause and ask** — if the MCP was expected to be there, fixing the MCP setup may be the right move rather than working around it.

Recommend (1) by default when the MCP is absent, but say explicitly "Playwright MCP would normally be preferred — it's not registered in this session" so the user can choose to fix the setup instead.

For unit / component / hook tests, this rule does **not** apply — those go through `implement-tests` (Vitest, Testing Library, etc.) with no browser involved.

## Build pipelines

Default CI/CD is GitHub Actions. Implement build pipelines as GitHub workflows under `.github/workflows/` unless the user specifies a different platform.

### Dockerization & build artifacts

Containerization is a first-class concern, decided at **scaffold time** — not bolted on after the fact. Every component is scaffolded so that the moment CI runs, it produces a deployable artifact with no extra wiring.

- **Backend-type components** — `/backend` and every `/ai-services/<name>/` — ship a multi-stage `Dockerfile` **and** a `.dockerignore` from the moment they're scaffolded. The CI artifact for these is a **container image**, built and pushed to **GitHub Container Registry (GHCR)** at `ghcr.io/<owner>/<repo>-<component>`, tagged `latest`, `sha-<short-sha>`, and `<semver>` on a version tag. Image push authenticates with the workflow's built-in `GITHUB_TOKEN` (`permissions: packages: write`) — no long-lived secret. Cloud **deploy** steps still use OIDC.
- **Frontend** (`/frontend`) is **not** containerized. Its build artifact is the static `dist/` bundle, deployed to static hosting (S3 + CloudFront / Cloud Storage + CDN) via the frontend workflow's sync step. Do not write a production `Dockerfile` for the frontend.
- **Local dev** uses a single root `docker-compose.yml` that boots the whole stack. `scaffold-monorepo` emits it; each component scaffold registers its own service. Backend / ai-services use `build: ./<dir>`; the frontend runs as a stock `node:lts-alpine` dev container (bind mount + `npm run dev`), so it needs no Dockerfile. No database/cache service unless a component requires one.
- **Dockerfile conventions** (for the components that have one): multi-stage build; base-image major confirmed via context7 (don't guess the tag); run as a **non-root** user; a single documented `EXPOSE` port; and a `.dockerignore` that keeps the build context small (`bin/`, `obj/`, `node_modules/`, `__pycache__/`, `.venv/`, `.git/`, test output).

When you scaffold or extend any backend-type component, treat "does this produce a GHCR image artifact and a compose service?" as part of done — not an optional follow-up.
