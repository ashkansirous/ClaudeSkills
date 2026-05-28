---
name: implement-frontend
description: Implement frontend features (pages, components, hooks, state) in the existing /frontend React + TypeScript app. Detects state management, styling, and data-fetching libraries already in use; fetches current docs via context7; enforces ESLint. Triggers: "add a page for X", "build the UI for X", "implement the frontend for this feature", "add a component", or invocation as `/implement-frontend`.
---

This skill implements UI features in an **existing** React frontend. It
detects which libraries are in use and matches the project's existing
patterns rather than imposing new ones.

## When to use this skill

Invoke this skill **only**:

- When `/frontend` exists with a working React + TypeScript app.
- When the user wants new UI — a page, component, hook, form, etc.

Do **not** invoke this skill:

- For initial scaffold — use `scaffold-react-app`.
- For pure CSS/styling tweaks unrelated to component logic — those
  don't need this much ceremony.
- For non-React frontends (Svelte, Vue, etc.) — would need a separate
  skill.

## Detect the stack first

Read `/frontend/package.json` to figure out what's in use. Look for:

| Library                                 | Role               |
| --------------------------------------- | ------------------ |
| `@tanstack/react-query` / `swr`         | Data fetching      |
| `zustand` / `redux` / `jotai`           | Global state       |
| `react-hook-form` + `zod`               | Forms + validation|
| `tailwindcss` / `styled-components`     | Styling            |
| `@radix-ui/*` / `shadcn` / `mui`        | Component library  |
| `react-router-dom` / `@tanstack/router` | Routing            |
| `vitest` / `jest`                       | Unit tests         |
| `@playwright/test`                      | E2E tests          |

Use whatever's already there. Do not introduce a new state/data/form
library without asking — pick from what's installed.

Also read:
- Existing components in `src/` to learn folder structure (e.g.
  `src/pages/`, `src/components/`, `src/hooks/`) and naming.
- `eslint.config.js` for the project's lint rules.
- `CLAUDE.md` / `AGENTS.md` for project-specific conventions.

## Fetch current docs before writing code — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not**
write a single line of UI code until you have logged context7 queries
for every library you'll touch:

- `/reactjs/react.dev` — for hooks, suspense, server components, and
  the v6 `eslint-plugin-react-hooks` rules
  (`react-hooks/set-state-in-effect`, `react-hooks/refs`, etc.) which
  change the patterns you can write inside `useEffect`.
- `/microsoft/TypeScript` — for current TS features (satisfies, const
  type parameters, etc.).
- Library-specific docs (`/tanstack/query`,
  `/react-hook-form/react-hook-form`, `/colinhacks/zod`,
  `/tailwindlabs/tailwindcss`, `/shadcn-ui/ui`, etc.) for whatever
  you're using.

State the library IDs you're about to query before calling, so the
user sees the rule being followed. React 19, Tailwind v4, and the
current lint plugins have idioms that older training data does not
reflect. Always verify — "I already know React" is not a valid
reason to skip; React 19 specifically broke patterns that worked in
18.

## Best practices

0. **`App.tsx` stays a thin shell.** It mounts providers (router,
   query client, theme, error boundary) and renders the route tree —
   typically 10–20 lines, no business logic, no `useState`, no
   `useEffect` for data fetching. Real UI lives in
   `src/pages/<Page>.tsx` or `src/features/<feature>/`. If a feature
   request would add logic to `App.tsx`, create a page/feature
   component instead. The same applies to other top-level shells
   (`Layout.tsx`, `Root.tsx`) — they compose, they don't compute.

1. **Function components + hooks only.** No class components.

2. **Strict TypeScript.** No `any`, no `as` casts except at clearly
   marked boundaries. Use `unknown` + narrowing. Use `satisfies` to
   constrain without widening.

3. **Composition over configuration.** Prefer small components that
   accept children / render-props over a giant component with 20 boolean
   props.

4. **Custom hooks for shared logic.** If two components share
   non-trivial state-or-effect logic, extract into a `useX` hook in
   `src/hooks/`.

5. **Data fetching** — use whatever library is already installed
   (`react-query` / `swr`). If none, plain `useEffect` with an abort
   signal and proper loading/error/success states. Never fetch without
   handling all three states.

6. **Server state vs. client state.** Don't pour server state into
   global stores (Redux/Zustand). Server state lives in the
   data-fetching cache; global stores hold UI state (modals, theme,
   filters).

7. **Forms** — use `react-hook-form` + `zod` if installed. Validate on
   blur for fields, on submit for the form. Show inline errors.

8. **Accessibility (a11y).**
   - Semantic HTML (`<button>` not `<div onClick>`).
   - Every form input has a `<label>` (or `aria-label`).
   - Focus management for modals and route changes.
   - Keyboard navigation works.
   - Run `axe` or `@axe-core/react` in dev.

9. **Performance — measure first.**
   - Don't sprinkle `useMemo` / `useCallback` everywhere. Profile, find
     a real bottleneck, then memoize.
   - Code-split route-level: `React.lazy` + `Suspense` for big pages.
   - `<img loading="lazy">` for below-the-fold images.

10. **Error boundaries** around route-level components so one broken
    page doesn't blank the whole app.

11. **ESLint must pass.** Per `home/CLAUDE.md`: frontend code must pass
    ESLint before a task is declared done. Run `npm run lint` and fix
    everything.

## Process

1. **Detect** the stack — read `package.json` and existing components.
2. **Fetch current docs** via context7 for everything you'll use.
3. **Plan** — list the components / hooks / pages you'll add. Share
   the list briefly before writing code so the user can redirect.
4. **Implement** following existing folder structure and best practices
   above. Reuse existing components / hooks where possible.
5. **Add tests** via `implement-tests` — at minimum, one test per
   component covering the main render path + one user interaction.
6. **Lint and build:**

   ```bash
   cd frontend
   npm run lint
   npm run build
   ```

   Both must be clean.

7. **Visual smoke test.** `npm run dev`, load the page, click through
   the feature, confirm it works against a running backend (or mocked
   API). If you can't run it (e.g. headless environment), say so
   explicitly — don't claim done without verifying.

8. **Commit on the current feature branch.** Do not push unless asked.

## Verification

- `npm run lint` clean.
- `npm run build` succeeds with no TS errors.
- Tests pass.
- Manual smoke test: the feature works in the dev server (or it's
  explicitly flagged as unverified-because-headless).
- Accessibility: keyboard navigation works, labels present, no axe
  violations on the new component.
