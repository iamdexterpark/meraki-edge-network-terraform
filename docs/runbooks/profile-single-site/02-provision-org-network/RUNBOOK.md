# Runbook 02 — Provision Org & Network (single-site)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `profile-single-site` — one org, one network, one edge site |
> | **Substrate** | workstation/CI with the engine + remote state bound (runbook 01) |
> | **Cloud services used** | Meraki Dashboard API + remote state backend |
> | **Identity model** | Meraki API key (runbook 03) — read/write to the target org |
> | **What changes under a different profile** | multi-site repeats this per network with a per-site `config_path` ([profile-multi-site](../../profile-multi-site/README.md)) |

**Goal:** the organization is referenced (or created), the network container exists, and devices are
claimed into it — the substrate every feature module binds to.
**Time:** ~10 min · **Risk:** med (claims hardware → budget event) · **Reversible:** yes (destroy + release)

## Prerequisites

- Backend bootstrapped (runbook 01). API key + PSKs exported (runbook 03).
- The target org's ID, and the serials of the MX/MS/MR to claim.
- **License headroom confirmed** — claiming devices can re-price the org's license pool.

## Steps

### 1. Point config at your org and devices
```bash
cp -r terraform/config.example terraform/config       # config/ is gitignored
$EDITOR terraform/config/org/organization.json         # organization_id: REPLACE_ORG_ID -> real id
                                                        # manage:false references an existing org
$EDITOR terraform/config/network/network.json          # name, product_types, time_zone
$EDITOR terraform/config/devices/devices.json          # serials: [...] + per-device names/tags
```

### 2. Plan just the substrate, then apply
```bash
cd terraform
tofu plan  -target=module.org -target=module.network -target=module.devices -out=base.tfplan
tofu apply base.tfplan
```

## Verification

```bash
cd terraform
tofu output organization_id     # the org you targeted
tofu output network_id          # a new (or referenced) network id
tofu state list | grep -E 'module.(org|network|devices)'
# Dashboard: the network exists; the devices appear claimed in Inventory.
```

## Rollback

```bash
cd terraform && tofu destroy \
  -target=module.devices -target=module.network -target=module.org
# Then release the devices from the org Inventory (Dashboard) so serials are reusable.
```

## Notes / Gotchas

- `org/organization.json` `manage:false` **references** an existing org (the common case); `true`
  has Terraform own/create it ([modules/org](../../../../terraform/modules/org/main.tf)).
- **Device claim ordering matters** — claim must succeed before any switch port (keyed on serial)
  can be configured ([LLD §4 schema notes](../../../LLD.md#4-configuration--concrete)).
- Targeted apply here is a convenience for a clean first bring-up; the full apply (runbook 04) does
  not need `-target`.
