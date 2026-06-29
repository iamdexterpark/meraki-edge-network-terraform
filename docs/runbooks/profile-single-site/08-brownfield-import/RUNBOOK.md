# Runbook 08 — Adopt an Existing Network (brownfield import)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `profile-single-site` — adopting a network that already exists in the Dashboard |
> | **Substrate** | workstation/CI with the engine + remote state bound (runbook 01) |
> | **Cloud services used** | Meraki Dashboard API + remote state backend |
> | **Identity model** | Meraki API key + SSID PSK map (runbook 03) |
> | **What changes under a different profile** | multi-site repeats this per site, each into its own state |

**Goal:** bring a live, hand-built Meraki network under declarative management **without a flag day** —
no destroy, no re-provision, no client-facing outage. End state: `tofu plan` reports
`No changes. Your infrastructure matches the configuration.`
**Time:** ~30–60 min (depends on object count) · **Risk:** low (import mutates state, not the network) · **Reversible:** yes (state-only)

> This is the single most useful thing this repo does. Almost everyone already has a network; very few
> have a clean greenfield. Field-proven on a live multi-VLAN edge: empty state →
> `N imported, 0 added, 0 changed, 0 destroyed` → clean re-plan.

## Why import (not rebuild)

A `tofu destroy`/re-apply against a live site is an outage and a risk. **Import** binds existing
Dashboard objects to Terraform state, so the engine *adopts* what is already running. Once state and a
matching JSON config agree, you own the network declaratively from that moment on — drift detection,
peer-reviewed change, rebuild-as-apply — with zero disruption to get there.

## Prerequisites

- Runbooks 01–03 done: backend bound, secrets exported, API key valid.
- Read access to the live Dashboard (to read the current config and the resource IDs).

## Steps

### 1. Mirror the live config into JSON — adopt first, refactor second
Read the live network from the Dashboard and write `config/` JSON to **match what exists today**.
Resist the urge to "fix" anything yet; a faithful mirror is what makes the import a no-op. Improve
*after* the clean re-plan.

### 2. Author the import blocks
```bash
cd terraform
cp import.example.tf import.tf
# Fill one import{} block per live resource: org, network, each VLAN, each enabled
# switch port, each configured SSID. IDs come from the Dashboard / API.
```
Disabled switch ports: do not import `allowedVlans` (the API omits it on disabled ports — see the
disabled-port guard in `modules/ms/ports/main.tf`).

### 3. Plan the import — expect changes, expect exit code 2
```bash
cd terraform && tofu plan -out=import.tfplan
# Expect: "N to import, 0 to add, 0 to change, 0 to destroy".
```
> **Exit code 2 is SUCCESS here.** A plan that contains `import{}` blocks returns
> `-detailed-exitcode` **2** ("changes present") by design — it is *not* an error. CI must treat exit 2
> as success for the import stage; only exit 1 is a failure. (Field quirk NQ-4.)

If the plan shows any `to add / to change / to destroy`, your JSON does not yet match live — fix the
config, do **not** apply. A `0 to add / 0 to change / 0 to destroy` import is the only safe one.

### 4. Apply the import
```bash
cd terraform && tofu apply import.tfplan
# Expect: "Apply complete! ... 0 added, 0 changed, 0 destroyed, N imported."
```

### 5. Re-plan to prove faithful adoption
```bash
cd terraform && tofu plan -detailed-exitcode
# Goal: exit 0 — "No changes. Your infrastructure matches the configuration."
```

## Verification

```bash
cd terraform
tofu plan -detailed-exitcode     # exit 0 == state + config + live network all agree
tofu state list | wc -l          # matches the number of objects you imported
```

## Refactor-safe renames (after adoption)

Renaming a JSON key or a `for_each` key naively shows **destroy + create** — an outage on live infra.
Use a `moved{}` block (see `import.example.tf`) to make it a pure state move (`0 destroyed`).

## Notes / Gotchas

- **`1 to change` on the clean re-plan** = an `optional()`/literal default is force-writing an attribute
  the live object legitimately omits (NQ-2). Default omittable attributes to **null** so the provider
  leaves them unset, then re-plan.
- **`SUCCESS ≠ no-op`** (NQ-1): a green apply does not prove zero drift. Always assert the
  `0 to change` / `No changes` line explicitly; don't trust the exit banner alone.
- **Import mutates state only** — if step 3/4 looks wrong, you can discard state changes and retry; the
  live network is never touched by an import.
- See [`docs/LLD.md` §Field-tested quirks](../../../LLD.md) for the full known-quirks list.
