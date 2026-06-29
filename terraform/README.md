# Terraform Deliverable — Meraki Edge Network

The real, runnable artifact. This is declarative end-state for a complete Cisco Meraki
edge network (MX appliance · MS switching · MR wireless), driven by JSON that mirrors the
Meraki Dashboard API. The design rationale lives in [`../docs/HLD.md`](../docs/HLD.md) and
[`../docs/LLD.md`](../docs/LLD.md); this README is the operator-facing map of the tree.

> Compatible with **OpenTofu** and **Terraform** ≥ 1.5. Examples use `tofu`; substitute
> `terraform` verbatim.

## Layout

```
terraform/
├── main.tf            # root composition — wires every module in Dashboard-hierarchy order
├── variables.tf       # minimal: api_key (sensitive) + config_path + ssid_psks (sensitive)
├── outputs.tf         # surfaces key IDs/counts from each module
├── versions.tf        # provider + version pins (CiscoDevNet/meraki >= 1.0.0)
├── config.example/    # committed, safe-to-share JSON (RFC 5737 docs addresses, REPLACE_* ids)
│   ├── org/ network/ devices/
│   ├── mx/  # settings vlans firewall vpn routing ports traffic_shaping
│   ├── ms/  # settings ports qos routing stp acl
│   └── mr/  # settings ssids rf_profiles
└── modules/           # 19 single-concern modules, one per Dashboard section (never edited to add settings)
```

## The pattern in one breath

Each module accepts a `config` variable of type `any`, decoded from a JSON file with
`jsondecode(file(...))`. JSON keys are **camelCase** to match the Dashboard API verbatim, so
payloads copy straight from the [API docs](https://developer.cisco.com/meraki/api-latest/). Every
optional field is wrapped in `try()`, so a missing file or absent key is a clean no-op — you add
settings by editing JSON, never by editing HCL.

## Quick start

```bash
export MERAKI_DASHBOARD_API_KEY="REPLACE_API_KEY"            # provider reads this directly
export TF_VAR_ssid_psks='{"edge-trusted":"REPLACE","edge-iot":"REPLACE","edge-guest":"REPLACE"}'

cp -r config.example config           # config/ is gitignored — your live values live here
$EDITOR config/org/organization.json  # set organization_id (REPLACE_ORG_ID)

tofu init
tofu validate
tofu plan
tofu apply
```

## Validate without a live org

```bash
tofu fmt -check -recursive
tofu init -backend=false
tofu validate
```

`../scripts/validate.sh` runs exactly this (fmt-check + validate) plus the doc-sync and
secret-scan gates. See [`../docs/runbooks/`](../docs/runbooks/README.md) for the full lifecycle.

## Secrets

Nothing sensitive is committed. The API key arrives via `MERAKI_DASHBOARD_API_KEY`; SSID PSKs via
`TF_VAR_ssid_psks` (a name→PSK map the `mr/ssids` module looks up by SSID name); state belongs in
an encrypted remote backend. `config/`, `*.tfstate`, `*.tfvars`, and `.terraform/` are gitignored.
