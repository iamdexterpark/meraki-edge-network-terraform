# Runbook 03 — Secrets (API key + SSID PSKs)

> **Target Environment**
> | | |
> |---|---|
> | **Deployment profile** | `profile-single-site` (the secret contract is identical on multi-site) |
> | **Substrate** | workstation/CI shell or CI secret store |
> | **Cloud services used** | optionally a secret manager (GSM/SSM/Vault) feeding the env vars |
> | **Identity model** | Meraki Dashboard API key (org read/write); SSID PSKs (name→key map) |
> | **What changes under a different profile** | nothing — same env contract; only *where* the values are sourced may differ |

**Goal:** the API key and any SSID PSKs are available to the reconciler at runtime, with **zero
secret material in the repo or state-on-disk** ([ADR-0005](../../../adr/0005-secrets-out-of-repo.md)).
**Time:** ~5 min · **Risk:** low · **Reversible:** yes (unset/rotate)

## Prerequisites

- A Dashboard API key (Dashboard → Organization → Settings → API access).
- The PSK values for any `authMode: psk` SSIDs (never put these in JSON).

## Steps

### 1. Export the API key (provider reads it directly)
```bash
export MERAKI_DASHBOARD_API_KEY="REPLACE_API_KEY"
# Alternative: export TF_VAR_meraki_api_key="REPLACE_API_KEY"
```

### 2. Export the PSK map (sensitive; looked up by SSID name)
```bash
export TF_VAR_ssid_psks='{"edge-trusted":"REPLACE","edge-iot":"REPLACE","edge-guest":"REPLACE"}'
```

### 3. (CI) Source from a secret store instead of plaintext export
```bash
# Example: pull at job start so nothing is committed and nothing persists on disk.
export MERAKI_DASHBOARD_API_KEY="$(gcloud secrets versions access latest --secret=meraki-api-key)"
```

## Verification

```bash
# Key is present and the provider authenticates (validate needs no key; a no-op plan proves auth):
cd terraform && tofu plan >/dev/null && echo "OK: provider authenticated"
# PSK map parses as JSON:
echo "$TF_VAR_ssid_psks" | jq . >/dev/null && echo "OK: PSK map well-formed"
# Repo is clean of secret material:
bash ../scripts/validate.sh 2>/dev/null | grep -q 'No obvious secret material' && echo "OK: secret scan clean"
```

## Rollback

```bash
unset MERAKI_DASHBOARD_API_KEY TF_VAR_ssid_psks TF_VAR_meraki_api_key
# Rotate the key in the Dashboard if it may have been exposed; update the secret store.
```

## Notes / Gotchas

- The PSK map is keyed by **SSID name** — a name mismatch yields a `null` PSK and clients can't auth
  (a common silent failure; see [troubleshooting](../09-troubleshooting/RUNBOOK.md)).
- State can contain the resolved PSK/key — this is exactly why state lives in an **encrypted** remote
  backend (runbook 01), never local-only.
- A missing key/PSK fails *early and loudly* at plan/apply, by design.
