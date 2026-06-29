# ---------------------------------------------------------------------------
# Devices module
#
# Claims devices into the network and applies device-level settings.
# This must run after the network is created and before any device-specific
# feature modules (mx/*, ms/*, mr/*).
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# Claim devices into the network.  The serials list should contain all
# device serials (MX, MS, MR) that belong to this network.
resource "meraki_network_device_claim" "this" {
  count = length(try(var.config.serials, [])) > 0 ? 1 : 0

  network_id = var.network_id
  serials    = var.config.serials
}

# Per-device settings (name, address, tags, etc.).
# Keyed by serial so each device can be configured independently.
resource "meraki_device" "this" {
  for_each = { for d in try(var.config.devices, []) : d.serial => d }

  serial          = each.value.serial
  name            = try(each.value.name, null)
  address         = try(each.value.address, null)
  tags            = try(each.value.tags, null)
  notes           = try(each.value.notes, null)
  move_map_marker = try(each.value.move_map_marker, null)
  lat             = try(each.value.lat, null)
  lng             = try(each.value.lng, null)

  depends_on = [meraki_network_device_claim.this]
}
