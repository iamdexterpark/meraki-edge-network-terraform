# Runbook 06 — Drift Detection (scheduled plan)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `profile-single-site` (multi-site schedules one plan per site) |
> | **Substrate** | CI runner / scheduler with the engine + remote state bound |
> | **Cloud services used** | Meraki Dashboard API (read) + remote state backend (read) |
> | **Identity model** | Meraki API key — **read is sufficient for plan** |
> | **What changes under a different profile** | multi-site fans out a plan per site, serialized |

**Goal:** detect when the live network has diverged from declared intent (an out-of-band Dashboard
edit, a manual fix during an incident) and alert — **without** auto-applying.
**Time:** ~5 min to wire · **Risk:** low (read-only) · **Reversible:** n/a

## Prerequisites

- A converged baseline (runbook 04). API key available to the scheduler (runbook 03).

## Steps

### 1. Run a detect-only plan
```bash
cd terraform && tofu plan -detailed-exitcode -lock=false
# exit 0 = no drift · exit 2 = drift detected · exit 1 = error
```

### 2. Schedule it (cron) — plan only, NEVER apply
```cron
# Daily drift check; alert on exit code 2. Apply stays gated behind a human.
17 8 * * *  cd /path/terraform && tofu plan -detailed-exitcode -lock=false || \
            { [ $? -eq 2 ] && notify "Meraki edge DRIFT detected — review before reconciling"; }
```

### 3. On drift: review, then reconcile or import deliberately
```bash
cd terraform && tofu plan          # read what diverged
# If the live change is unwanted: re-apply to reconcile (runbook 05).
# If the live change should be kept: bring it into intent, then import:
$EDITOR terraform/config/...       # encode the change as JSON
cd terraform && tofu import <addr> <id>   # adopt the live resource, then plan clean
```

## Verification

```bash
cd terraform && tofu plan -detailed-exitcode ; echo "exit=$?"   # 0 after reconcile
```

## Rollback

n/a — detection is read-only. The *response* (reconcile/import) is covered by runbook 05.

## Notes / Gotchas

- **Schedule `plan`, never `apply`.** A scheduled apply can reconcile away an emergency hand-edit
  made during an incident ([HLD R6](../../../HLD.md#12-risks--open-questions); the network analogue of
  the [heartbeat cost trap](../../../COST-MODEL.md#3-️-runtime--operational-cost-traps-read-before-deploying)).
- Use `-lock=false` for a read-only plan so a drift check never blocks a real change holding the lock.
- Frequent plans against a busy org consume API quota — keep the cadence sane (daily/hourly, not
  per-minute) to avoid `429`s.
