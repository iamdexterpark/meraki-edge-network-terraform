# ADR-0006 — Explicit dependency ordering matching the platform hierarchy

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering
**Related:** [HLD §6](../HLD.md#6-architecture), [LLD §3](../LLD.md#3-the-deliverable-structure), [ADR-0001](0001-declarative-over-imperative.md)

---

## Context and Problem Statement

The control-plane API has hard ordering requirements: an organization must exist before a network
binds to it; a device must be claimed before its ports are configured; VLANs must be *enabled* on
the appliance before individual VLANs can be created. A declarative reconciler infers ordering from
references, but several of these ordering constraints are **side-effect dependencies the data flow
does not express**. **How do we guarantee correct apply order?**

## Decision Drivers

- **D1 — Correctness:** the apply must never attempt a resource before its precondition exists.
- **D2 — Visibility:** the ordering should be legible to a reader, not hidden in implicit graphs.
- **D3 — Minimal coupling:** ordering must not force modules to pass data they don't actually use.
- **D4 — Hierarchy alignment:** the order should mirror the platform's own object model (ADR-0002).

## Considered Options

### Option A — Rely solely on implicit reference-based ordering
- ➕ No extra code; idiomatic.
- ➖ Side-effect preconditions (enable-VLANs-before-VLAN, claim-before-port) aren't expressed by any
  value reference, so the reconciler may parallelize them wrongly (violates D1).
- **Verdict: rejected — silently incorrect for the API's side-effect constraints.**

### Option B — Pass synthetic "ready" outputs between modules to force edges
- ➕ Ordering rides the normal dependency graph.
- ➖ Modules must emit/consume dummy values they don't use (violates D3); obscures intent (D2).
- **Verdict: rejected — couples modules with fake data to encode ordering.**

### Option C — Explicit `depends_on` between modules, structured to mirror the hierarchy  ✅
- ➕ Guarantees side-effect ordering (D1); the `depends_on` edges read as the hierarchy
  org→network→devices→settings→features (D2, D4); no synthetic data passing (D3).
- ➖ Slightly more verbose; the author must know the API's ordering rules (documented in the LLD).
- **Verdict: chosen — makes the platform's ordering explicit and reviewable.**

## Decision

Encode apply order with explicit `depends_on` between modules, arranged to mirror the platform
hierarchy: organization → network → device claims → device *settings* (e.g. enable VLANs) → device
*features* (VLANs, firewall, ports, SSIDs). The dependency chain is a first-class, diagrammed part
of the design ([architecture-at-a-glance](../HLD.md#6-architecture)).

## Consequences

**Positive**
- Applies are correct by construction against the API's ordering rules; the order is self-documenting
  and matches how operators navigate the console.

**Negative / Risks accepted**
- Authoring a new module requires knowing its precondition (mitigated: the LLD apply-order table and
  the dependency diagram are kept current; a wrong order fails loudly at apply).

## Revisit If

- The provider begins expressing these side-effect preconditions as real resource references (making
  implicit ordering sufficient), or the hierarchy itself changes.
