# ---------------------------------------------------------------------------
# MS Ports sub-module
#
# Manages switch port configuration.  Ports are keyed by serial + port_id
# from the JSON config, supporting both access and trunk modes.
#
# Provider resources:
#   - meraki_switch_port (for_each)
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

locals {
  # Flatten ports across all switches into a map keyed by "serial:port_id"
  port_map = {
    for p in try(var.config.ports, []) :
    "${p.serial}:${p.portId}" => p
  }
}

# ---------------------------------------------------------------------------
# FIELD-TESTED QUIRK (disabled-port apply guard)
#
# The Dashboard API returns HTTP 400 on any PUT that sets allowedVlans on a
# DISABLED switchport ("enable the port first"), and GET omits allowedVlans on
# disabled ports entirely. So declaring allowed_vlans = "all" on a port whose
# enabled=false is literally un-appliable, AND produces a perpetual
# "1 to change" diff because the live object never carries the attribute back.
#
# Guard: only emit allowed_vlans when the port is enabled. For a disabled port
# we send null so the provider omits the attribute and the plan stays a no-op.
# (Reconcile an already-disabled port with `tofu apply -refresh-only`.)
# ---------------------------------------------------------------------------

resource "meraki_switch_port" "this" {
  for_each = local.port_map

  serial     = each.value.serial
  port_id    = each.value.portId
  name       = try(each.value.name, null)
  type       = try(each.value.type, "access")
  enabled    = try(each.value.enabled, true)
  vlan       = try(each.value.vlan, null)
  voice_vlan = try(each.value.voiceVlan, null)
  # Disabled-port guard: never emit allowedVlans on a disabled port (un-appliable 400).
  allowed_vlans            = try(each.value.enabled, true) ? try(each.value.allowedVlans, null) : null
  poe_enabled              = try(each.value.poeEnabled, true)
  stp_guard                = try(each.value.stpGuard, null)
  rstp_enabled             = try(each.value.rstpEnabled, null)
  isolation_enabled        = try(each.value.isolationEnabled, null)
  link_negotiation         = try(each.value.linkNegotiation, null)
  port_schedule_id         = try(each.value.portScheduleId, null)
  tags                     = try(each.value.tags, null)
  access_policy_type       = try(each.value.accessPolicyType, null)
  access_policy_number     = try(each.value.accessPolicyNumber, null)
  adaptive_policy_group_id = try(each.value.adaptivePolicyGroupId, null)
}
