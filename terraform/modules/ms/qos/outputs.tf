output "qos_rules_count" {
  description = "Number of QoS rules configured."
  value       = length(meraki_switch_qos_rule.this)
}
