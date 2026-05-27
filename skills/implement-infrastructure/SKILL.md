---
name: implement-infrastructure
description: Implement infrastructure changes in an existing /infra Terraform setup — add resources, extend modules, wire new services to the cloud. Detects the provider already in use (GCP or AWS) and fetches current docs via context7. Triggers: "add infrastructure for X", "extend the Terraform", "add a cloud resource", "wire X to the cloud", or invocation as `/implement-infrastructure`.
---

This skill implements changes inside an **existing** Terraform setup
under `/infra`. It is the day-to-day counterpart to `scaffold-iac` —
that one bootstraps the folder; this one adds resources to it.

## When to use this skill

Invoke this skill **only**:

- When `/infra` already exists and has at least `versions.tf` +
  `providers.tf` (i.e. `scaffold-iac` has run, or a Terraform setup is
  in place).
- When the user wants to add, modify, or extend cloud resources via
  IaC.

Do **not** invoke this skill:

- For initial bootstrap — use `scaffold-iac` instead.
- For one-off manual changes in the cloud console — those are out of
  scope; IaC is the source of truth.
- To change providers (GCP ↔ AWS) — that's a migration, not an
  implementation change.

## Fetch current docs before doing anything

Use the **context7 MCP** at the start of every invocation:

- `/hashicorp/terraform` — for language features (`for_each`,
  `dynamic`, `moved` blocks, etc.).
- `/hashicorp/terraform-provider-google` **or**
  `/hashicorp/terraform-provider-aws` — read `/infra/versions.tf` to
  detect which one is pinned and pull its docs for the **specific
  resources** you're about to touch.

Provider arguments change between majors. Do not write a resource
block from memory — always check the current schema.

## Process

1. **Read the existing Terraform** under `/infra` to learn:
   - Which provider is in use (GCP / AWS) and what version is pinned.
   - The module structure — is the new resource a natural fit for an
     existing module, or does it deserve a new module?
   - Naming conventions, tagging/labelling conventions, variable
     naming style (snake_case is standard).
   - Whether remote state is configured and where.

2. **Decide where the change goes:**
   - **Inside an existing module** — if the new resource is part of an
     already-modelled concern (e.g. another bucket in
     `modules/static-site/`).
   - **New module** — if the resource is a new concern that will be
     reused (e.g. `modules/database/`).
   - **Top-level `main.tf`** — only for one-off composition; resist
     this for anything you'd reuse.

3. **Implement the change** following Terraform best practices:
   - Every value the user might change → `variable` with `type`,
     `description`, and a sensible `default` (or `nullable = false`
     when required).
   - Every value another module or CI might consume → `output`.
   - **Tag/label every resource** consistently (`environment`,
     `managed_by = "terraform"`, `component`, etc.).
   - **Least-privilege IAM** — never use predefined roles like
     `roles/owner` or `AdministratorAccess`. Use the smallest scope
     that works.
   - **No secrets in code** — pull from Secret Manager / Parameter
     Store via data sources; never hard-code keys.
   - **Lifecycle blocks** — add `prevent_destroy = true` for stateful
     resources (state buckets, databases, KMS keys).
   - **Use data sources** for resources you don't own (existing
     projects, network, etc.) — never recreate them.

4. **Format and validate:**

   ```bash
   cd infra
   terraform fmt
   terraform validate
   ```

   Both must pass clean before moving on.

5. **Plan and show the user:**

   ```bash
   terraform plan -out=tfplan
   ```

   Summarise the plan output in chat — number of resources to add /
   change / destroy, and flag anything destructive. Do **not** run
   `terraform apply` without explicit user approval; destructive plans
   need a second confirmation.

6. **Commit on the current feature branch** with a message describing
   the resource(s) added (e.g. `feat(infra): add Cloud SQL instance
   for backend`). Do not push or open a PR unless asked.

## Verification

- `terraform fmt -check` clean.
- `terraform validate` clean.
- `terraform plan` shows exactly the resources you intended, no
  unexpected changes elsewhere.
- After `terraform apply` (user-initiated), the new resource works
  end-to-end with the consuming code.
