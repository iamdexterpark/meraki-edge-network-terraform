# ADR-0001 — Declarative end-state over imperative scripting

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering
**Related:** [HLD §2](../HLD.md#2-the-workload--problem-under-design), [HLD §5](../HLD.md#5-design-principles)

---

## Context and Problem Statement

The keystone property of the workload is that network configuration is a **desired-state**
problem (see [HLD §2](../HLD.md#2-the-workload--problem-under-design)): we make statements about
what should be true, not steps to perform. The platform is cloud-managed and API-first, so multiple
automation paradigms can drive it. **How should we express and enforce edge network intent?**

## Decision Drivers

- **D1 — Reviewability:** a change should be a peer-reviewable artifact before it touches production.
- **D2 — Drift handling:** divergence between intent and reality must be detectable, ideally for free.
- **D3 — Idempotency:** re-running the same intent must converge, not double-apply.
- **D4 — Reproducibility across sites:** standing up another site should not be a fresh manual effort.
- **D5 — Control over change actions:** some operations (firmware rollout, emergency shutdown) are
  genuinely imperative and must remain possible.

## Considered Options

### Option A — Manual Dashboard configuration
- ➕ Zero tooling; fastest for a one-off single site.
- ➖ No artifact, no review (violates D1); drift invisible (D2); not reproducible (D4); idempotency
  is a human (D3).
- **Verdict: rejected — unmanageable past one site, and unauditable even at one.**

### Option B — Imperative scripting (SDK / playbooks / curl)
- ➕ Total control over ordering; trivial for one-off verbs (satisfies D5 directly).
- ➖ *You* own idempotency (D3); drift is invisible unless you build detection (D2); the script is a
  sequence of actions, not a reviewable end-state (D1 partial).
- **Verdict: rejected as the primary paradigm — kept for actions (D5), not for state.**

### Option C — Declarative end-state (Terraform/OpenTofu)  ✅
- ➕ The configuration *is* the reviewable artifact (D1); the plan *is* drift detection (D2);
  idempotent by construction (D3); a new site is a new config set (D4).
- ➖ Less control over *how* a change applies; genuinely imperative verbs don't fit.
- **Verdict: chosen for state; imperative actions handled out of band.**

## Decision

Express and enforce edge network **state** declaratively with a Terraform/OpenTofu-compatible
reconciler. Keep imperative tooling for **actions** only. The honest boundary: declarative for
state, imperative for verbs.

## Consequences

**Positive**
- Every change is a reviewed plan with a git history; drift detection is free via scheduled `plan`.
- Reproducing or rebuilding a site is an apply, not a memory exercise.

**Negative / Risks accepted**
- We give up fine-grained control over apply mechanics (mitigated: the platform's API ordering is
  modeled explicitly — see [ADR-0006](0006-dependency-ordering.md)).
- A scheduled *apply* could reconcile away an emergency hand-edit ([HLD R6](../HLD.md#12-risks--open-questions)) —
  mitigated by scheduling `plan` only and gating `apply` behind a human.

## Revisit If

- The platform gains a first-class declarative interface of its own that supersedes a general-purpose
  reconciler, or a workload emerges that is genuinely action-shaped rather than state-shaped.
