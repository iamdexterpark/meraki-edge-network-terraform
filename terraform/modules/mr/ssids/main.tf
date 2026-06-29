# ---------------------------------------------------------------------------
# MR SSIDs sub-module
#
# Manages wireless SSID configuration.  Each SSID in the JSON config
# becomes a meraki_wireless_ssid resource.  PSKs are injected via a
# separate sensitive variable — never stored in JSON.
#
# Provider resources:
#   - meraki_wireless_ssid (for_each)
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_wireless_ssid" "this" {
  for_each = { for s in try(var.config.ssids, []) : tostring(s.number) => s }

  network_id = var.network_id
  number     = each.value.number
  name       = each.value.name
  enabled    = try(each.value.enabled, true)
  auth_mode  = try(each.value.authMode, "open")

  # IP assignment
  ip_assignment_mode = try(each.value.ipAssignmentMode, null)
  use_vlan_tagging   = try(each.value.useVlanTagging, contains(["Bridge mode", "Layer 3 roaming"], try(each.value.ipAssignmentMode, "")))
  default_vlan_id    = try(each.value.defaultVlanId, null)

  # Encryption — only meaningful for PSK or enterprise auth
  encryption_mode     = try(each.value.encryptionMode, each.value.authMode == "psk" ? "wpa" : null)
  wpa_encryption_mode = try(each.value.wpaEncryptionMode, each.value.authMode == "psk" ? "WPA3 Transition Mode" : null)

  # PSK — injected from sensitive variable, never from JSON
  psk = try(each.value.authMode, "open") == "psk" ? lookup(var.ssid_psks, each.value.name, null) : null

  # Optional settings pass-through
  min_bitrate                     = try(each.value.minBitrate, null)
  band_selection                  = try(each.value.bandSelection, null)
  per_client_bandwidth_limit_down = try(each.value.perClientBandwidthLimitDown, null)
  per_client_bandwidth_limit_up   = try(each.value.perClientBandwidthLimitUp, null)
  per_ssid_bandwidth_limit_down   = try(each.value.perSsidBandwidthLimitDown, null)
  per_ssid_bandwidth_limit_up     = try(each.value.perSsidBandwidthLimitUp, null)
  visible                         = try(each.value.visible, null)
  available_on_all_aps            = try(each.value.availableOnAllAps, null)
  splash_page                     = try(each.value.splashPage, null)
  lan_isolation_enabled           = try(each.value.lanIsolationEnabled, null)
}
