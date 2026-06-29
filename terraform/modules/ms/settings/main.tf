# ---------------------------------------------------------------------------
# MS Settings sub-module
#
# Manages switch-level settings.
#
# Provider resources:
#   - meraki_switch_settings
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_switch_settings" "this" {
  count = try(var.config, null) != null ? 1 : 0

  network_id         = var.network_id
  vlan               = try(var.config.vlan, null)
  use_combined_power = try(var.config.useCombinedPower, null)
  power_exceptions   = try(var.config.powerExceptions, null)
}
