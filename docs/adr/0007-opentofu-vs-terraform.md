# ADR-0007 — OpenTofu/Terraform-compatible engine, operator's choice

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering
**Related:** [HLD §10](../HLD.md#10-portability), [LLD §1](../LLD.md#1-component-inventory--versions), [ADR-0001](0001-declarative-over-imperative.md)

---

## Context and Problem Statement

[ADR-0001](0001-declarative-over-imperative.md) commits to a declarative reconciler. The HCL
ecosystem now has two near-identical engines: HashiCorp **Terraform** (BSL-licensed since 1.6) and
the Linux Foundation **OpenTofu** fork (MPL, open source). The CiscoDevNet/meraki provider works
with both. **Which engine does the repo target, and how hard do we bind to it?**

## Decision Drivers

- **D1 — License risk:** the engine must not impose licensing constraints on this repo's use.
- **D2 — Portability:** operators on either engine should run the repo unchanged.
- **D3 — Provider compatibility:** the chosen engine must run the official Meraki provider.
- **D4 — Longevity:** the engine should have a credible maintenance future.

## Considered Options

### Option A — Bind to Terraform only (BSL)
- ➕ The incumbent; widest tooling/docs.
- ➖ BSL introduces a license consideration for some org policies (tension with D1); excludes
  OpenTofu shops (D2).
- **Verdict: rejected as an exclusive target — needlessly narrows who can run it.**

### Option B — Bind to OpenTofu only (MPL)
- ➕ Fully open license (D1); active LF stewardship (D4).
- ➖ Excludes the large installed base still on Terraform (violates D2).
- **Verdict: rejected as an exclusive target — same narrowing in the other direction.**

### Option C — Target the common HCL surface; support both, examples in `tofu`, recommend OpenTofu  ✅
- ➕ Runs on either engine unchanged (D2); recommending the MPL engine sidesteps license concern
  (D1); the provider is engine-agnostic (D3); both engines are maintained (D4).
- ➖ Must avoid engine-exclusive features and pin a `required_version` both satisfy (`>= 1.5`).
- **Verdict: chosen — portability at near-zero cost.**

## Decision

Write against the common HCL surface both engines share, pin `required_version >= 1.5`, document
examples with `tofu` while stating `terraform` substitutes verbatim, and **recommend OpenTofu** as
the default for its open license. Avoid engine-exclusive syntax.

> Underlying platform note: the managed edge itself is **inert without an active vendor
> subscription** — an accepted SD-WAN trade-off independent of this engine choice (see
> [HLD §2](../HLD.md#2-the-workload--problem-under-design) and R1).

## Consequences

**Positive**
- Any operator runs the repo on the engine their org already standardized on; no license blocker.

**Negative / Risks accepted**
- We forgo any engine-exclusive feature (mitigated: none needed for this workload; CI can run both
  engines if divergence ever appears).

## Revisit If

- The two engines diverge enough that a needed feature exists in only one, or an org policy mandates
  a single engine.
