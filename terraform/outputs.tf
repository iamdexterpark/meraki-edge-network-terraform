# ---------------------------------------------------------------------------
# Root outputs — surfaces key identifiers and summaries from all modules.
# ---------------------------------------------------------------------------

# --- Core ---
output "organization_id" {
  description = "Organization ID the network lives in."
  value       = module.org.organization_id
}

output "network_id" {
  description = "ID of the created Meraki network."
  value       = module.network.network_id
}

# --- MX Appliance ---
output "mx_vlan_ids" {
  description = "VLAN IDs configured on the MX appliance."
  value       = module.mx_vlans.vlan_ids
}

output "mx_l3_firewall_rules_count" {
  description = "Number of L3 firewall rules on the MX."
  value       = module.mx_firewall.l3_rules_count
}

output "mx_vpn_mode" {
  description = "Site-to-site VPN mode."
  value       = module.mx_vpn.vpn_mode
}

# --- MS Switch ---
output "ms_configured_ports" {
  description = "Switch ports configured by Terraform."
  value       = module.ms_ports.configured_ports
}

output "ms_qos_rules_count" {
  description = "Number of QoS rules on the switch."
  value       = module.ms_qos.qos_rules_count
}

# --- MR Wireless ---
output "mr_ssid_names" {
  description = "Configured SSID names."
  value       = module.mr_ssids.ssid_names
}
