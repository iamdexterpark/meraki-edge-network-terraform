# ---------------------------------------------------------------------------
# MS QoS sub-module
#
# Manages switch QoS rules and DSCP-to-CoS mappings.
#
# Provider resources:
#   - meraki_switch_qos_rule (for_each)
#   - meraki_switch_dscp_to_cos_mappings
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# --- QoS Rules ---
resource "meraki_switch_qos_rule" "this" {
  for_each = { for idx, r in try(var.config.qos_rules, []) : tostring(idx) => r }

  network_id = var.network_id
  vlan       = try(each.value.vlan, null)
  protocol   = try(each.value.protocol, "ANY")
  src_port   = try(each.value.srcPort, null)
  dst_port   = try(each.value.dstPort, null)
  dscp       = each.value.dscp
}

# --- DSCP-to-CoS Mappings ---
resource "meraki_switch_dscp_to_cos_mappings" "this" {
  count = try(var.config.dscp_to_cos_mappings, null) != null ? 1 : 0

  network_id = var.network_id
  mappings   = var.config.dscp_to_cos_mappings.mappings
}
