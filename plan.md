# Plan: Bake dockerization into the scaffolding skills

## Context

The scaffolding skills don't treat containerization as a first-class
concern. Today only `scaffold-csharp-api` ships a real `Dockerfile`;
`scaffold-genai-service` mentions one in passing without a spec; and
nothing defines a repo-wide policy. The goal: every **backend-type**
component should ship a container artifact at scaffold time, so that
when a branch merges, the GitHub Actions build pipeline produces a
dockerized image as its artifact — ready to deploy — rather than the
user wiring Docker up after the fact.

Decisions locked with the user:

- **Registry:** GitHub Container Registry (**GHCR**). Image push uses
  the auto-provisioned `GITHUB_TOKEN` (`permissions: packages: write`) —
  no extra secret, works day one. Cloud deploy steps still use OIDC.
- **Frontend is NOT containerized.** Its build artifact is the static
  `/dist` bundle, deployed to static hosting (S3 / Cloud Storage) via
  the existing `frontend.yml` sync. It participates in local
  `docker-compose` only as a stock-`node` dev container (no committed
  Dockerfile).
- **Local dev:** `scaffold-monorepo` emits a root `docker-compose.yml`
  from day one; each component scaffold fills in its service.
- **Leave `implement-backend` / `implement-frontend` untouched** — the
  cross-cutting rule in `home/CLAUDE.md` covers them; no skill bloat.

Dockerized components = `/backend` (C#) + `/ai-services/*`. Frontend =
static artifact. Infra = consumes GHCR images, produces no artifact.

## Changes (7 files)

- [ ] **1. `home/CLAUDE.md`** — add a "Dockerization & build artifacts"
  subsection under "Build pipelines": GHCR image artifacts for
  `/backend` + `/ai-services/*` (`ghcr.io/<owner>/<repo>-<component>`,
  tags `latest` / `sha-<short>` / `<semver>`); frontend = static
  `/dist` artifact, not a container; root `docker-compose.yml` for
  local dev; Dockerfile conventions (multi-stage, context7-confirmed
  base major, non-root, single `EXPOSE`, `.dockerignore`).
- [ ] **2. `scaffold-monorepo/SKILL.md`** — emit a root
  `docker-compose.yml` (fill-in-as-scaffolded; frontend as
  `node:lts-alpine` dev container, no DB by default); reference it in
  root README; add a compose-spec context7 query.
- [ ] **3. `scaffold-csharp-api/SKILL.md`** — add `backend/.dockerignore`;
  register the `backend` service in the root compose; tie the image to
  the GHCR artifact.
- [ ] **4. `scaffold-genai-service/SKILL.md`** — replace the bare
  `Dockerfile` entry with a multi-stage non-root spec; add
  `.dockerignore`; register the compose service; tie to GHCR.
- [ ] **5. `scaffold-github-actions/SKILL.md`** — main change: add
  `docker/login-action` + `docker/build-push-action` context7 queries;
  GHCR login + build-push in `backend.yml` and `ai-services.yml`
  (`permissions: packages: write`, tags); clarify `frontend.yml` is a
  static bundle, not a container; document `GITHUB_TOKEN` vs OIDC.
- [ ] **6. `scaffold-iac/SKILL.md`** — one paragraph: `container-host`
  module pulls the GHCR image; registry-pull auth notes (Cloud Run
  public/secret, ECS `repositoryCredentials`); image ref as a module
  variable.
- [ ] **7. `scaffold-react-app/SKILL.md`** — "production = static
  hosting, not a container" note; register the dev-only `node` service
  in the root compose. Reconciles the no-frontend-Dockerfile +
  compose-includes-frontend decisions.
- [ ] **README.md** (repo root) — `scaffold-monorepo` bullet mentions
  the root compose; `scaffold-github-actions` bullet mentions GHCR.

## Out of scope
- `implement-backend`, `implement-frontend` — untouched (user choice).
- No database/cache services in compose unless a future component
  needs them.
- No Kubernetes / Helm — managed container hosting only.
- Mirroring images to GAR/ECR — GHCR only.

## Git workflow
These edits build on the open **PR #8** (`feat/scaffolding-skills`),
which is unmerged and touches the same files, so they're committed to
that same branch to avoid conflicts. Commit in logical steps, push,
update PR #8 body.

## Verification
- **Static:** re-read each edited `SKILL.md` for cross-file
  consistency — GHCR path, non-root, `.dockerignore`, compose service
  names all match.
- **Dry-run (manual, throwaway scratch repo):** `/scaffold-monorepo`
  produces the root compose; `/scaffold-csharp-api` +
  `/scaffold-genai-service` each produce `Dockerfile` + `.dockerignore`
  + a compose service, `docker compose build` succeeds, `docker compose
  up` boots both containers + the frontend dev server;
  `/scaffold-github-actions` produces GHCR build-push steps and a
  static `frontend.yml`.
- **Lint:** workflows pass `actionlint`; compose passes
  `docker compose config`.
