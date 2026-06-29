output "settings_applied" {
  description = "Whether wireless settings were applied."
  value       = length(meraki_wireless_settings.this) > 0
}
