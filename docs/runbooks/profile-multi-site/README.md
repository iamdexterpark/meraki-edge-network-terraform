# Profile: `multi-site` (extension)

> The extension pattern. The `single-site` profile is written concretely; this is how you fan out to
> many sites **reusing every module and the JSON config pattern unchanged** — only configuration
> selection and state scoping change ([ADR-0008](../../adr/0008-deployment-profile-single-site.md),
> [LLD §Environment Profiles](../../LLD.md#environment-profiles)).

## What a `multi-site` target must specify

| Axis | How multi-site sets it |
|---|---|
| Config selection | `config_path = ./environments/<site>/config` (one set per site) |
| State scoping | per-site state: a workspace **or** a distinct backend `prefix`/key per site |
| Apply granularity | one apply **per site**, serialized (never parallel against one org → rate limits) |
| Blast radius | site-local per state; a bad apply cannot touch another site |
| Identity | same Meraki API key (or per-org keys if sites span orgs) |

## How to stand it up (reuse, don't rewrite)

1. **Backend:** reuse [`_common/01-bootstrap-backend`](../_common/01-bootstrap-backend/RUNBOOK.md);
   give each site its own `prefix` (or workspace).
   ```
   environments/
   ├── site-01/config/   # copy of terraform/config.example with site-01 values
   ├── site-02/config/
   └── site-03/config/
   ```
2. **Per site**, run the `single-site` runbooks 02→04 unchanged, passing the site's config:
   ```bash
   cd terraform
   tofu workspace new site-01
   tofu apply -var="config_path=../environments/site-01/config"
   ```
3. **Drift/update/decommission:** the same `_common` + `single-site` runbooks, once per site,
   serialized.

## What stays identical to single-site

The 19 modules, the `try()`-driven JSON decode, the `depends_on` apply chain, the secret contract,
and the firewall/segmentation model. **Nothing in the deliverable changes** — multi-site is purely a
selection + state-scoping concern.

## When this earns its own ADR

If you move from per-site isolated state to **shared single-state**, or to a managed multi-site
wrapper, that is a material change to blast radius and state strategy — write a new ADR
([HLD §12 open questions](../../HLD.md#12-risks--open-questions)).
