output "vpn_mode" {
  description = "Site-to-site VPN mode (none, hub, spoke)."
  value       = length(meraki_appliance_site_to_site_vpn.this) > 0 ? meraki_appliance_site_to_site_vpn.this[0].mode : "none"
}
