# Runbook {{NN}} — {{Title}}

> **Target Environment** (mandatory — a runbook that doesn't declare its env is a trap)
> | | |
> |---|---|
> | **Deployment profile** | {{`_common` (profile-independent) \| `profile-single-site` \| `profile-multi-site`}} |
> | **Substrate** | {{e.g. workstation/CI with OpenTofu/Terraform >= 1.5}} |
> | **Cloud services used** | {{e.g. Meraki Dashboard API + encrypted remote state backend (GCS/S3/TF Cloud) \| none}} |
> | **Identity model** | {{e.g. Meraki Dashboard API key + state-bucket credential}} |
> | **What changes under a different profile** | {{the 1–2 steps that differ, + pointer to that profile's runbook}} |

**Goal:** one sentence — what state this runbook leaves you in.
**Time:** ~{{N}} min · **Risk:** low/med/high · **Reversible:** yes/no (see Rollback)

## Prerequisites

- …

## Steps

### 1. {{step}}
```bash
# copy-pasteable, sanitized; placeholders explicit (REPLACE_*)
```

## Verification

How you *know* it worked — the explicit check, expected output, success criterion.

```bash
```

## Rollback

How to undo, cleanly.

```bash
```

## Notes / Gotchas

- …
