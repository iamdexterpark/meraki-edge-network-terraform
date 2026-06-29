output "vlans_enabled" {
  description = "Whether VLANs are enabled on the appliance."
  value       = meraki_appliance_vlans_settings.this.vlans_enabled
}
