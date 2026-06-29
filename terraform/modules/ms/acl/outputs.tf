output "acl_rules_count" {
  description = "Number of ACL rules configured."
  value       = length(meraki_switch_access_control_lists.this) > 0 ? length(try(var.config.rules, [])) : 0
}
