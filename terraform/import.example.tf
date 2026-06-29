# ===========================================================================
# Brownfield adoption — import an EXISTING Meraki network under management
# ===========================================================================
#
# The high-value real-world scenario is NOT building a network from zero — it
# is adopting a network that already exists in the Dashboard (clicked together
# over years) and bringing it under declarative control WITHOUT a flag day.
#
# This file is an EXAMPLE. Copy to `import.tf`, fill in the real IDs/serials,
# `tofu plan` until every block reports "will be imported" with NO resource
# changes, `tofu apply`, then re-plan until you see:
#
#     No changes. Your infrastructure matches the configuration.
#
# That clean re-plan is the whole game: it proves your JSON config now
# faithfully describes the live network. Delete (or keep, harmlessly) the
# import blocks afterward — Terraform 1.5+ / OpenTofu import{} blocks are
# declarative and idempotent; a second apply is a no-op.
#
# WORKFLOW
#   1. Author config.example -> config/ JSON to MATCH what is live today
#      (read it from the Dashboard; do not "improve" it yet — adopt first,
#       refactor second).
#   2. Fill in the import{} blocks below (IDs from the Dashboard / API).
#   3. tofu plan        -> expect "N to import, 0 to add, 0 to change, 0 to destroy"
#      (NOTE: a plan containing import blocks exits NON-ZERO (2) by design —
#       "2" means "changes present", not "error". CI must treat exit 2 as success
#       for the import stage. See docs/runbooks/.../08-brownfield-import.)
#   4. tofu apply       -> 0 added / 0 changed / 0 destroyed, N imported
#   5. tofu plan again  -> "No changes." If you instead see "1 to change",
#      an optional() attribute is force-writing a value the live object omits;
#      default that attribute to null so the provider leaves it unset.
#
# The `to` address is the module resource address; the `id` is the Meraki
# import id for that resource type (formats vary per resource — see the
# provider docs `import` section for each `meraki_*` resource).
# ---------------------------------------------------------------------------

# --- Organization -----------------------------------------------------------
# import {
#   to = module.org.meraki_organization.this
#   id = "REPLACE_ORG_ID"
# }

# --- Network ----------------------------------------------------------------
# import {
#   to = module.network.meraki_network.this
#   id = "REPLACE_NETWORK_ID"
# }

# --- MX appliance VLANs (one block per live VLAN) ---------------------------
# import {
#   to = module.mx_vlans.meraki_appliance_vlan.this["10"]
#   id = "REPLACE_NETWORK_ID,10"           # most appliance resources: "<networkId>,<vlanId>"
# }

# --- MS switch ports (one block per live, ENABLED port) ---------------------
# Disabled ports: do NOT import allowedVlans (the API omits it on disabled
# ports; see modules/ms/ports/main.tf disabled-port guard).
# import {
#   to = module.ms_ports.meraki_switch_port.this["Q2XX-XXXX-XXXX:1"]
#   id = "REPLACE_SERIAL,1"
# }

# --- MR SSIDs (one block per configured SSID number 0..14) ------------------
# import {
#   to = module.mr_ssids.meraki_wireless_ssid.this["0"]
#   id = "REPLACE_NETWORK_ID,0"
# }

# ===========================================================================
# Refactor-safe renames: use `moved{}` blocks, never destroy+recreate
# ===========================================================================
# When you rename a JSON key or restructure a module's for_each key, a naive
# plan shows destroy+create (an OUTAGE on live infra). A moved{} block turns it
# into a pure state move — 0 destroyed.
#
# moved {
#   from = module.mx_vlans.meraki_appliance_vlan.this["10"]
#   to   = module.mx_vlans.meraki_appliance_vlan.this["data"]
# }
