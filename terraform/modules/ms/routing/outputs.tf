output "routing_interfaces" {
  description = "List of configured routing interface names."
  value       = [for i in meraki_switch_routing_interface.this : i.name]
}

output "static_routes_count" {
  description = "Number of static routes configured."
  value       = length(meraki_switch_routing_static_route.this)
}
