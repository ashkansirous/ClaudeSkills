---
name: scaffold-csharp-api
description: Scaffold a C# .NET Web API under /backend with a health endpoint, Dockerfile, and xUnit test project. Use when the user says "add a C# backend", "scaffold the .NET API", "add a Web API", "init the backend", or invokes `/scaffold-csharp-api`.
---

This skill scaffolds the C# .NET backend under `/backend`. Assumes the
monorepo skeleton already exists — run `scaffold-monorepo` first if
`/backend` is missing.

Follows the language defaults in `home/CLAUDE.md`: **C# 15 on .NET 10**,
methods 3–30 lines, single responsibility per method.

## Process

1. **Preflight:**
   - Verify `/backend` exists and is empty. If non-empty, ask before
     overwriting.
   - Verify `dotnet --version` is .NET 10. If older, stop and tell the
     user to upgrade — do not fall back silently.
   - Use `context7` MCP (`/dotnet/aspnetcore` or similar) to confirm
     current `dotnet new webapi` template flags and minimal-API
     idioms for .NET 10.

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
   using `mcr.microsoft.com/dotnet/sdk:10.0` for build and
   `mcr.microsoft.com/dotnet/aspnet:10.0` for runtime. Expose port
   8080, run as non-root user.

5. **Add `backend/README.md`** — one section each: run locally
   (`dotnet run --project Api`), test (`dotnet test`), build container
   (`docker build`).

6. **Sanity check:**
   - `dotnet build` succeeds.
   - `dotnet test` passes the health test.
   - `dotnet run --project Api` serves `/health` returning `200`.

7. **Commit on the current feature branch** with a message like
   `feat(backend): scaffold .NET 10 Web API with health endpoint`. Do
   not push or open a PR unless asked — that's the user's call.

## Code quality reminders

- Every method 3–30 lines, single responsibility (from `home/CLAUDE.md`).
- Prefer minimal-API endpoints over controllers for simple cases; use
  controllers only when the endpoint needs model binding, filters, or
  shared route prefixes.
- Use `IOptions<T>` and the built-in DI container — no manual
  singletons.

## Verification

- `cd backend && dotnet build` → succeeds.
- `dotnet test` → health endpoint test passes.
- `dotnet run --project Api` → `curl http://localhost:5000/health`
  (or whatever port the launch settings use) returns
  `{"status":"ok"}`.
- `docker build -t backend backend/` → image builds cleanly.
