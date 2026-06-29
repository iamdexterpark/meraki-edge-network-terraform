output "rstp_enabled" {
  description = "Whether RSTP is enabled."
  value       = length(meraki_switch_stp.this) > 0 ? meraki_switch_stp.this[0].rstp_enabled : null
}
