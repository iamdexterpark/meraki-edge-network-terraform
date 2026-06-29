output "configured_ports" {
  description = "List of configured port identifiers (serial:port_id)."
  value       = keys(meraki_switch_port.this)
}
