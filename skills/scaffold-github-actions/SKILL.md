---
name: scaffold-github-actions
description: Generate GitHub Actions workflows under .github/workflows/ for whichever components exist in the monorepo (backend, frontend, infra, ai-services). Detects components automatically; uses OIDC for cloud auth (no long-lived secrets). Run after at least one component has been scaffolded. Triggers: "set up CI", "add the GitHub Actions", "wire up the pipeline", "scaffold CI", or invocation as `/scaffold-github-actions`.
---

This skill generates the CI/CD workflows for the monorepo. It **detects**
which components exist and only generates workflows for what's present.

Per `home/CLAUDE.md`, default CI/CD is GitHub Actions. Always use OIDC
for cloud auth — no long-lived secrets.

## When to use this skill

Invoke this skill **only**:

- After at least one component (`/backend`, `/frontend`, `/infra`, or
  `/ai-services/*`) has been scaffolded.
- When the user wants the CI/CD wired up from scratch, OR when a new
  component was just added and needs its workflow.

Do **not** invoke this skill:

- If the user already has hand-crafted workflows they want to keep —
  this skill will overwrite by component name (`backend.yml`, etc.).
- For non-GitHub CI (GitLab, Azure DevOps, CircleCI) — those would need
  separate skills.

## Fetch current docs and versions before running — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not**
write a single workflow YAML line until you have logged context7
queries against:

- `/actions/setup-dotnet` — for backend workflows.
- `/actions/setup-node` — for frontend workflows.
- `/hashicorp/setup-terraform` — for infra workflows.
- `/docker/login-action` and `/docker/build-push-action` — for the
  GHCR image build/push in backend and ai-services workflows. The
  `tags:` / `images:` input shapes and the `docker/metadata-action`
  helper change between majors.
- `/google-github-actions/auth` **or**
  `/aws-actions/configure-aws-credentials` — depending on which cloud
  was scaffolded in `/infra/`.

State the library IDs you're about to query before calling, so the
user sees the rule being followed. Action versions and inputs shift
more than people realise — and an outdated `@vN` tag can fail in CI
with cryptic errors. Do not pin specific action `@vN` tags in this
skill. Use whatever context7 reports as the current major.

## Process

1. **Preflight:**
   - Verify `.github/workflows/` exists.
   - Detect components via marker files:
     - `/backend/*.sln` → backend present
     - `/frontend/package.json` → frontend present
     - `/infra/main.tf` → infra present
     - `/ai-services/*/` (any subfolder) → AI service present
   - Read `/infra/providers.tf` (if present) to learn which cloud was
     scaffolded — drives the OIDC config.

2. **Generate workflows — one per detected component:**

   Per `home/CLAUDE.md` "Dockerization & build artifacts", backend-type
   components produce a **GHCR container image** as their CI artifact;
   the frontend produces a **static bundle**, not a container.

   ### `backend.yml` (if backend present)
   - **On PR:** `dotnet restore`, `dotnet build`, `dotnet test`.
   - **On push to `main` (and on version tags):** above + build the
     image from `backend/Dockerfile` and push to GHCR (see the GHCR
     step below) + trigger deploy (pull from GHCR).
   - Use `actions/setup-dotnet` with `dotnet-version` set to whatever
     `backend/global.json` (or the project files) target — read it,
     don't hard-code.

   ### `frontend.yml` (if frontend present)
   - **On PR:** `npm ci`, `npm run lint`, `npm run build`.
   - **On push to main:** above + `gsutil rsync` (GCP) or `aws s3 sync`
     (AWS) to the static-site bucket from `infra/` outputs.
   - The frontend artifact is the static `dist/` bundle — **do not**
     build or push a container image here. (Optionally
     `actions/upload-artifact` the `dist/` for inspection.)

   ### `infra.yml` (if infra present)
   - **On PR:** `terraform fmt -check`, `init`, `validate`, `plan`.
     Post plan as PR comment.
   - **On push to main:** manual-approval gate (`environment:
     production`) before `terraform apply`. Never auto-apply.

   ### `ai-services.yml` (if AI service present)
   - **On PR:** language-appropriate lint + test (Python: `ruff` +
     `pytest`; C#: `dotnet test`).
   - **On push to `main` (and version tags):** build the image from
     `ai-services/<name>/Dockerfile` and push to GHCR (see below),
     then deploy. One image per service if there are several.

3. **GHCR image build & push (backend + ai-services):**
   - Add `permissions:` to the job: `contents: read`,
     `packages: write` (the latter is what authorizes the GHCR push).
   - Log in with `docker/login-action`: `registry: ghcr.io`,
     `username: ${{ github.actor }}`,
     `password: ${{ secrets.GITHUB_TOKEN }}` — **no PAT or extra
     secret needed.**
   - Derive tags with `docker/metadata-action` for
     `ghcr.io/${{ github.repository }}-<component>`: emit `latest`
     (on default branch), `sha-<short>`, and the semver on tag pushes.
   - Build + push with `docker/build-push-action`
     (`context: ./<component-dir>`, `push: true`, `tags:` from the
     metadata step). Pin action majors to whatever context7 reports.

4. **Cloud auth (OIDC) for deploy workflows:**
   - Image **push** uses `GITHUB_TOKEN` (step 3); cloud **deploy**
     uses OIDC — keep the two distinct.
   - GCP: `google-github-actions/auth` with
     `workload_identity_provider` from `infra/` outputs.
   - AWS: `aws-actions/configure-aws-credentials` with the role ARN
     from `infra/` outputs.
   - Deploy pulls the image from GHCR; if `/infra` provisions private
     hosting, make sure the platform can pull from GHCR (see
     `scaffold-iac`'s registry-pull note).
   - Document required GitHub repo variables (`GCP_PROJECT_ID`,
     `WIF_PROVIDER`, `AWS_ROLE_ARN`, etc.) **and** that image push
     needs no secret beyond `GITHUB_TOKEN`, in
     `.github/workflows/README.md`.

6. **Path filters** — every workflow has `paths:` filters so backend
   doesn't run on frontend-only changes, etc.

7. **Sanity check:**
   - `gh workflow list` recognizes each workflow.
   - Pushing the branch triggers the expected workflows (first run will
     fail on missing OIDC variables — that's expected until
     `terraform apply` populates them). The GHCR push step should
     succeed on its own since it only needs `GITHUB_TOKEN`.

8. **Commit** with a message like `ci: scaffold GitHub Actions
   workflows for <detected components>`.

## Verification

- `gh workflow list` shows one workflow per detected component.
- A no-op PR triggers only the relevant workflows (path filters work).
- Each workflow's YAML passes `actionlint` if installed.
- `backend.yml` and `ai-services.yml` declare `packages: write` and
  push to `ghcr.io/<owner>/<repo>-<component>`; `frontend.yml` builds
  a static bundle and pushes no image.
