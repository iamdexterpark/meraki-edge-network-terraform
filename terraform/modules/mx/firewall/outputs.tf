output "l3_rules_count" {
  description = "Number of L3 firewall rules configured."
  value       = length(meraki_appliance_l3_firewall_rules.this) > 0 ? length(try(var.config.l3_firewall_rules.rules, [])) : 0
}

output "l7_rules_count" {
  description = "Number of L7 firewall rules configured."
  value       = length(meraki_appliance_l7_firewall_rules.this) > 0 ? length(try(var.config.l7_firewall_rules.rules, [])) : 0
}
