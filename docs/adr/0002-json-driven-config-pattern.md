# ADR-0002 — JSON-driven, Dashboard-shaped configuration over typed HCL variables

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering
**Related:** [HLD §5](../HLD.md#5-design-principles), [LLD §4](../LLD.md#4-configuration--concrete), [ADR-0001](0001-declarative-over-imperative.md)

---

## Context and Problem Statement

Given a declarative reconciler ([ADR-0001](0001-declarative-over-imperative.md)), the configuration
*data* has to enter the modules somehow. The control plane's API speaks a documented JSON object
model. **How should operators express per-network/per-device configuration so that the modules stay
stable as the platform adds features?**

## Decision Drivers

- **D1 — Data/logic separation:** adding a setting should edit data, never module logic.
- **D2 — Low translation cost:** copying a payload from the API docs should be near-verbatim.
- **D3 — Module stability:** new provider attributes should not force module rewrites.
- **D4 — Optionality:** an absent setting/file should be a clean no-op, not an error.
- **D5 — Reviewability of values:** the live values must diff cleanly in version control.

## Considered Options

### Option A — Strongly-typed HCL variables per setting
- ➕ Compile-time validation; editor autocomplete; explicit contracts.
- ➖ Every new provider attribute is a new typed variable → module churn (violates D3); payloads
  must be hand-translated from the API's JSON shape (D2); verbose.
- **Verdict: rejected — couples module logic to the platform's evolving schema.**

### Option B — One module per resource, values inline in HCL
- ➕ Maximally explicit.
- ➖ Data and logic fused (violates D1); no clean way to copy from API docs (D2); diffs mix structure
  and values (D5).
- **Verdict: rejected — fuses the two things D1 says to separate.**

### Option C — JSON config files, camelCase, decoded via `jsondecode(file())`, fields wrapped in `try()`  ✅
- ➕ Data lives in JSON, modules in HCL (D1); camelCase mirrors the API so payloads paste in
  near-verbatim (D2); `try()` makes every field optional so new attributes need only a JSON edit
  (D3, D4); JSON diffs are pure values (D5).
- ➖ Loses compile-time type safety on the data; a typo surfaces at plan, not at edit.
- **Verdict: chosen — the optionality and zero-churn properties outweigh the lost static typing.**

## Decision

Drive all configuration from JSON files whose keys are **camelCase to match the Dashboard API**,
decoded with `jsondecode(file("${config_path}/..."))`, with every optional field wrapped in `try()`
inside the module. Modules never change to add a setting — the JSON does.

## Consequences

**Positive**
- Operators copy examples straight from the API documentation; modules are stable across provider
  feature additions; the `config.example/` tree is a safe-to-share reference.
- A missing file or key is a no-op (the `try()` defaults), so partial adoption is frictionless.

**Negative / Risks accepted**
- No static typing on values — a malformed value fails at `plan`/`apply` rather than at edit
  (mitigated: `tofu validate` + a JSON lint in CI; the plan is reviewed before apply).

## Revisit If

- The provider ships a typed object schema rich enough that static validation outweighs the
  copy-from-docs ergonomics, or JSON drift between files becomes a recurring defect source.
