# Architecture Decision Records

These ADRs capture the **load-bearing decisions** behind this repo. The point of an ADR is not to
document the chosen answer — the deliverable already does that — but to record the **alternatives
that were genuinely on the table** and *why they lost*, so the design can be audited and revisited as
conditions change.

Format: lightly-adapted [MADR](https://adr.github.io/madr/). Each record is self-contained:
context → decision drivers → options considered → decision → consequences → revisit-if. Start from
[`0000-template.md`](0000-template.md).

| ADR | Status | Decision | Rejected alternatives |
|---|---|---|---|
| [0001](0001-declarative-over-imperative.md) | Accepted | Declarative end-state over imperative scripting | manual Dashboard; imperative SDK/playbooks |
| [0002](0002-json-driven-config-pattern.md) | Accepted | JSON-driven, Dashboard-shaped config over typed HCL variables | typed HCL vars; values-in-HCL per resource |
| [0003](0003-trust-zone-vlan-segmentation.md) | Accepted | Trust-zone VLAN segmentation as the core security control | flat L2 + host controls; per-host microsegmentation |
| [0004](0004-default-deny-firewall.md) | Accepted | Explicit, logged default-deny firewall | default-allow + blocklist; implicit platform default-deny |
| [0005](0005-secrets-out-of-repo.md) | Accepted | Secrets materialized at runtime, never in the repo | encrypted-in-git (SOPS); plaintext `.tfvars` |
| [0006](0006-dependency-ordering.md) | Accepted | Explicit `depends_on` matching the platform hierarchy | implicit reference ordering; synthetic "ready" outputs |
| [0007](0007-opentofu-vs-terraform.md) | Accepted | OpenTofu/Terraform-compatible engine, operator's choice | Terraform-only (BSL); OpenTofu-only |
| [0008](0008-deployment-profile-single-site.md) | Accepted | Single edge site as the primary deployment profile | multi-site shared state; multi-site isolated state |
| [0009](0009-brownfield-import-workflow.md) | Accepted | Adopt an existing network via `import{}`/`moved{}`, not greenfield rebuild | destroy+rebuild (outage); imperative `terraform import` CLI |

> All identifiers, providers, and addresses referenced in these records are placeholders, consistent
> with the rest of this sanitized repo.
