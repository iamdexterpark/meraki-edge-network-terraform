output "rf_profile_names" {
  description = "List of configured RF profile names."
  value       = [for p in meraki_wireless_rf_profile.this : p.name]
}
