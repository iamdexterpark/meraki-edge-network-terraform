output "static_routes" {
  description = "Map of static route name to subnet."
  value       = { for k, r in meraki_appliance_static_route.this : k => r.subnet }
}
