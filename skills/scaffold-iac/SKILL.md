---
name: scaffold-iac
description: Scaffold Terraform infrastructure under /infra for GCP or AWS — grills for provider, then generates remote state backend and modules for container hosting, static site, secrets, and CI IAM. Use when the user says "add infrastructure", "scaffold Terraform", "set up the cloud", "init IaC", or invokes `/scaffold-iac`.
---

This skill scaffolds Terraform under `/infra`. Assumes the monorepo
skeleton already exists.

**Cloud-agnostic at invocation time, not runtime.** This skill grills the
user once on GCP vs AWS, then generates **provider-specific** Terraform.
The user picks once per project; the generated code is not portable.

Default to the smallest viable footprint — managed container hosting,
managed static-site, no Kubernetes unless the user explicitly asks.

## Process

1. **Preflight:**
   - Verify `/infra` exists and is empty.
   - Verify `terraform --version` is installed and ≥ 1.9.
   - Use `context7` MCP (`/hashicorp/terraform`, `/hashicorp/terraform-provider-google` or `/hashicorp/terraform-provider-aws`) to confirm current provider versions and module idioms.

2. **Grill the user — exactly 3 questions, no more:**
   - **Provider:** GCP or AWS?
   - **Region:** primary region (e.g. `europe-west1`, `us-east-1`).
   - **Project / Account:** GCP project ID, or AWS account ID + profile
     name from `~/.aws/credentials`.

   Use the `quick-grill` style: single batch, recommend a default for
   each.

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
       ci-iam/            # service account + WIF (GCP) or OIDC IAM role (AWS) for GitHub Actions
   ```

   Each module gets its own `main.tf`, `variables.tf`, `outputs.tf`,
   and a `README.md` explaining inputs/outputs.

4. **Remote state backend:**
   - **GCP:** GCS bucket with versioning + uniform bucket-level access.
     Create the bucket out-of-band (Terraform can't manage the bucket
     it stores its own state in) — generate a one-time `bootstrap.sh`
     that uses `gcloud` to create it.
   - **AWS:** S3 bucket (versioned, encrypted) + DynamoDB lock table.
     Same approach: `bootstrap.sh` using `aws` CLI.

5. **CI IAM:**
   - **GCP:** Workload Identity Federation pool + provider for GitHub
     Actions OIDC, service account with least-privilege roles for
     deploy.
   - **AWS:** IAM OIDC provider for GitHub Actions + role with trust
     policy scoped to the repo.

   No long-lived credentials.

6. **Add `infra/README.md`** explaining: how to run `bootstrap.sh`
   first, then `terraform init && terraform plan && terraform apply`.

7. **Sanity check:**
   - `cd infra && terraform init -backend=false` → succeeds.
   - `terraform validate` → no errors.
   - `terraform fmt -check` → clean.

8. **Commit on the current feature branch** with a message like
   `feat(infra): scaffold Terraform for <provider> (Cloud Run + GCS
   static site)`. Do not run `terraform apply` or push — that's the
   user's call.

## Verification

- `terraform validate` passes for the root module and every
  sub-module.
- `terraform plan` (after the user runs `bootstrap.sh` and supplies
  variable values) shows the expected resources and no errors.
- Generated Terraform follows current provider documentation fetched
  via `context7`.
