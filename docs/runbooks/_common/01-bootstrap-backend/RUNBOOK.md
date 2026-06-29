# Runbook 01 — Bootstrap the State Backend

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `_common` — profile-independent (same for single-site or multi-site) |
> | **Substrate** | a workstation/CI runner with OpenTofu/Terraform ≥ 1.5 + provider access |
> | **Cloud services used** | one encrypted object-store bucket for remote state (GCS / S3 / TF Cloud) |
> | **Identity model** | write credential to the state bucket only (not the Meraki API key) |
> | **What changes under a different profile** | nothing structural — multi-site uses the *same* backend with a per-site `prefix`/workspace ([profile-multi-site](../../profile-multi-site/README.md)) |

**Goal:** an encrypted, versioned remote state backend exists and `tofu init` binds to it, so state
is recoverable and never lives only on a laptop.
**Time:** ~10 min · **Risk:** low · **Reversible:** yes (delete the bucket once destroyed)

## Prerequisites

- OpenTofu ≥ 1.5 (`tofu version`) or Terraform ≥ 1.5.
- A cloud account that can create an object-store bucket with versioning + encryption.
- The repo cloned; you are in its root.

## Steps

### 1. Create a versioned, encrypted bucket (example: GCS)
```bash
# Versioning is what makes state recoverable; encryption is non-negotiable for state.
gsutil mb -l REPLACE_REGION gs://REPLACE_STATE_BUCKET
gsutil versioning set on gs://REPLACE_STATE_BUCKET
```

### 2. Declare the backend in the deliverable
```hcl
# terraform/backend.tf  (gitignore-safe: contains no secret, only the bucket name placeholder)
terraform {
  backend "gcs" {
    bucket = "REPLACE_STATE_BUCKET"
    prefix = "meraki/single-site"   # multi-site: one prefix per site
  }
}
```

### 3. Initialize against the backend
```bash
cd terraform && tofu init
```

## Verification

State is remote, not local.

```bash
cd terraform && tofu state list           # talks to the remote backend, no error
gsutil ls gs://REPLACE_STATE_BUCKET/**     # a state object appears after first apply
test ! -f terraform/terraform.tfstate && echo "OK: no local state file"
```

## Rollback

```bash
# Remove the backend block and re-init to local state (dev only), or delete the bucket
# AFTER a successful destroy (runbook 07). Never delete a bucket holding live state.
( cd terraform && rm -f backend.tf && tofu init -migrate-state )
```

## Notes / Gotchas

- **State is recovery truth** — treat the bucket as production from day 0 (versioning + encryption +
  restricted IAM). See [LLD §7](../../../LLD.md#7-state--restore--concrete-commands).
- The state-bucket credential is **separate** from the Meraki API key (runbook 03) — least privilege.
- For a portfolio/lab run you may skip the remote backend and use `-backend=false` for `validate`
  only; never run a real `apply` on local-only state.
