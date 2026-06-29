# ADR-0004 — Explicit, logged default-deny firewall

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering · Security
**Related:** [HLD §7](../HLD.md#7-controls-protocols--patterns), [ADR-0003](0003-trust-zone-vlan-segmentation.md)

---

## Context and Problem Statement

Trust zones ([ADR-0003](0003-trust-zone-vlan-segmentation.md)) are only as strong as the policy that
governs traffic between them. Rule lists are evaluated top-down, first-match. **What is the terminal
posture for inter-zone (and egress) traffic, and how is it expressed?**

## Decision Drivers

- **D1 — Defensible default:** the safe posture is "deny unless explicitly allowed."
- **D2 — Visibility in review:** the deny must be obvious in code review, not implied.
- **D3 — Observability:** denied traffic should be loggable for detection and forensics.
- **D4 — No silent reliance on vendor defaults:** behavior must not depend on an implicit platform rule.

## Considered Options

### Option A — Implicit/default-allow with explicit denies for known-bad
- ➕ Fewer rules; nothing breaks by default.
- ➖ Anything not explicitly denied is permitted (violates D1); blocklists are unbounded and always
  incomplete.
- **Verdict: rejected — the wrong default; a blocklist is a losing game.**

### Option B — Rely on the platform's implicit default-deny without stating it
- ➕ Less config.
- ➖ Intent is invisible in review (violates D2, D4); the deny isn't logged unless explicit (D3); a
  platform behavior change silently changes posture.
- **Verdict: rejected — correct posture, but unstated and unobservable.**

### Option C — Explicit, logged `deny any/any` as the terminal rule, with reviewed top-down permits  ✅
- ➕ Default-deny is the stated posture (D1); the terminal rule is visible in the config (D2); syslog
  on the deny makes blocked traffic observable (D3); posture does not depend on an implicit default
  (D4).
- ➖ Slightly more verbose; every legitimate flow needs an explicit permit above the deny.
- **Verdict: chosen — intent that isn't in the code isn't intent.**

## Decision

Express the firewall as a top-down, first-match permit list terminated by an **explicit, logged
`deny any/any`**. Inter-zone permits are written individually and reviewed; the example posture
denies IoT→trusted and guest→RFC-1918, permits trusted→mgmt, and logs the terminal deny.

## Consequences

**Positive**
- The security posture is fully legible in code review; denied traffic is observable in logs;
  behavior is independent of platform default changes.

**Negative / Risks accepted**
- A forgotten permit is a (fail-safe) connectivity outage rather than an exposure — caught at
  `plan`/smoke test, and recoverable by adding the reviewed permit.

## Revisit If

- The platform exposes a richer policy primitive (identity/application-aware default-deny) that
  preserves the same explicit-and-logged property with less rule maintenance.
