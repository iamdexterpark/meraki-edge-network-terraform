# ---------------------------------------------------------------------------
# MS ACL sub-module
#
# Manages switch access control lists.
#
# Provider resources:
#   - meraki_switch_access_control_lists
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_switch_access_control_lists" "this" {
  count = try(var.config, null) != null ? 1 : 0

  network_id = var.network_id

  rules = [for r in try(var.config.rules, []) : {
    comment    = try(r.comment, "")
    policy     = r.policy
    ip_version = try(r.ipVersion, "any")
    protocol   = try(r.protocol, "any")
    src_cidr   = try(r.srcCidr, "any")
    src_port   = try(r.srcPort, "any")
    dst_cidr   = try(r.dstCidr, "any")
    dst_port   = try(r.dstPort, "any")
    vlan       = try(r.vlan, "any")
  }]
}
