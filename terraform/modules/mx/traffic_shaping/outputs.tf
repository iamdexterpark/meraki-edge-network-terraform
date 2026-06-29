output "shaping_rules_count" {
  description = "Number of traffic shaping rules configured."
  value       = length(meraki_appliance_traffic_shaping_rules.this) > 0 ? length(try(var.config.traffic_shaping_rules.rules, [])) : 0
}
