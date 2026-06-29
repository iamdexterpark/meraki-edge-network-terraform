# ---------------------------------------------------------------------------
# MX Settings sub-module
#
# Manages appliance-level settings including enabling VLANs.
# This must run before the vlans sub-module.
#
# Provider resources:
#   - meraki_appliance_settings
#   - meraki_appliance_vlans_settings
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_appliance_vlans_settings" "this" {
  network_id    = var.network_id
  vlans_enabled = try(var.config.vlans_enabled, true)
}
