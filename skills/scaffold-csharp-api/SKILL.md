---
name: scaffold-csharp-api
description: Scaffold a fresh C# .NET Web API under /backend (latest stable .NET) with a health endpoint, Dockerfile, and xUnit test project. Run when /backend exists and is empty. Triggers: "add a C# backend", "scaffold the .NET API", "add a Web API", "init the backend", or invocation as `/scaffold-csharp-api`.
---

This skill scaffolds the C# .NET backend under `/backend`. Assumes the
monorepo skeleton already exists — run `scaffold-monorepo` first if
`/backend` is missing.

## When to use this skill

Invoke this skill **only**:

- After `scaffold-monorepo` has run, so `/backend` exists and is empty.
- When the user wants a fresh .NET Web API as the backend (matches the
  `home/CLAUDE.md` backend default for C# projects).

Do **not** invoke this skill:

- If `/backend` already has a `.sln` or projects — modify those by hand.
- For non-API .NET work (worker services, console apps, libraries).

## Fetch current docs and versions before running

Use the **context7 MCP** at the start of every invocation:

- `/dotnet/aspnetcore` — confirm current `dotnet new webapi` flags,
  minimal-API idioms, and the **latest stable .NET version**.
- `/xunit/xunit` — confirm current xUnit setup.

Do not pin a specific .NET version in the generated project unless the
user asks. Use whatever `dotnet --list-sdks` shows as the latest stable
on the user's machine, and confirm via context7 that it matches the
current GA release.

## Process

1. **Preflight:**
   - Verify `/backend` exists and is empty. If non-empty, ask before
     overwriting.
   - Run `dotnet --list-sdks` and pick the latest stable major. Cross-
     check against the context7 answer for current GA. If the user's
     machine is on an older major than current GA, ask whether to
     proceed or upgrade first.

2. **Generate the projects:**

   ```bash
   cd backend
   dotnet new sln -n Backend
   dotnet new webapi -n Api -o Api --use-minimal-apis
   dotnet new xunit -n Api.Tests -o Api.Tests
   dotnet sln add Api/Api.csproj Api.Tests/Api.Tests.csproj
   dotnet add Api.Tests/Api.Tests.csproj reference Api/Api.csproj
   ```

3. **Replace boilerplate with a minimal vertical slice:**
   - `Api/Program.cs` — minimal API with one `GET /health` endpoint
     returning `{ "status": "ok" }`.
   - `Api.Tests/HealthEndpointTests.cs` — one xUnit test that calls
     `/health` via `WebApplicationFactory` and asserts `200 OK`.
   - Delete the default `WeatherForecast` sample.

4. **Add a `Dockerfile`** at `backend/Dockerfile` — multi-stage build
   using the matching `mcr.microsoft.com/dotnet/sdk:<version>` and
   `aspnet:<version>` images (substitute the major version the project
   targets). Expose port 8080, run as non-root.

5. **Add `backend/README.md`** — sections: run locally
   (`dotnet run --project Api`), test (`dotnet test`), build container
   (`docker build`).

6. **Sanity check:**
   - `dotnet build` succeeds.
   - `dotnet test` passes.
   - `dotnet run --project Api` serves `/health` returning `200`.

7. **Commit on the current feature branch** with a message like
   `feat(backend): scaffold .NET Web API with health endpoint`. Do not
   push or open a PR unless asked.

## Code quality reminders (from home/CLAUDE.md)

- Every method 3–30 lines, single responsibility.
- Prefer minimal-API endpoints over controllers for simple cases.
- Use `IOptions<T>` and the built-in DI container — no manual
  singletons.

## Verification

- `cd backend && dotnet build` succeeds.
- `dotnet test` passes.
- `dotnet run --project Api` serves the health endpoint with a 200.
- `docker build -t backend backend/` builds cleanly.
