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

## Fetch current docs and versions before running — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not** run
`dotnet new`, write a `csproj`, or touch a single line of .NET code in
this skill until you have logged context7 queries against:

- `/dotnet/aspnetcore` — current `dotnet new webapi` flags,
  minimal-API idioms, parameter binding (`AsParameters`,
  `[FromQuery]`), DI patterns, and the **latest stable .NET version**.
- `/xunit/xunit` — current xUnit setup, `WebApplicationFactory`
  idioms.

State the library IDs you're about to query before calling, so the
user sees the rule being followed. "I already know minimal API" is not
a valid reason to skip this — APIs shift between majors and the rule
exists exactly because that's the easiest mistake to make.

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

2. **Offer architecture choices and confirm.** Per the
   `home/CLAUDE.md` "Backend architecture: offer choices" rule, do
   **not** silently scaffold one shape. Show the user a short list
   and let them pick:

   > Before generating, pick the architecture for `/backend`:
   >
   > 1. **Clean Architecture + DDD** *(recommended)* — `Domain` /
   >    `Application` / `Infrastructure` / `Api` projects, with DDD
   >    building blocks (entities, value objects, aggregates, domain
   >    events, repository interfaces in `Domain`). Best when the
   >    business logic is non-trivial and likely to grow.
   > 2. **Vertical-slice architecture** — one folder per feature
   >    (`Features/Orders/`, `Features/Users/`), each owning its
   >    handler + DTOs + persistence. Lighter for CRUD-heavy apps.
   > 3. **Modular monolith** — each bounded context as its own
   >    assembly with a public contract; appropriate when you already
   >    know the contexts.
   > 4. **Simple 3-layer N-tier** — `Api` / `Services` / `Data`. Only
   >    for throwaway or genuinely small apps.
   >
   > Default is #1 unless you say otherwise.

   Wait for the user to confirm before generating. The rest of this
   skill describes the **Clean Architecture + DDD** path (the
   default); if the user picks something else, adapt the project
   layout and the seed files accordingly but keep the
   no-magic-strings / enums / validated-inputs rules.

3. **Generate the projects (Clean Architecture + DDD layout).** Per
   the backend code-quality rules in `home/CLAUDE.md`, four layers as
   separate `*.csproj` projects:

   ```bash
   cd backend
   dotnet new sln -n Backend
   dotnet new classlib -n Domain         -o Domain
   dotnet new classlib -n Application    -o Application
   dotnet new classlib -n Infrastructure -o Infrastructure
   dotnet new webapi   -n Api            -o Api --use-minimal-apis
   dotnet new xunit    -n Api.Tests      -o Api.Tests

   dotnet sln add Domain/Domain.csproj Application/Application.csproj \
                  Infrastructure/Infrastructure.csproj Api/Api.csproj \
                  Api.Tests/Api.Tests.csproj

   # Dependency direction: Api → Application → Domain; Infrastructure → Application/Domain.
   dotnet add Application/Application.csproj       reference Domain/Domain.csproj
   dotnet add Infrastructure/Infrastructure.csproj reference Application/Application.csproj Domain/Domain.csproj
   dotnet add Api/Api.csproj                       reference Application/Application.csproj Infrastructure/Infrastructure.csproj
   dotnet add Api.Tests/Api.Tests.csproj           reference Api/Api.csproj
   ```

   **Domain** holds entities, value objects, aggregates, domain
   events, enums, and repository *interfaces* — zero framework
   dependencies. **Application** holds use cases / command + query
   handlers, DTOs, and orchestration. **Infrastructure** holds
   external API clients, persistence (EF Core implementations of the
   Domain repository interfaces), and file I/O. **Api** holds
   endpoints, request/response models, and DI wiring.

