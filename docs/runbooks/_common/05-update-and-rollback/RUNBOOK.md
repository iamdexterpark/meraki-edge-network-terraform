# Runbook 05 — Update & Rollback (change management)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `_common` — profile-independent (the change loop is identical everywhere) |
> | **Substrate** | workstation/CI with the engine + remote state bound (runbook 01) |
> | **Cloud services used** | Meraki Dashboard API + the remote state backend |
> | **Identity model** | Meraki API key (runbook 03) |
> | **What changes under a different profile** | multi-site repeats this loop per site, serialized |

**Goal:** make a controlled, reviewed change to the edge config and have a proven path back.
**Time:** ~10–15 min · **Risk:** med (it changes live network state) · **Reversible:** yes (git revert + apply)

## Prerequisites

- Backend bootstrapped (runbook 01); secrets exported (runbook 03); a clean `tofu plan` baseline.
- A branch/PR for the change — **changes go through review, never an out-of-band Dashboard click**
  ([ADR-0001](../../../adr/0001-declarative-over-imperative.md)).

## Steps

### 1. Edit intent (JSON, not modules)
```bash
# Add a VLAN, a firewall rule, an SSID — by editing config, never module HCL.
$EDITOR terraform/config/mx/vlans.json
```

### 2. Plan and review the diff (this IS the change review)
```bash
cd terraform && tofu plan -out=change.tfplan
# Read every resource the plan will touch. The diff is the artifact reviewers approve.
```

### 3. Apply the reviewed plan
```bash
cd terraform && tofu apply change.tfplan
```

## Verification

```bash
cd terraform && tofu plan -detailed-exitcode   # exit 0 = converged, no further drift
# Spot-check the intended change reached the Dashboard (e.g. the new VLAN/SSID is present).
```

## Rollback

The declared end-state *is* the rollback artifact — revert it and re-apply.

```bash
git revert <bad-commit>            # restores the previous intent
cd terraform && tofu plan && tofu apply
# (For a not-yet-committed change: discard the edit and `tofu apply` to reconcile back.)
```

## Notes / Gotchas

- **Serialize applies per org** — never run two `apply`s against the same org concurrently (API
  rate-limit storm, [HLD R4](../../../HLD.md#12-risks--open-questions)).
- A **device-claim** change is a **budget event** — claiming hardware can re-price the org's license
  pool ([COST-MODEL §2](../../../COST-MODEL.md#3-️-runtime--operational-cost-traps-read-before-deploying)).
  Pre-stage license headroom first.
- Rollback restores *config*; it does not un-bill a license already consumed by a claim.
