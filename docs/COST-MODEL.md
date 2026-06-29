# Meraki Edge Network — Cost Model

> **Business accumen first.** This is the economic argument in full; the README carries only the
> summary. Two cost planes matter for a network-as-code workload, and conflating them hides the
> real levers — so keep them separate:
>
> 1. **Infrastructure plane** — what it costs to *own and run the edge*: Meraki hardware (CapEx),
>    per-device licensing (the recurring line that actually dominates), and the ISP/circuit OpEx.
> 2. **Operational / runtime plane** — what it costs to *operate the network as code*: the toil
>    of change, the cost of a change-induced outage, and the API/state mechanics that quietly add
>    up. (This is the network analogue of the template's AI-runtime plane — see the friction log.)
>
> Every figure carries a `Source` (vendor/list pricing URL or a stated assumption). Unsourced
> numbers are a draft, not a deliverable. **All dollar figures are list-price order-of-magnitude
> estimates for a single reference edge site (1× MX, 1× MS, 1× MR); negotiated/partner pricing is
> materially lower and varies by region. Treat them as a sizing model, not a quote.**

---

## 1. Infrastructure Plane — Own-and-Run the Edge

The genuine comparison is **manage-as-code (this repo)** vs the status quo of **clicking the
Dashboard by hand** vs a **bespoke scripted/SDK** approach. The hardware and licensing cost is the
*same* across all three — Meraki is Meraki — so the plane below is the platform cost floor; the
*differentiated* cost is in §2.

### 1.1 Hardware (CapEx, amortized)

| Device class (reference SKU) | Role | List CapEx (est.) | Amortized / mo (5-yr) | Source / assumption |
|---|---|---|---|---|
| MX security appliance (e.g. MX67/MX68 class) | edge L3 gw + firewall + SD-WAN | ~$600–$1,000 | ~$10–$17 | Assumption: small-branch MX list price band, [meraki.cisco.com/products/appliances](https://meraki.cisco.com/products/security-sd-wan/) (list bands, not a quote) |
| MS access switch (e.g. MS120-8P class) | L2/L3 access, PoE+ | ~$700–$1,100 | ~$12–$18 | Assumption: 8-port PoE+ access-switch list band, [meraki.cisco.com/products/switches](https://meraki.cisco.com/products/switches/) |
| MR access point (e.g. MR44 / CW9164 class) | Wi-Fi overlay | ~$1,000–$1,500 | ~$17–$25 | Assumption: Wi-Fi 6 AP list band, [meraki.cisco.com/products/wireless](https://meraki.cisco.com/products/wi-fi/) |
| **Hardware subtotal (1 site)** | | **~$2,300–$3,600** | **~$39–$60/mo** | 5-yr straight-line amortization |

### 1.2 Licensing (recurring OpEx — the dominant line)

Meraki is **inert without an active license** (an accepted SD-WAN trade-off — see [ADR-0007](adr/0007-opentofu-vs-terraform.md) context and HLD). Licensing is per-device, per-year, by tier.

| License | Tier | List / device / yr (est.) | Source / assumption |
|---|---|---|---|
| MX Enterprise / Advanced Security | Enterprise vs Adv. Sec. | ~$150–$600 | Assumption: published MX license bands vary widely by model + tier; confirm at [Dashboard → Organization → License info]. Adv. Security adds IDS/IPS + AMP. |
| MS license | Enterprise | ~$100–$300 | Assumption: per-switch annual, model-dependent. |
| MR license | Enterprise / Advanced | ~$100–$200 | Assumption: per-AP annual. |
| **Licensing subtotal (1 site, Enterprise)** | | **~$350–$1,100 / yr → ~$29–$92/mo** | co-termination model: all licenses share one expiry date |

> **Co-termination is a real operational cost trap** — adding one device re-prices the *whole*
> org's license pool to a common expiry. Budget license headroom before claiming a device, or a
> `tofu apply` that claims hardware can trigger an unexpected license charge. (See §2 traps.)

### 1.3 Circuit / ISP (recurring OpEx, site-local)

| Line item | Unit | Est. monthly | Source / assumption |
|---|---|---|---|
| Primary WAN (business fiber/cable) | flat | ~$80–$300 | Assumption: regional business-broadband band. |
| Secondary WAN (LTE/5G failover, optional) | flat + metered | ~$30–$60 | Assumption: failover-tier cellular plan; only billed on failover bytes if metered. |
| **Circuit subtotal** | | **~$80–$360/mo** | varies entirely by market |

### 1.4 Infra-plane rollup (single reference site)

| Class | Monthly est. | Notes |
|---|---|---|
| Hardware (amortized) | ~$39–$60 | sunk CapEx, 5-yr |
| Licensing | ~$29–$92 | Enterprise tier, co-termed |
| Circuit | ~$80–$360 | market-dependent |
| **Infra subtotal** | **~$148–$512/mo** | platform floor — identical whether managed by hand or by code |

---

## 2. Operational / Runtime Plane — Operate the Network as Code

> This plane is where this repo earns its keep. The hardware/licensing floor (§1) is fixed; the
> *operating* cost is not — and it is the line item most likely to surprise you. It is dominated by
> **human toil** and **the cost of a bad change**, not by infrastructure.

### 2.1 Toil of change (the status-quo tax)

The unit of work is "make a controlled change to the edge config" (a VLAN, a firewall rule, an
SSID) and prove it.

| Approach | Time / change (assumed) | Audit trail | Drift visibility | Multi-site cost |
|---|---|---|---|---|
| **Manual Dashboard** | ~15–45 min click-through + no review | none (tribal) | invisible | linear: re-click every site |
| **Bespoke script / SDK** | ~10–30 min + you own idempotency | commit, but no end-state | partial (you build it) | re-run, hope it's idempotent |
| **This repo (declarative)** | ~5–15 min: edit JSON → `plan` (peer review the diff) → `apply` | full: git history + plan output | **built-in**: `tofu plan` *is* drift detection | near-zero marginal: new `config/` dir |

**Toil cost model:** `changes/mo × minutes/change × loaded $/hr`.
Assumption: 20 changes/mo, loaded rate $75/hr.
- Manual: 20 × 30 min × $75/hr ≈ **$750/mo** of engineer time.
- This repo: 20 × 10 min × $75/hr ≈ **$250/mo**.
- **Toil delta ≈ $500/mo saved per operator**, and it *compounds* with site count — the
  status-quo line scales linearly with sites, this repo's does not.

### 2.2 Change-failure cost (the asymmetric risk)

A fat-fingered firewall rule or a wrong VLAN gateway during a manual edit can black-hole a site.

| Factor | Manual Dashboard | This repo |
|---|---|---|
| Pre-change review | none | `tofu plan` diff, peer-reviewed before apply |
| Blast radius | whole network, live | bounded per module; plan shows it |
| Rollback | re-remember + re-click | `git revert` + `apply` (the end-state is the artifact) |
| MTTR (assumed) | ~60–120 min | ~10–20 min |

**Change-failure cost model:** `change-failure-rate × incidents/mo × downtime-min × $/downtime-min`.
Assumption: a single-site retail/branch edge at $5/min of downtime cost.
- Manual at 5% failure, 20 changes, 90-min MTTR: `0.05 × 20 × 90 × $5` ≈ **$450/mo** expected loss.
- This repo at ~1% failure (plan + review catches most), 15-min MTTR: `0.01 × 20 × 15 × $5` ≈ **$15/mo**.
- **Change-failure delta ≈ $435/mo** of avoided expected downtime.

### 2.3 API / state mechanics (the small, real line items)

Network-as-code has no per-token meter, but it does have operational costs that hide in the plumbing:

- **Dashboard API rate limits.** The Meraki API is rate-limited (historically ~5–10 req/s/org;
  confirm current limit at [developer.cisco.com/meraki/api/rate-limit](https://developer.cisco.com/meraki/api-latest/#!rate-limit)).
  A large multi-site `apply` or a tight retry loop can hit `429`; the provider backs off, which
  *slows* applies but doesn't bill you. Cost is **wall-clock**, not dollars — size big applies and
  avoid hammering the org with parallel runs.
- **Remote state storage.** An encrypted backend (object store) costs cents/mo for a config of this
  size — effectively a rounding error, but it must exist (state is the source of recovery truth).
- **CI minutes.** `fmt`/`validate`/`plan` on every PR: trivial (seconds of a free-tier runner).

### 2.4 Operational-plane rollup

| Line item | Monthly est. (assumed) | Lever |
|---|---|---|
| Toil (vs manual) | **−$500** saved | declarative + peer-reviewed diffs + multi-site reuse |
| Change-failure expected loss | **−$435** avoided | `plan` gate + bounded blast radius + `git revert` rollback |
| State storage + CI | ~$1–$5 | rounding error |
| **Operational net** | **≈ $935/mo of avoided cost** vs manual | the repo's actual ROI lives here |

---

## 3. ⚠️ Runtime / Operational Cost Traps (read before deploying)

The network-IaC analogue of the template's AI-runtime traps. These turn a "cheap" automation into a
bleed or an outage; each is a control the design must address, not a disclaimer.

- **License co-termination on claim.** Claiming a device via `tofu apply` (the `devices` module)
  can re-price the org's whole license pool to a shared expiry. **Pre-stage license capacity before
  the apply that claims hardware.** Treat a device-claim apply as a budget event.
- **API rate-limit retry storms.** A multi-site `apply` or a watchdog re-running `plan` in a tight
  loop hits the org rate limit; the provider retries, applies slow down, and a CI pipeline can
  stall. **Serialize org-wide applies; never run parallel `apply` against the same org; back off.**
- **Drift-detection cron that *applies*.** A scheduled `plan` is healthy (it surfaces drift). A
  scheduled `apply` is a footgun — it can reconcile away an emergency hand-edit made during an
  incident. **Schedule `plan` (detect + alert); gate `apply` behind a human.** (Template's
  heartbeat trap, network edition.)
- **State drift from out-of-band Dashboard edits.** Someone clicks the GUI; now state lies. Cost is
  a confusing next-apply. **Enforce change-via-repo; use scheduled `plan` to catch and re-reconcile.**
- **Stale provider/version pins.** A moving `>=` constraint silently upgrades the provider mid-apply
  and can change resource behavior. **Pin the provider; commit the lock for reproducible CI** (we
  gitignore the lock here only because it's a portfolio repo — a real deployment commits it).
- **Orphaned cloud objects on teardown.** `tofu destroy` removes Meraki config but a forgotten
  remote-state bucket or a still-claimed device keeps billing. **Decommission verifies zero
  orphans** — see [OPERATIONS Day-N](OPERATIONS.md#day-n--decommission-retire-cleanly).

**Guardrails to wire in:**
- A **license-headroom check** before any apply that claims devices.
- **Scheduled `plan` (not apply)** for drift detection, alert on non-empty diff.
- **Serialized applies** per org; CI concurrency lock.
- **Pinned provider + committed lock** (real deployments); reviewed PR diff on every change.

---

## 4. Total Cost of Ownership (rollup)

| Plane | Monthly | Driver | Lever |
|---|---|---|---|
| Infrastructure | ~$148–$512 | hardware + licensing + circuit | tier choice; same floor regardless of management method |
| Operational (vs manual) | **≈ −$935 avoided** | toil + change-failure | declarative + reviewed diffs + bounded blast radius |
| **TCO** | platform floor **minus** ~$935/mo of avoided toil & risk | | |

*Break-even / ROI:* the repo's cost is the one-time authoring effort plus near-zero ongoing
storage. Against a manual baseline it returns **~$935/mo per operator in avoided toil and avoided
change-failure downtime** (§2.1 + §2.2), and that figure **scales with site count** while the
manual baseline scales linearly worse. It pays for itself inside the first month of a multi-change,
multi-site operation — tie this to the README Business Case figure.
