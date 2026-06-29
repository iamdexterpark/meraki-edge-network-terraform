# ---------------------------------------------------------------------------
# MR Settings sub-module
#
# Manages wireless network settings and Bluetooth settings.
#
# Provider resources:
#   - meraki_wireless_settings
#   - meraki_wireless_network_bluetooth_settings
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_wireless_settings" "this" {
  count = try(var.config.wireless, null) != null ? 1 : 0

  network_id                 = var.network_id
  meshing_enabled            = try(var.config.wireless.meshingEnabled, null)
  ipv6_bridge_enabled        = try(var.config.wireless.ipv6BridgeEnabled, null)
  location_analytics_enabled = try(var.config.wireless.locationAnalyticsEnabled, null)
  led_lights_on              = try(var.config.wireless.ledLightsOn, null)
}

resource "meraki_wireless_network_bluetooth_settings" "this" {
  count = try(var.config.bluetooth, null) != null ? 1 : 0

  network_id          = var.network_id
  scanning_enabled    = try(var.config.bluetooth.scanningEnabled, null)
  advertising_enabled = try(var.config.bluetooth.advertisingEnabled, null)
  major               = try(var.config.bluetooth.major, null)
  minor               = try(var.config.bluetooth.minor, null)
}
