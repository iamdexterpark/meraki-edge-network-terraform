# ADR-0009 — Brownfield adoption via import, not greenfield rebuild

**Status:** Accepted
**Date:** 2026-06-29
**Deciders:** Network/Platform Engineering
**Related:** [ADR-0001](0001-declarative-over-imperative.md), [LLD §11 Field-Tested Quirks](../LLD.md#11-field-tested-quirks-provider-behavior-proven-on-a-live-network), [Runbook 08](../runbooks/profile-single-site/08-brownfield-import/RUNBOOK.md)

---

## Context and Problem Statement

The dominant real-world scenario is **not** a greenfield site. Almost every operator already has a
Meraki network that was clicked together in the Dashboard over months or years. To bring that under
declarative management there are two paths: tear it down and rebuild from config (a flag day and an
outage), or **adopt** the live objects into state and prove the config matches. **How should this repo
onboard an existing, running network?**

This was validated on a live multi-VLAN edge: the greenfield-shaped "copy config.example, apply"
story does not survive contact with a network that already exists and is carrying traffic.

## Decision Drivers

- **D1 — No outage:** adoption must not disrupt clients on the live network.
- **D2 — Proof of fidelity:** we need objective evidence the JSON config describes reality, not a hope.
- **D3 — Refactor safety:** later renames/restructures must not become destroy+create on live infra.
- **D4 — CI-compatible:** the import stage must fit a pipeline whose gates key on exit codes.

## Considered Options

### Option A — Greenfield rebuild (destroy live, re-apply from config)
- ➕ Simplest mental model; config is unquestionably the source.
- ➖ Outage (violates D1); risky on a production edge; throws away a working network to prove a point.
- **Verdict: rejected — unacceptable on any live site.**

### Option B — `import{}` / `moved{}` blocks (Terraform 1.5+ / OpenTofu)  ✅
- ➕ Binds live objects to state with **zero network mutation** (D1); a clean re-plan (`No changes`) is
  objective proof of fidelity (D2); `moved{}` turns later renames into pure state moves (D3);
  declarative and idempotent so a second apply is a no-op.
- ➖ Import ids are per-resource-type and fiddly; a plan containing import blocks exits non-zero (2),
  which CI must be taught to treat as success (D4, handled).
- **Verdict: chosen.**

### Option C — `terraform import` CLI (one command per resource, imperative)
- ➕ Works on older engine versions.
- ➖ Imperative, not reviewable, not in the repo as an artifact; easy to do partially and forget.
- **Verdict: rejected in favor of declarative `import{}` blocks; CLI kept only as a fallback for
  pre-1.5 engines.**

## Decision

Ship a committed `import.example.tf` (copy to `import.tf`) with declarative `import{}` and `moved{}`
blocks, and a dedicated [brownfield runbook](../runbooks/profile-single-site/08-brownfield-import/RUNBOOK.md).
The adoption contract is: **mirror the live config into JSON → import → re-plan to `No changes`.** Adopt
first, refactor second.

## Consequences

**Positive**
- The repo answers the question most operators actually have ("I have a network already — now what?")
  without a flag day, and proves the adoption with a clean re-plan.
- Surfaces and documents the field quirks that make adoption fail silently (NQ-2 null defaults, NQ-3
  disabled-port `allowedVlans`, NQ-4 import exit-2) — see [LLD §11](../LLD.md#11-field-tested-quirks-provider-behavior-proven-on-a-live-network).

**Negative / Risks accepted**
- Operators must read live resource ids to fill the import blocks (irreducible — it's their network).
- Import mutates state; a botched import is recoverable (state-only, the network is untouched) but
  requires care — the runbook gates on a `0 to add / 0 to change / 0 to destroy` import only.

## Revisit If

- The engine ships a bulk/auto-discovery import for this provider that removes the per-resource block
  authoring, or the provider changes the import-id formats.
