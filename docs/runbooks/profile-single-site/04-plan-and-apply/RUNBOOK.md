# Runbook 04 — Plan & Apply the Full Edge (single-site)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `profile-single-site` — the complete MX/MS/MR config for one site |
> | **Substrate** | workstation/CI with the engine + remote state bound (runbook 01) |
> | **Cloud services used** | Meraki Dashboard API + remote state backend |
> | **Identity model** | Meraki API key + SSID PSK map (runbook 03) |
> | **What changes under a different profile** | multi-site runs this once per site with a distinct `config_path`, serialized |

**Goal:** the entire edge network — VLANs, firewall, switching, wireless — is applied and converged,
matching the declared intent.
**Time:** ~15 min · **Risk:** med · **Reversible:** yes (runbook 05 rollback / runbook 07 destroy)

## Prerequisites

- Runbooks 01–03 done: backend bound, org/network/devices provisioned, secrets exported.
- Feature JSON edited for your site (`config/mx/*`, `config/ms/*`, `config/mr/*`).

## Steps

### 1. Format + validate (no API key needed)
```bash
cd terraform
tofu fmt -check -recursive
tofu validate
```

### 2. Plan the full config and review the diff
```bash
cd terraform && tofu plan -out=full.tfplan
# Review: VLANs created after settings enable them; firewall list ends in the logged deny;
# switch ports keyed on the claimed serials; SSIDs map to the right zones.
```

### 3. Apply
```bash
cd terraform && tofu apply full.tfplan
```

## Verification

```bash
cd terraform
tofu plan -detailed-exitcode        # exit 0 = fully converged, no drift
tofu output mx_vlan_ids             # [10 20 30 40]
tofu output mx_l3_firewall_rules_count
tofu output mr_ssid_names           # the configured SSIDs
# Functional smoke: a client on VLAN 20 reaches the internet; IoT(30) cannot reach trusted(20);
# guest(40) cannot reach RFC-1918; wireless clients authenticate (PSK resolved).
```

## Rollback

```bash
# Whole-site: revert intent and re-apply (runbook 05), or:
cd terraform && tofu destroy        # tears the site down (runbook 07 for clean decommission)
```

## Notes / Gotchas

- **Apply is serialized per org** — do not run a second apply against the same org concurrently
  (rate-limit storm, [HLD R4](../../../HLD.md#12-risks--open-questions)).
- The firewall is **one ordered resource**, not per-rule — the terminal logged `deny any/any` must be
  the last list element ([LLD §6](../../../LLD.md#6-networking--concrete)).
- A missing feature JSON file is a **clean no-op** (the `try()` defaults), so partial config is fine.
- If `apply` errors mid-run, re-running is safe — the engine is idempotent and resumes the diff.
