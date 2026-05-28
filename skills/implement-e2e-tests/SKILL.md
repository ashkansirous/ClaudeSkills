---
name: implement-e2e-tests
description: Write end-to-end UI tests with Playwright — drives the frontend in a real browser and asserts user-visible behaviour. Prefers the Playwright MCP when it is registered in this Claude Code session; falls back to standalone `@playwright/test`. Triggers: "add E2E tests for X", "write Playwright tests", "test this user flow end-to-end", "add UI tests", or invocation as `/implement-e2e-tests`.
---

This skill writes **end-to-end** tests that drive a real browser
against the running application. It is the E2E counterpart to
`implement-tests`, which covers unit / integration / component tests.

## When to use this skill

Invoke this skill **only**:

- When the user wants to test a complete user flow through the UI
  (login → dashboard → action → result), not a single component.
- When the test should fail if the backend, frontend, or wiring
  between them is broken — i.e. it asserts the *integrated* system.
- After `implement-frontend` (and usually `implement-backend`) have
  produced the feature being tested.

Do **not** invoke this skill:

- For unit tests, component tests, hook tests, or backend integration
  tests — use `implement-tests` instead.
- For visual regression / screenshot diff suites — those are a
  different tool (Percy, Chromatic). Mention it and stop.
- When `/frontend` is not running and can't be started — say so and
  ask the user to start it (or wire `docker-compose up`).

## Playwright MCP first, fallbacks second

The user keeps the **Playwright MCP** registered in their Claude Code
setup (`mcp__*playwright*` tools). This MCP gives Claude direct
control of a browser — you can navigate, click, fill, and read the
DOM without writing or running any code yourself. **Always prefer the
MCP** for both authoring and verifying E2E tests:

1. **At skill start, scan the tool list** for any tool whose name
   contains `playwright` (typical names: `mcp__playwright__navigate`,
   `mcp__playwright__click`, `mcp__playwright__snapshot`, etc.).
2. If found, use the MCP to:
   - Drive the live UI while exploring the flow (so the spec you
     write matches what actually happens).
   - Capture selectors / accessible names from the rendered DOM
     instead of guessing.
   - Verify each `await page...` step before pasting it into a spec.
3. **State which MCP tools you're about to call** before calling
   them, so the user sees the rule from `home/CLAUDE.md`
   ("UI testing prefers Playwright MCP") being followed.

If the Playwright MCP is **not** registered in the current session,
do not silently fall back — surface the gap to the user and offer
options:

- **Standalone `@playwright/test`** — install it in `/frontend/` (or
  the repo root) and write the spec; the test will run headlessly
  via `npx playwright test`. Best when E2E will be part of CI anyway.
- **Manual verification with screenshots** — fine for a one-shot
  bug confirmation, useless as a regression test. Mention it as a
  stopgap only.
- **Skip and ask** — if the user expected the MCP to be there, the
  right move may be to fix the MCP setup rather than work around it.
  Surface this option, do not assume.

Recommend the first one (`@playwright/test`) by default when the MCP
is absent, but explicitly say "the Playwright MCP would normally be
preferred — it's not available in this session" so the user can
decide whether to fix the setup instead.

## Fetch current docs before writing tests — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not**
write a single line of spec code until you have logged context7
queries against:

- `/microsoft/playwright` — for the current `@playwright/test` API
  (test fixtures, `expect` matchers, `page.locator` semantics,
  auto-waiting rules, `webServer` config, projects, traces).
- The relevant frontend framework (`/reactjs/react.dev`,
  `/tanstack/router`, etc.) if you need to understand how the page
  is structured.

State the library IDs you're about to query before calling. Playwright
in particular has shifted heavily — `getByRole` defaults, `expect`
auto-retry, fixture composition, and the project model all changed.
"I know Playwright" is exactly the rationalisation the hard
precondition exists to defeat.

## Where the tests live

The default home for E2E specs is `/frontend/e2e/` (separate from
`/frontend/src/`). If the repo already has `e2e/` at the root, use
that instead. Structure:

```
frontend/e2e/
  fixtures/         # shared test fixtures (auth, seeded data)
  pages/            # page-object classes
  specs/
    <feature>.spec.ts
  playwright.config.ts
```

