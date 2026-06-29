output "ssid_names" {
  description = "List of configured SSID names."
  value       = [for s in meraki_wireless_ssid.this : s.name]
}

output "ssid_numbers" {
  description = "Map of SSID number to SSID name."
  value       = { for k, s in meraki_wireless_ssid.this : k => s.name }
}
