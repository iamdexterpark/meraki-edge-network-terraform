# ---------------------------------------------------------------------------
# MS Routing sub-module
#
# Manages L3 routing interfaces, static routes, and OSPF on the switch.
#
# Provider resources:
#   - meraki_switch_routing_interface (for_each)
#   - meraki_switch_routing_static_route (for_each)
#   - meraki_switch_routing_ospf
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# --- L3 Routing Interfaces ---
resource "meraki_switch_routing_interface" "this" {
  for_each = { for idx, i in try(var.config.routing_interfaces, []) : try(i.name, tostring(idx)) => i }

  serial          = each.value.serial
  name            = try(each.value.name, each.key)
  subnet          = try(each.value.subnet, null)
  interface_ip    = try(each.value.interfaceIp, null)
  vlan_id         = try(each.value.vlanId, null)
  default_gateway = try(each.value.defaultGateway, null)
}

# --- Static Routes ---
resource "meraki_switch_routing_static_route" "this" {
  for_each = { for idx, r in try(var.config.static_routes, []) : try(r.name, tostring(idx)) => r }

  serial                          = each.value.serial
  name                            = try(each.value.name, each.key)
  subnet                          = each.value.subnet
  next_hop_ip                     = each.value.nextHopIp
  advertise_via_ospf_enabled      = try(each.value.advertiseViaOspfEnabled, null)
  prefer_over_ospf_routes_enabled = try(each.value.preferOverOspfRoutesEnabled, null)
}

# --- OSPF ---
resource "meraki_switch_routing_ospf" "this" {
  count = try(var.config.ospf, null) != null ? 1 : 0

  network_id                 = var.network_id
  enabled                    = try(var.config.ospf.enabled, false)
  hello_timer_in_seconds     = try(var.config.ospf.helloTimerInSeconds, null)
  dead_timer_in_seconds      = try(var.config.ospf.deadTimerInSeconds, null)
  md5_authentication_enabled = try(var.config.ospf.md5AuthenticationEnabled, null)
}