If `@playwright/test` isn't installed yet, add it and create a minimal
`playwright.config.ts` with:

- `webServer` block that boots `npm run dev` (frontend) and waits on
  the dev port.
- A single `chromium` project for the first slice; add `firefox` /
  `webkit` only when the user asks for cross-browser.
- `trace: 'on-first-retry'` so failures are debuggable.
- `testDir: './specs'`.

## Best practices

1. **One spec per user flow**, not one spec per page. The test name
   describes the user's intent (`books a flight`, `recovers password`),
   not the file under test.

2. **Page-object model.** Wrap each page in a class
   (`SearchPage`, `CheckoutPage`) that exposes intent-level methods
   (`page.searchFor("Berlin")`) and hides selectors. Specs read like
   prose; selectors live in one place and can be updated without
   touching every test.

3. **Selectors by accessible name, not CSS.** Prefer
   `page.getByRole('button', { name: 'Submit' })`,
   `page.getByLabel('Email')`, `page.getByText(...)`. Use
   `getByTestId('…')` only when no accessible name exists — and
   add the `data-testid` to the component in that case.

4. **No `waitForTimeout`.** Playwright auto-waits on locators.
   `page.waitForTimeout(500)` is a flaky-test factory. If you need
   to wait for a specific condition, `await expect(locator).toBeVisible()`
   or `await page.waitForResponse(...)`.

5. **Independent tests, isolated state.** Each spec must pass on its
   own and in parallel with others. Seed/clean per-test, not
   per-suite. Use `test.beforeEach` for shared setup, not module-level
   variables.

6. **Trace + screenshot on failure.** Configured in
   `playwright.config.ts` (`trace: 'on-first-retry'`,
   `screenshot: 'only-on-failure'`). Don't add manual screenshot
   calls in tests.

7. **Real backend, not mocks.** E2E means E2E. If you need to fake
   a third-party API (Stripe, OpenAI), do it at the network layer
   with `page.route(...)` — not by mocking the frontend client.

8. **Don't test what unit/component tests already cover.** E2E is
   slow and brittle; reserve it for the integrated paths that only
   E2E can verify (auth flow, payment, navigation that crosses
   routes). Single-component behaviour belongs in Vitest +
   Testing Library.

9. **Test the happy path first, then the one critical failure.**
   For a checkout flow: one happy path (place order successfully)
   + one failure (card declined → error shown). Don't fan out into
   ten edge cases at the E2E layer.

## Process

1. **Detect environment:**
   - Is the Playwright MCP registered? (`mcp__*playwright*` in the
     tool list).
   - Is `@playwright/test` installed in `/frontend/package.json`?
   - Is there an existing `e2e/` directory? If so, match its style.

2. **State the plan briefly** to the user: which flow you'll test,
   which MCP / fallback you'll use, and where the spec file will
   live. One short paragraph, then proceed.

3. **Fetch context7 docs** for `/microsoft/playwright`.

4. **(If MCP available) Walk the flow live in the browser** using
   the MCP — navigate, interact, snapshot the DOM. Capture the
   actual accessible names, ARIA roles, and response shapes so the
   spec doesn't lie about them.

5. **Write the spec(s)** following the best practices above. Page
   objects in `pages/`, fixtures in `fixtures/`, the spec itself
   describing the user flow in prose-like steps.

6. **Run the tests** — `npx playwright test`. They must all pass.

7. **Mutation-validate one critical assertion** — break the frontend
   (e.g. comment out the submit handler), re-run, confirm the spec
   fails for the right reason. Restore the code.

8. **Add a `frontend/e2e/README.md`** if absent — sections: how to
   run locally, how the page-object model is organised, how to debug
   a failing run (UI mode, trace viewer).

9. **Commit on the current feature branch** with a message like
   `test(e2e): cover <user flow>`. Do not push unless asked.

## Verification

- `npx playwright test` passes locally, with the frontend (and
  backend, if needed) running.
- Mutation-check on at least one critical assertion: production code
  broken → spec fails for the right reason.
- The spec reads top-to-bottom as a user flow — a non-Playwright
  reader can follow what's being tested.
- No `waitForTimeout` calls, no `sleep`, no `setTimeout` workarounds.
- CI workflow includes the E2E job (or the user is told what needs
  adding to `.github/workflows/`).
