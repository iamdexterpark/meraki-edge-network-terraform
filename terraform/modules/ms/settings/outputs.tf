output "settings_applied" {
  description = "Whether switch settings were applied."
  value       = length(meraki_switch_settings.this) > 0
}
