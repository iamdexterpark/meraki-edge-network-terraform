# Runbook 09 — Troubleshooting (break-fix, single-site)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `profile-single-site` (failure modes generalize to multi-site per site) |
> | **Substrate** | workstation/CI with the engine + remote state bound |
> | **Cloud services used** | Meraki Dashboard API + remote state backend |
> | **Identity model** | Meraki API key + SSID PSK map |
> | **What changes under a different profile** | multi-site adds per-site state/lock as a failure axis |

**Goal:** diagnose and recover the common failure modes of this deliverable.
**Time:** varies · **Risk:** varies · **Reversible:** yes for all rows below

## Symptom → Cause → Fix

| Symptom | Likely cause | Fix |
|---|---|---|
| `apply` fails on `meraki_appliance_vlan` ("VLANs not enabled") | settings didn't run first | the `mx/settings → mx/vlans` `depends_on` prevents this; if hit, `tofu apply -target=module.mx_settings` then re-apply |
| `meraki_switch_port` not found for serial | device not claimed yet | ensure `module.devices` applied; check `tofu output` / Inventory; re-apply |
| Wireless clients can't authenticate | PSK `null` — SSID name ≠ key in `TF_VAR_ssid_psks` | match the map key to the SSID `name`; re-export (runbook 03); re-apply |
| `apply`/CI stalls, `429` in logs | API rate-limit storm (parallel/large apply) | serialize applies; back off; never run two applies per org |
| Unexpected diff on every plan | out-of-band Dashboard edit (drift) | review, then reconcile (re-apply) or `tofu import` the live change (runbook 06) |
| Claim apply fails / surprise license charge | license capacity / co-termination | pre-stage license headroom; review Dashboard License info |
| `plan` wants to recreate everything | state lost/empty | restore state from backend versioning; last resort re-derive from git (runbook 01→04) |
| State lock stuck | a prior apply crashed holding the lock | `tofu force-unlock <LOCK_ID>` (only after confirming no apply is actually running) |

## Diagnostics

```bash
cd terraform
tofu validate                       # HCL/schema sane?
tofu plan -detailed-exitcode        # 0 converged · 2 drift · 1 error
tofu state list                     # is state populated as expected?
TF_LOG=INFO tofu plan 2>&1 | grep -iE '429|rate|unauthor|forbidden'   # API-layer issues
```

## Verification (recovered)

```bash
cd terraform && tofu plan -detailed-exitcode ; echo "exit=$?"   # 0 = healthy, converged
```

## Rollback

Every fix above is itself reversible via runbook 05 (revert intent + apply). Destructive recovery is
runbook 07.

## Notes / Gotchas

- Most "broken apply" cases are **ordering** (claim/enable preconditions) or **secrets** (missing/mismatched
  env), not the modules — check those first.
- These rows mirror the [LLD failure-modes table](../../../LLD.md#10-failure-modes) and the
  [HLD risk register](../../../HLD.md#12-risks--open-questions); keep all three in sync.
