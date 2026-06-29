# Runbook 07 — Decommission (retire cleanly, no orphans)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `_common` — profile-independent (teardown is the same shape everywhere) |
> | **Substrate** | workstation/CI with the engine + remote state bound |
> | **Cloud services used** | Meraki Dashboard API + remote state backend |
> | **Identity model** | Meraki API key + state-bucket credential |
> | **What changes under a different profile** | multi-site destroys per site, then removes each site's state prefix/workspace |

**Goal:** the network config is torn down, devices are released, and **nothing is left billing** —
no orphaned state bucket, no still-claimed device, no dangling license.
**Time:** ~15 min · **Risk:** high (destructive) · **Reversible:** no (re-derive from git if needed)

## Prerequisites

- Confirmed intent to retire the site. A final config snapshot is committed (it *is* the archive).
- You know which devices were claimed (the `devices` module / `tofu state list`).

## Steps

### 1. Archive the final state of intent
```bash
git tag decommission/$(date +%F) && git push --tags   # the repo at this tag re-derives the site
```

### 2. Destroy the managed config
```bash
cd terraform && tofu plan -destroy -out=destroy.tfplan   # review what leaves
cd terraform && tofu apply destroy.tfplan
```

### 3. Release devices + reconcile licensing (out of band)
```bash
# `destroy` removes config; releasing claimed hardware from the org and reclaiming/parking
# licenses is a Dashboard/admin action — do it so the devices/licenses are reusable.
echo "Dashboard → Organization → Inventory → release devices; review License info."
```

### 4. Remove state and its bucket (only after destroy is verified)
```bash
gsutil rm -r gs://REPLACE_STATE_BUCKET/meraki/single-site
# If the bucket exists solely for this deployment, delete it to stop storage billing:
gsutil rb gs://REPLACE_STATE_BUCKET
```

## Verification — no orphans

```bash
cd terraform && tofu state list                 # empty
gsutil ls gs://REPLACE_STATE_BUCKET 2>&1 | grep -q 'BucketNotFound' && echo "OK: state bucket gone"
# Dashboard: Inventory shows the devices released; License info shows no surprise charge.
```

## Rollback

Not reversible — but the repo at the `decommission/<date>` tag fully re-derives the network: bootstrap
backend (runbook 01) → apply (runbook 04).

## Notes / Gotchas

- **The orphan checklist is the point:** managed config (destroyed), claimed devices (released),
  licenses (parked/reviewed), state object (deleted), state bucket (deleted if dedicated). Skipping
  any one leaves a bill or a phantom resource ([COST-MODEL §3](../../../COST-MODEL.md#3-️-runtime--operational-cost-traps-read-before-deploying)).
- `tofu destroy` against an org you don't fully own can hit resources outside this state — confirm
  scope before applying.
