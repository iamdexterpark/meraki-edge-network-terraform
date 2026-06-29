# ---------------------------------------------------------------------------
# MX Ports sub-module
#
# Manages per-port VLAN settings on the MX appliance.
#
# Provider resources:
#   - meraki_appliance_port (for_each)
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_appliance_port" "this" {
  for_each = { for p in try(var.config.ports, []) : tostring(p.portId) => p }

  network_id            = var.network_id
  port_id               = each.value.portId
  enabled               = try(each.value.enabled, true)
  type                  = try(each.value.type, "access")
  vlan                  = try(each.value.vlan, null)
  drop_untagged_traffic = try(each.value.dropUntaggedTraffic, null)
  allowed_vlans         = try(each.value.allowedVlans, null)
  access_policy         = try(each.value.accessPolicy, null)
}
