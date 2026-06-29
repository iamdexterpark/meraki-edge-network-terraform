# ADR-0008 — Single-site as the primary deployment profile

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering
**Related:** [HLD §10](../HLD.md#10-portability), [LLD §Environment Profiles](../LLD.md#environment-profiles), [ADR-0006](0006-dependency-ordering.md)

---

## Context and Problem Statement

The repo must be written against a **concrete primary profile** while leaving room for others
without a rewrite (PLAYBOOK §5b). The realistic deployment shapes are: one edge site; many sites
sharing one state; or many sites with isolated state. The ADRs, LLD addressing, and the apply graph
are all written against *some* profile. **Which is primary?**

## Decision Drivers

- **D1 — Concreteness:** the primary profile must be specifiable down to addresses and apply order.
- **D2 — Lowest blast radius:** the primary should isolate failures, not couple sites.
- **D3 — Additive extension:** moving to multi-site must reuse modules + config pattern unchanged.
- **D4 — Operational fit:** it must match the single-operator / small-fleet reality this targets.
- **D5 — State simplicity:** state model must be the simplest that is still recoverable.

## Considered Options

### Option A — Multi-site, shared single state (one state for all sites)
- ➕ One apply manages everything.
- ➖ Largest blast radius — one bad apply touches every site (violates D2); state contention; an org
  rate-limit storm risk on every run (D4).
- **Verdict: rejected as primary — couples sites that should fail independently.**

### Option B — Multi-site, per-site isolated state (workspaces / separate state dirs)
- ➕ Per-site isolation; good *target* shape for a real fleet.
- ➖ More moving parts than a clean primary needs (D1 harder to pin down to one address plan);
  premature for the design's baseline (D4).
- **Verdict: rejected as primary — it's the natural *extension* profile, not the baseline.**

### Option C — Single edge site as the primary profile  ✅
- ➕ Fully concrete: one org, one network, the four-zone address plan, the documented apply order
  (D1); failures are inherently site-local (D2); the modules + JSON pattern are identical when you
  fan out — only `config_path`/workspace changes (D3); matches the single-operator reality (D4); one
  state file, one encrypted backend (D5).
- ➖ Multi-site fan-out is left as an extension profile, not solved in the baseline.
- **Verdict: chosen — the simplest fully-specifiable profile; multi-site is additive.**

## Decision

Write the LLD, addressing, and apply graph against a **single edge site** (`profile-single-site`):
one organization, one network, MX/MS/MR, four trust zones, one encrypted remote state. **Multi-site**
is a documented **extension profile** (`profile-multi-site`) that reuses every module and the JSON
config pattern unchanged, switching only `config_path`/workspace and state scoping. A material switch
to a shared-state or managed multi-site model earns its own ADR.

## Consequences

**Positive**
- The whole design is concrete and reproducible; failures stay site-local; scaling out is mechanical
  (copy a `config/` set), not a redesign.

**Negative / Risks accepted**
- The canonical multi-site state strategy is deferred (mitigated: the extension profile documents the
  axes; the modules already support it via `config_path` + workspaces) — see
  [HLD §12 open questions](../HLD.md#12-risks--open-questions).

## Revisit If

- The fleet grows enough that multi-site becomes the *baseline* reality, at which point the
  extension profile is promoted and gets its own state-strategy ADR.
