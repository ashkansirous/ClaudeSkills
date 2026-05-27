---
name: implement-backend
description: Implement backend features (endpoints, services, repositories, domain logic) in the existing /backend, in whichever language is already in use (C#/.NET or Python). Detects framework and conventions from the codebase; fetches current docs via context7. Triggers: "add a backend endpoint", "implement the X service", "add the API for X", "build the backend for this feature", or invocation as `/implement-backend`.
---

This skill implements features in an **existing** backend. It detects
the language (C# or Python per `home/CLAUDE.md` defaults) and framework
from the project files, then implements the feature as a vertical slice
following stack-appropriate best practices.

## When to use this skill

Invoke this skill **only**:

- When `/backend` exists with a solution/project already in place.
- When the user wants to add backend functionality — a new endpoint,
  service method, repository, domain rule, migration, etc.

Do **not** invoke this skill:

- For initial scaffold — use `scaffold-csharp-api` (or future
  Python equivalent) instead.
- For frontend work — use `implement-frontend`.
- For pure infrastructure — use `implement-infrastructure`.

## Detect language and framework first

Read `/backend` to figure out what's in use:

| Marker                              | Stack                   |
| ----------------------------------- | ----------------------- |
| `*.sln` + `*.csproj`                | .NET / C#               |
| `Program.cs` with `WebApplication`  | ASP.NET Core minimal API|
| `Startup.cs` + `[ApiController]`    | ASP.NET Core MVC        |
| `pyproject.toml` with `fastapi`     | FastAPI (Python)        |
| `pyproject.toml` with `django`      | Django                  |
| `pyproject.toml` with `flask`       | Flask                   |

Also read:
- `CLAUDE.md` / `AGENTS.md` at the repo root for project-specific
  conventions.
- The closest existing feature to copy patterns from (folder
  structure, naming, DI registration style, error handling).

## Fetch current docs before writing code

Use the **context7 MCP** for whatever stack you detected. Examples:

- C# / ASP.NET Core: `/dotnet/aspnetcore` + `/dotnet/efcore` (if EF
  is in use) + library docs for anything you're adding.
- Python / FastAPI: `/tiangolo/fastapi` + `/pydantic/pydantic` +
  `/sqlalchemy/sqlalchemy` (or whichever ORM is in use).

API surface and idioms shift between majors. Do not write controller
attributes, dependency-injection registrations, or ORM queries from
memory.

## Best practices (apply to whichever stack is detected)

These translate across .NET and Python — pick the language-appropriate
form.

1. **Vertical slice.** For a new feature, implement the full slice
   (entity / model → repository / data access → service / use case →
   endpoint / route) in one pass, with tests, before moving on.
   Matches the `home/CLAUDE.md` "vertical slices over horizontal
   layers" rule.

2. **Method size.** 3–30 lines, single responsibility, per
   `home/CLAUDE.md`. If a method grows past 30, extract a private
   helper.

3. **Dependency injection.** Everything goes through the framework's
   DI container — no `new` for services, no static singletons. Inject
   abstractions where you want substitutability for tests.

4. **Async all the way.** Async methods return `Task` / `Task<T>` (C#)
   or `async def` (Python). No `.Result`, no `.Wait()`, no
   `asyncio.run` from inside async code. Propagate `CancellationToken`
   (C#) or be `cancel`-aware (Python).

5. **Validation at the boundary.** Validate input on entry —
   `FluentValidation` / DataAnnotations (C#) or `pydantic` (Python).
   Domain layer assumes validated input.

6. **DTOs separate from entities.** Never expose ORM entities through
   the API. Map to a DTO/response model.

7. **Error handling.** Pick one model (Result types or exceptions) and
   stick to it. Map domain errors to HTTP status codes in one place
   (middleware in .NET, exception handler in FastAPI).

8. **Idempotency for mutations.** POST / PUT endpoints that mutate
   external state should accept an idempotency key when the operation
   is retryable.

9. **Logging and observability.** Structured logging only — no
   `Console.WriteLine` / `print`. Include the request correlation id.

10. **No business logic in controllers / endpoints.** The endpoint
    parses input, calls a service, formats the response. Logic goes
    in the service / domain layer.

## Process

1. **Detect** language, framework, and existing patterns.
2. **Fetch current docs** via context7 for everything you're about to
   touch.
3. **Plan the vertical slice** — list the files you'll add/change
   (entity, repo, service, endpoint, DTO, validator, tests). Share
   the list with the user briefly before writing code.
4. **Implement** each piece, following the project's existing
   conventions and the best practices above.
5. **Add tests** by calling `implement-tests`. Don't skip them — at
   minimum, one happy-path and one failure-path test for the new
   endpoint.
6. **Build and run:**
   - C#: `dotnet build && dotnet test`.
   - Python: `ruff check && pytest`.
   - Then start the app locally and hit the new endpoint
     (`curl` / HTTPie) to confirm it works end-to-end.
7. **Commit on the current feature branch.** Do not push unless asked.

## Verification

- Build clean.
- All tests pass (existing + new).
- The new endpoint or method behaves correctly when called end-to-end
  (manual smoke test or integration test).
- ESLint-equivalent linter (e.g. `dotnet format --verify-no-changes`,
  `ruff check`) passes.
