---
name: scaffold-iac
description: Scaffold Terraform infrastructure under /infra for GCP or AWS — grills user for provider, then generates remote state backend and modules for container hosting, static site, secrets, and CI OIDC. Run once per project, on a fresh /infra folder. Triggers: "add infrastructure", "scaffold Terraform", "set up the cloud", "init IaC", or invocation as `/scaffold-iac`.
---

This skill scaffolds Terraform under `/infra`. Assumes the monorepo
skeleton already exists.

**Cloud-agnostic at invocation time, not runtime.** The skill grills the
user once on GCP vs AWS, then generates **provider-specific** Terraform.
The user picks once per project; the generated code is not portable.

Default to the smallest viable footprint — managed container hosting,
managed static-site, no Kubernetes unless asked.

## When to use this skill

Invoke this skill **only**:

- On a fresh `/infra` folder, when bootstrapping infrastructure for the
  first time on this project.
- When the user has not yet picked GCP vs AWS (the skill grills them) —
  or has picked one and wants a clean Terraform scaffold for it.

Do **not** invoke this skill:

- If `/infra` already has Terraform files — modify those by hand or
  with a more targeted skill.
- To change cloud providers on an existing project — that's a migration,
  not a scaffold.

## Fetch current docs and versions before running — HARD PRECONDITION

Per `home/CLAUDE.md` "Context7 is a hard precondition", do **not**
run `terraform init`, write a `versions.tf`, or scaffold any module
until you have logged context7 queries against:

- `/hashicorp/terraform` — confirm current Terraform major and module
  idioms.
- `/hashicorp/terraform-provider-google` **or**
  `/hashicorp/terraform-provider-aws` — confirm current provider major
  and resource argument shapes (these change often).
- `/google-github-actions/auth` or `/aws-actions/configure-aws-credentials` — for the CI OIDC step.

State the library IDs you're about to query before calling, so the
user sees the rule being followed. Do not pin a specific Terraform or
provider version in this skill. Use whatever context7 reports as
current.

## Process

1. **Preflight:**
   - Verify `/infra` exists and is empty.
   - Verify `terraform` is installed; check the version against the
     current stable from context7.

2. **Grill the user — exactly 3 questions** (use the `RefineScope` skill
   style: single batch with a recommended default for each):
   - **Provider:** GCP or AWS?
   - **Region:** primary region (e.g. `europe-west1`, `us-east-1`).
   - **Project / Account:** GCP project ID, or AWS account ID + profile
     name from `~/.aws/credentials`.

3. **Generate the Terraform layout:**

   ```
   infra/
     backend.tf           # remote state (GCS or S3 + DynamoDB)
     versions.tf          # required_providers, required_version
     providers.tf         # provider config, default tags/labels
     variables.tf
     outputs.tf
     main.tf              # wires up the modules below
     modules/
       container-host/    # Cloud Run (GCP) or ECS Fargate (AWS)
       static-site/       # Cloud Storage + CDN (GCP) or S3 + CloudFront (AWS)
       secrets/           # Secret Manager (GCP) or AWS Secrets Manager
       ci-iam/            # WIF for GitHub Actions (GCP) or OIDC IAM role (AWS)
   ```

   Each module gets its own `main.tf`, `variables.tf`, `outputs.tf`,
   and a `README.md` explaining inputs/outputs.

   **Container image source — GHCR.** The `container-host` module
   deploys an image, it doesn't build one. Per `home/CLAUDE.md`
   "Dockerization & build artifacts", images are built by CI and
   pushed to **GHCR** (`ghcr.io/<owner>/<repo>-<component>`). Expose
   the image reference as a module variable (`image` /
   `container_image`, default to the GHCR path with a `latest` or
   pinned-tag default) rather than hard-coding it. Registry-pull auth:
   - **GCP Cloud Run** can pull a *public* GHCR image with no extra
     auth; for a private image, store a GHCR PAT in Secret Manager and
     wire it as the service's pull credential.
   - **AWS ECS Fargate** needs `repositoryCredentials` pointing at a
     Secrets Manager secret holding the GHCR login when the image is
     private.
   Note this in the module README so the deploy step (in
   `scaffold-github-actions`) and the hosting line up.

4. **Remote state backend:**
   - **GCP:** GCS bucket with versioning + uniform bucket-level access.
     Generate a one-time `bootstrap.sh` using `gcloud` to create the
     bucket (Terraform can't manage the bucket it stores its own state
     in).
   - **AWS:** S3 bucket (versioned, encrypted) + DynamoDB lock table.
     `bootstrap.sh` using `aws` CLI.

5. **CI IAM (OIDC, no long-lived credentials):**
   - **GCP:** Workload Identity Federation pool + provider for GitHub
     Actions OIDC, service account with least-privilege deploy roles.
   - **AWS:** IAM OIDC provider for GitHub Actions + role with trust
     policy scoped to the repo.

6. **Add `infra/README.md`** — how to run `bootstrap.sh` first, then
   `terraform init && terraform plan && terraform apply`.

7. **Sanity check:**
   - `cd infra && terraform init -backend=false` succeeds.
   - `terraform validate` clean.
   - `terraform fmt -check` clean.

8. **Commit on the current feature branch** with a message like
   `feat(infra): scaffold Terraform for <provider> (managed container
   + static site)`. Do not run `terraform apply` or push — that's the
   user's call.

## Verification

- `terraform validate` passes for the root module and every sub-module.
- `terraform plan` (after the user runs `bootstrap.sh` and supplies
  variable values) shows expected resources with no errors.
- Generated Terraform matches the provider docs fetched via context7.
