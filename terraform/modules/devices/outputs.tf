output "device_serials" {
  description = "Map of device serial → device name."
  value       = { for s, d in meraki_device.this : s => d.name }
}

output "claimed" {
  description = "Whether devices were claimed into the network."
  value       = length(meraki_network_device_claim.this) > 0
}
