# ---------------------------------------------------------------------------
# MS STP sub-module
#
# Manages Spanning Tree Protocol settings on the switch network.
#
# Provider resources:
#   - meraki_switch_stp
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_switch_stp" "this" {
  count = try(var.config, null) != null ? 1 : 0

  network_id          = var.network_id
  rstp_enabled        = try(var.config.rstpEnabled, true)
  stp_bridge_priority = try(var.config.stpBridgePriority, null)
}
