output "vlan_ids" {
  description = "List of VLAN IDs created on the appliance."
  value       = [for v in meraki_appliance_vlan.this : v.vlan_id]
}

output "vlans" {
  description = "Map of VLAN ID to VLAN details."
  value       = { for k, v in meraki_appliance_vlan.this : k => { name = v.name, subnet = v.subnet } }
}
