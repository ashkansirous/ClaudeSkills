---
name: scaffold-github-actions
description: Generate GitHub Actions workflows under .github/workflows/ for whichever components exist in the monorepo (backend, frontend, infra, ai-services). Uses OIDC to the cloud. Use when the user says "set up CI", "add the GitHub Actions", "wire up the pipeline", "scaffold CI", or invokes `/scaffold-github-actions`.
---

This skill generates the CI/CD workflows for the monorepo. It **detects**
which components exist (looks for non-empty `/backend`, `/frontend`,
`/infra`, `/ai-services` folders) and only generates workflows for what's
present.

Per `home/CLAUDE.md`, default CI/CD is GitHub Actions. Always use OIDC
for cloud auth — no long-lived secrets.

## Process

1. **Preflight:**
   - Verify `.github/workflows/` exists.
   - Detect which components exist by checking for marker files:
     - `/backend/*.sln` → backend present
     - `/frontend/package.json` → frontend present
     - `/infra/main.tf` → infra present
     - `/ai-services/*/` (any subfolder) → AI service present
   - Read `/infra/providers.tf` (if present) to determine which cloud
     was scaffolded — this drives the OIDC config.
   - Use `context7` MCP (`/actions/setup-dotnet`, `/actions/setup-node`,
     `/hashicorp/setup-terraform`, `/google-github-actions/auth` or
     `/aws-actions/configure-aws-credentials`) to confirm current
     action versions.

2. **Generate workflows** — one per detected component, plus a shared
   reusable workflow for cloud auth if more than one component
   deploys.

   ### `backend.yml` (if backend present)
   - **On PR:** `dotnet restore`, `dotnet build`, `dotnet test`.
   - **On push to main:** above, plus build + push Docker image to
     registry (Artifact Registry / ECR via OIDC), then trigger deploy
     via Terraform output or direct API call.
   - Use `actions/setup-dotnet@v4` pinned to .NET 10.

   ### `frontend.yml` (if frontend present)
   - **On PR:** `npm ci`, `npm run lint`, `npm run build`.
   - **On push to main:** above, plus `gsutil rsync` (GCP) or `aws s3
     sync` (AWS) to the static-site bucket from `infra/`.

   ### `infra.yml` (if infra present)
   - **On PR:** `terraform fmt -check`, `terraform init`, `terraform
     validate`, `terraform plan`. Post plan as PR comment.
   - **On push to main:** manual-approval gate (`environment:
     production`) before `terraform apply`. Never auto-apply.

   ### `ai-services.yml` (if AI service present)
   - **On PR:** language-appropriate lint + test (Python: `ruff` +
     `pytest`; C#: `dotnet test`).
   - **On push to main:** build + deploy container similarly to
     backend.

3. **Cloud auth setup:**
   - Add a step to each deploy workflow using the cloud's OIDC action:
     - GCP: `google-github-actions/auth@v2` with `workload_identity_provider` from `infra/` outputs.
     - AWS: `aws-actions/configure-aws-credentials@v4` with the role
       ARN from `infra/` outputs.
   - Document required GitHub repo variables (e.g. `GCP_PROJECT_ID`,
     `WIF_PROVIDER`, `AWS_ROLE_ARN`) in `.github/workflows/README.md`.

4. **Path filters** — every workflow has `paths:` filters so the
   backend workflow doesn't run on frontend-only changes, etc.

5. **Sanity check:**
   - Push the branch and verify workflows are detected and runnable
     (will fail on first run without OIDC variables set — that's
     expected; the user populates those after `terraform apply`).
   - Use `gh workflow list` to confirm GitHub recognizes them.

6. **Commit** with a message like `ci: scaffold GitHub Actions
   workflows for <detected components>`.

## Verification

- `gh workflow list` shows one workflow per detected component.
- Open a PR with a no-op change and confirm only the relevant
  workflows trigger (path filters working).
- Each workflow's YAML passes `actionlint` if installed.
