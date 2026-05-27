---
name: implement-tests
description: Write tests for existing code in any stack (backend or frontend) — detects the test framework already in use, fetches its current docs via context7, and applies framework-appropriate best practices. Triggers: "add tests for X", "write a test", "increase test coverage on X", "test this function/component/endpoint", or invocation as `/implement-tests`.
---

This skill writes tests for code that already exists. It detects the
test framework in use from the project's manifest files and applies the
patterns idiomatic to that framework — it does **not** scaffold a fresh
test project.

## When to use this skill

Invoke this skill **only**:

- When code under test already exists.
- When the user wants tests added for a specific function, component,
  endpoint, or module.
- Often called from `implement-backend` / `implement-frontend` as the
  final "add tests for this feature" step.

Do **not** invoke this skill:

- To scaffold a fresh test project — that's part of the
  `scaffold-csharp-api` / `scaffold-react-app` skills.
- To write smoke tests purely for coverage numbers — tests must
  meaningfully exercise behaviour.

## Detect the framework first

Read the project to figure out which framework is in use:

| Marker file                              | Framework          |
| ---------------------------------------- | ------------------ |
| `*.Tests.csproj` with xunit package      | xUnit (.NET)       |
| `*.Tests.csproj` with nunit package      | NUnit (.NET)       |
| `pytest.ini` / `pyproject.toml` with pytest | pytest (Python) |
| `package.json` with `vitest`             | Vitest             |
| `package.json` with `jest`               | Jest               |
| `package.json` with `@playwright/test`   | Playwright (E2E)   |

If multiple are present (e.g. Vitest for unit + Playwright for E2E),
pick the one that fits the layer being tested.

## Fetch current docs before writing tests

Use the **context7 MCP** for the detected framework:

- `/xunit/xunit` for xUnit (plus `/dotnet/aspnetcore` for
  `WebApplicationFactory` / `TestServer` patterns).
- `/pytest-dev/pytest` for pytest (plus `/encode/httpx` or
  `/tiangolo/fastapi` for HTTP-client-based testing).
- `/vitest-dev/vitest` for Vitest (plus
  `/testing-library/react-testing-library` for React).
- `/microsoft/playwright` for Playwright.

Framework APIs change. Don't write fixtures, async patterns, or
mocking helpers from memory — verify against current docs.

## Best practices (framework-agnostic)

These apply regardless of stack:

1. **Test naming** — describe behaviour, not implementation. Pattern:
   `MethodOrComponent_Scenario_ExpectedOutcome`. Examples:
   `Withdraw_AmountExceedsBalance_ThrowsInsufficientFunds`,
   `LoginForm_SubmitsInvalidEmail_ShowsErrorMessage`.

2. **AAA structure** — Arrange, Act, Assert. Blank lines between.

3. **One logical assertion per test.** Multiple physical asserts are
   fine if they verify one concept (e.g. asserting the three fields of
   a returned object).

4. **No test interdependence.** Each test must pass in isolation.
   Avoid shared mutable state, ordered tests, or "set up in test A,
   verify in test B".

5. **Don't mock what you don't own.** Mock your own interfaces; for
   third-party APIs use a thin adapter and mock the adapter. Don't
   mock the database — prefer an in-memory or test-container instance.

6. **Test the boundary, not the implementation.** Black-box tests
   survive refactors; white-box tests break on every change.

7. **Validate the test by breaking the code.** A test that always
   passes is worse than no test. Before declaring done, briefly
   change the production code to a wrong value and confirm the test
   fails.

8. **Test pyramid** — many unit, fewer integration, very few E2E. If
   you're tempted to spin up the full stack for a pure-logic test,
   move it down a level.

## Process

1. **Detect the framework** (see table above).
2. **Fetch current docs via context7** for the detected framework.
3. **Read the code under test** and the surrounding tests (if any) to
   match style.
4. **Write the test(s)** following the best practices above and the
   framework's current idioms.
5. **Run the tests** — they must all pass.
6. **Validate by mutation:** temporarily break the production code,
   re-run, confirm at least one test fails. Restore the code.
7. **Commit on the current feature branch** with a message like
   `test(<scope>): cover <behaviour>`. Do not push unless asked.

## Verification

- Tests pass when production code is correct.
- Tests fail when production code is mutated to a wrong value
  (mutation check).
- No flaky tests — run them twice in a row; both runs pass.
- Coverage of the targeted behaviour, not just lines.
