# ---------------------------------------------------------------------------
# MX Firewall sub-module
#
# Manages L3 and L7 firewall rules on the MX appliance.
# Rules are applied top-down, first match wins.
#
# Provider resources:
#   - meraki_appliance_l3_firewall_rules
#   - meraki_appliance_l7_firewall_rules
#   - meraki_appliance_inbound_firewall_rules
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# --- L3 Firewall Rules ---
resource "meraki_appliance_l3_firewall_rules" "this" {
  count = try(var.config.l3_firewall_rules, null) != null ? 1 : 0

  network_id          = var.network_id
  syslog_default_rule = try(var.config.l3_firewall_rules.syslogDefaultRule, true)

  rules = [for r in try(var.config.l3_firewall_rules.rules, []) : {
    comment        = try(r.comment, "")
    policy         = r.policy
    protocol       = r.protocol
    src_cidr       = r.srcCidr
    src_port       = try(r.srcPort, "Any")
    dest_cidr      = r.destCidr
    dest_port      = try(r.destPort, "Any")
    syslog_enabled = try(r.syslogEnabled, r.policy == "deny")
  }]
}

# --- L7 Firewall Rules ---
resource "meraki_appliance_l7_firewall_rules" "this" {
  count = try(var.config.l7_firewall_rules, null) != null ? 1 : 0

  network_id = var.network_id

  rules = [for r in try(var.config.l7_firewall_rules.rules, []) : {
    policy = r.policy
    type   = r.type
    value  = try(r.value, null)
  }]
}
