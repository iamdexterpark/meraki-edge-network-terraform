# ADR-0005 — Secrets materialized at runtime, never in the repo

**Status:** Accepted
**Date:** 2026-06-18
**Deciders:** Network/Platform Engineering · Security
**Related:** [HLD §5](../HLD.md#5-design-principles), [LLD §5](../LLD.md#5-secrets--concrete-wiring), [HLD R5](../HLD.md#12-risks--open-questions)

---

## Context and Problem Statement

The source of truth is a public-facing, reviewable artifact. The system needs two secret kinds at
runtime: the management **API key** and wireless **pre-shared keys (PSKs)**. **Where do those values
live, given that the repo must stay safe to share?**

## Decision Drivers

- **D1 — Repo is safe to share:** no value-bearing secret in any committed file or state in the repo.
- **D2 — Structure stays in the repo:** the config *shape* (which SSID uses a PSK) is not secret.
- **D3 — CI-friendly injection:** automation must supply secrets without committing them.
- **D4 — Least privilege & no logging:** secrets must be sensitive (unprinted) and narrowly scoped.

## Considered Options

### Option A — Secrets in the JSON config (encrypted-at-rest in git, e.g. SOPS)
- ➕ One source of truth; values travel with structure.
- ➖ Encrypted blobs still live in the repo (tension with D1); key management overhead; a decryption
  slip leaks values.
- **Verdict: rejected — keeps secret material in the artifact, even if encrypted.**

### Option B — Secrets as plain Terraform variables in committed `.tfvars`
- ➕ Trivial.
- ➖ Plaintext secrets in git (flatly violates D1).
- **Verdict: rejected outright.**

### Option C — Runtime injection: API key via `MERAKI_DASHBOARD_API_KEY` env; PSKs via a sensitive `TF_VAR_ssid_psks` map looked up by SSID name  ✅
- ➕ No secret value in any committed file (D1); the JSON still declares *which* SSID needs a PSK,
  structure only (D2); env-var injection is native to CI (D3); variables are `sensitive` and the
  provider reads the key directly, never echoed (D4).
- ➖ Operators must wire the env/secret store themselves; a forgotten export is a clear, early failure.
- **Verdict: chosen — only the values are secret, never the structure.**

## Decision

Materialize secrets at runtime: the API key from `MERAKI_DASHBOARD_API_KEY` (provider reads it
directly), PSKs from a `sensitive` `TF_VAR_ssid_psks` name→key map that `mr/ssids` looks up by SSID
name. Only `config.example/` (no values) is committed; `config/`, state, and `*.tfvars` are
gitignored. A CI secret-scan gate blocks accidental value-bearing material.

## Consequences

**Positive**
- The repo is publishable as-is; rotating a secret is an env/store change, not a commit; state is
  the only place a secret could land, so it goes to an encrypted remote backend.

**Negative / Risks accepted**
- Operators own secret distribution (mitigated: documented env contract + CI scan; a missing secret
  fails fast at apply rather than silently).

## Revisit If

- A team secret-store standard (Vault/GSM/etc.) becomes mandatory enough to wire a provider-side
  data source, or state-stored sensitive values need field-level encryption beyond backend-at-rest.
