# ---------------------------------------------------------------------------
# MX Routing sub-module
#
# Manages static routes on the MX appliance.
#
# Provider resources:
#   - meraki_appliance_static_route (for_each)
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_appliance_static_route" "this" {
  for_each = { for idx, r in try(var.config.static_routes, []) : try(r.name, tostring(idx)) => r }

  network_id      = var.network_id
  name            = try(each.value.name, each.key)
  subnet          = each.value.subnet
  gateway_ip      = each.value.gatewayIp
  gateway_vlan_id = try(each.value.gatewayVlanId, null)
}
