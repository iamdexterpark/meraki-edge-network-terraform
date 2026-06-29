# ADR-0003 — Trust-zone VLAN segmentation as the core security control

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering · Security
**Related:** [HLD §2](../HLD.md#2-the-workload--problem-under-design), [HLD §7](../HLD.md#7-controls-protocols--patterns), [ADR-0004](0004-default-deny-firewall.md)

---

## Context and Problem Statement

The edge is where the least-trusted, most-numerous endpoints live (guest, IoT). The keystone
constraint ([HLD §2](../HLD.md#2-the-workload--problem-under-design)) is that cross-trust traffic
must be denied unless explicitly permitted. **What is the primary structural control that enforces
that boundary?**

## Decision Drivers

- **D1 — Blast-radius containment:** a compromised endpoint must not have flat-network reach.
- **D2 — Management isolation:** device administration must be unreachable from general user traffic.
- **D3 — Enforceable in code:** the control must be expressible as reviewable declarative config.
- **D4 — Operational simplicity:** it must be comprehensible to anyone fluent in the platform.
- **D5 — Endpoint-agnostic:** it must not depend on trusting or agent-ing the endpoints.

## Considered Options

### Option A — Flat L2 network, host-level controls
- ➕ Simplest to stand up; no inter-VLAN routing to design.
- ➖ Zero containment (violates D1); management shares the broadcast domain (D2); relies on every
  endpoint defending itself (D5).
- **Verdict: rejected — a single compromise owns the network.**

### Option B — Microsegmentation / per-host identity policy (NAC, SGT, ZTNA-style)
- ➕ Finest-grained control; identity-aware.
- ➖ Heavy to operate at a small edge (violates D4); depends on endpoint posture/agents (D5);
  overkill for the site cardinality this design targets.
- **Verdict: rejected for the primary control — a valid *future* layer above this one.**

### Option C — Trust-zone L3 VLAN segmentation (mgmt / trusted / iot / guest)  ✅
- ➕ Each zone is its own L3 broadcast domain → containment (D1); management is its own zone (D2);
  expressed as declarative VLAN + gateway + firewall config (D3); maps 1:1 to how operators already
  think (D4); enforced at the gateway regardless of endpoint cooperation (D5).
- ➖ Coarser than per-host policy; inter-zone exceptions must be written explicitly.
- **Verdict: chosen — the highest-leverage control per unit of operational complexity at the edge.**

## Decision

Segment the edge into distinct L3 trust zones — `mgmt`, `trusted`, `iot`, `guest` — each its own
VLAN/subnet/broadcast domain, gatewayed and firewalled at the security appliance. Wireless SSIDs map
onto these zones (bridge or isolated-NAT). This is the primary security control; the firewall posture
([ADR-0004](0004-default-deny-firewall.md)) enforces the boundaries between them.

## Consequences

**Positive**
- A compromise is contained to a zone; management traffic is unreachable from user traffic; the
  segmentation is visible and reviewable in the config.

**Negative / Risks accepted**
- Legitimate cross-zone flows require explicit firewall permits (by design — see ADR-0004); a missed
  permit is a (safe-direction) outage, caught at `plan`/test rather than as a breach.

## Revisit If

- Endpoint density or compliance requirements outgrow zone-level control and justify the operational
  cost of microsegmentation as a layer above this one.
