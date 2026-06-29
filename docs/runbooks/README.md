# Runbooks

The operational path across the full lifecycle. **Every runbook declares its Target Environment** in
a header block — because the procedure changes with the deployment target.

## The deployment-profile model

This repo is written against a **primary deployment profile** concretely, with room to add others
without rewriting the core. Runbooks are split so each profile is independently followable:

```
runbooks/
├── _common/                    # profile-INDEPENDENT steps (same regardless of target)
│   ├── 01-bootstrap-backend
│   ├── 05-update-and-rollback
│   └── 07-decommission
├── profile-single-site/        # PRIMARY profile: one org, one network, one edge site
│   ├── 02-provision-org-network
│   ├── 03-secrets
│   ├── 04-plan-and-apply
│   ├── 06-drift-detection
│   ├── 08-brownfield-import   # adopt an EXISTING network (no flag day)
│   └── 09-troubleshooting
└── profile-multi-site/         # EXTENSION pattern: fan out per site (add when needed)
    └── README.md
```

- **`_common/`** holds steps identical across targets (bootstrap encrypted remote state, the
  change/rollback loop, clean decommission). Don't duplicate these into profiles.
- **`profile-*`** holds the target-specific path: provisioning the org/network, wiring secrets,
  applying the full config, drift detection. The numbered sequence interleaves `_common` and profile
  steps — follow them in numeric order across both folders.
- **Adding a target** (you grow from one site to many): copy
  [`profile-multi-site/`](profile-multi-site/README.md) as a starting point, set `config_path` and
  state scoping per site, reuse `_common/` and every module unchanged. The
  [ADRs](../adr/README.md) and [LLD Environment Profiles](../LLD.md#environment-profiles) define what
  a new profile must specify.

> Everything is sanitized: `REPLACE_*` identifiers, RFC 5737 documentation addresses. Adapt before
> running.

## Order of operations (primary profile: single-site)

| # | Runbook | Folder | What it does |
|---|---|---|---|
| 01 | bootstrap-backend | `_common` | Create encrypted, versioned remote state; `tofu init` binds to it. |
| 02 | provision-org-network | `profile-single-site` | Reference/create the org, create the network, claim devices. |
| 03 | secrets | `profile-single-site` | Export API key + SSID PSK map at runtime; verify nothing in repo. |
| 04 | plan-and-apply | `profile-single-site` | `fmt`/`validate`/`plan`/`apply` the full MX/MS/MR config. |
| 05 | update-and-rollback | `_common` | Edit JSON → review the diff → apply; revert + apply to roll back. |
| 06 | drift-detection | `profile-single-site` | Scheduled `plan` (not apply); alert + reconcile/import on drift. |
| 07 | decommission | `_common` | Destroy config, release devices, delete state — **no orphans**. |
| 08 | brownfield-import | `profile-single-site` | **Adopt an existing Dashboard network** via `import{}`/`moved{}` → clean re-plan, no outage. |
| 09 | troubleshooting | `profile-single-site` | Break-fix for this deliverable's failure modes. |

## Operating principles

- **Declarative over imperative.** A `plan`+`apply` changes running state — no out-of-band Dashboard
  edits ([ADR-0001](../adr/0001-declarative-over-imperative.md)).
- **Review the diff.** The `tofu plan` output *is* the change review.
- **Pin the provider; serialize applies per org.** A moving pin or a parallel apply is a future
  outage / a rate-limit storm.
- **Schedule `plan`, gate `apply`.** Detection is automatic; reconciliation is human-decided.
- **Adopt before you refactor.** Bring a live network in with [runbook 08](profile-single-site/08-brownfield-import/RUNBOOK.md)
  to a clean `No changes` re-plan first; restructure only once state and reality agree.
- **A state backup nobody has restored is not a backup.** The restore drill ([LLD §7](../LLD.md#7-state--restore--concrete-commands))
  is not optional.
- **Watch the bill.** A device-claim apply is a budget event ([COST-MODEL](../COST-MODEL.md)).