4. **Seed the DDD building blocks in `Domain/`.** Even though the
   first slice is trivial, scaffold the abstractions the *next*
   feature will reach for:

   - `Domain/Common/Entity.cs` — base class with an `Id` of type
     `Guid` (or strongly-typed id), equality by `Id`, and a
     protected constructor for EF Core.
   - `Domain/Common/ValueObject.cs` — abstract base with structural
     equality (override `GetEqualityComponents`).
   - `Domain/Common/IAggregateRoot.cs` — marker interface;
     aggregates implement it.
   - `Domain/Common/DomainEvent.cs` — base record with
     `OccurredOnUtc`; `Entity` exposes
     `IReadOnlyCollection<DomainEvent> DomainEvents` and
     `Raise(...) / ClearDomainEvents()`.
   - `Domain/Common/IRepository.cs` — generic repository contract
     (`GetByIdAsync`, `Add`, `Remove`) parameterised on aggregate
     root + id type. Concrete repositories live in
     `Infrastructure/Persistence/`.

   These are five small files but they encode the DDD contract for
   the rest of the project — without them, the "Domain layer" is
   just a folder.

5. **Replace boilerplate with a minimal vertical slice that
   demonstrates the layering and the conventions:**
   - `Domain/Health/HealthStatus.cs` — an
     `enum HealthStatus { Ok, Degraded, Down }`. Demonstrates
     enums-over-strings.
   - `Application/Health/IHealthCheck.cs` +
     `HealthCheckService.cs` — service returns `HealthStatus`, not
     a string.
   - `Api/Endpoints/HealthEndpoints.cs` — endpoint maps
     `HealthStatus` to the response DTO. No business logic in
     `Program.cs`.
   - `Api/Contracts/HealthResponse.cs` — response DTO with the enum
     serialized as a string at the boundary only (via
     `JsonStringEnumConverter`).
   - `Api/Constants/RouteKeys.cs` —
     `public const string Health = "/health";`. Demonstrates
     no-magic-strings.
   - `Api.Tests/HealthEndpointTests.cs` — one xUnit test that calls
     `RouteKeys.Health` via `WebApplicationFactory` and asserts
     `200 OK`.
   - Delete the default `WeatherForecast` sample.

   Even though this is one endpoint, scaffold it the way real
   features should be built. The structure exists so the *next*
   feature has a pattern to follow.

6. **Add a `Dockerfile`** at `backend/Dockerfile` — multi-stage build
   using the matching `mcr.microsoft.com/dotnet/sdk:<version>` and
   `aspnet:<version>` images (substitute the major version the project
   targets). Expose port 8080, run as non-root.

7. **Add `backend/README.md`** — sections: run locally
   (`dotnet run --project Api`), test (`dotnet test`), build container
   (`docker build`), and a short paragraph naming the architecture
   (e.g. "Clean Architecture + DDD") and the dependency direction
   between projects.

8. **Sanity check:**
   - `dotnet build` succeeds.
   - `dotnet test` passes.
   - `dotnet run --project Api` serves `/health` returning `200`.

9. **Commit on the current feature branch** with a message like
   `feat(backend): scaffold .NET Web API with Clean Architecture + DDD`.
   Do not push or open a PR unless asked.

## Code quality reminders (from home/CLAUDE.md "Backend code quality")

- Every method 3–30 lines, single responsibility.
- Prefer minimal-API endpoints over controllers for simple cases.
- Use `IOptions<T>` and the built-in DI container — no manual
  singletons.
- **No magic strings.** JSON keys, route segments, header names,
  property accessors → `const` or `nameof(...)`. A typo should be a
  compile error.
- **Enums for closed sets** (status, role, kind, band). Never pass raw
  strings between layers.
- **Layered structure** as scaffolded above. Even if the project grows,
  resist collapsing the layers — the next person reading this needs the
  boundaries to be visible.
- **Inputs are nullable + `[Required]`** on request DTOs and endpoint
  parameters, so a missing/renamed field fails with 400 instead of
  silently defaulting.
- **No user-facing English from the backend.** Return enums + numeric
  values; the frontend composes copy.

## Verification

- `cd backend && dotnet build` succeeds.
- `dotnet test` passes.
- `dotnet run --project Api` serves the health endpoint with a 200.
- `docker build -t backend backend/` builds cleanly.
