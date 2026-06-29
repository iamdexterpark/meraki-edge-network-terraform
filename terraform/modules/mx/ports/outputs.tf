output "configured_ports" {
  description = "List of port IDs configured on the appliance."
  value       = [for p in meraki_appliance_port.this : p.port_id]
}
