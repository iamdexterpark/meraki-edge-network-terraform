# ---------------------------------------------------------------------------
# MR RF Profiles sub-module
#
# Manages wireless RF profiles.
#
# Provider resources:
#   - meraki_wireless_rf_profile (for_each)
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_wireless_rf_profile" "this" {
  for_each = { for idx, p in try(var.config.rf_profiles, []) : try(p.name, tostring(idx)) => p }

  network_id               = var.network_id
  name                     = each.value.name
  band_selection_type      = try(each.value.bandSelectionType, null)
  client_balancing_enabled = try(each.value.clientBalancingEnabled, null)
  min_bitrate_type         = try(each.value.minBitrateType, null)
  transmission_enabled     = try(each.value.transmissionEnabled, null)

  # AP band settings (flattened by provider)
  ap_band_settings_band_operation_mode   = try(each.value.apBandSettings.bandOperationMode, null)
  ap_band_settings_band_steering_enabled = try(each.value.apBandSettings.bandSteeringEnabled, null)
  ap_band_settings_bands_enabled         = try(each.value.apBandSettings.bandsEnabled, null)

  # 2.4 GHz settings (flattened by provider)
  two_four_ghz_settings_ax_enabled          = try(each.value.twoFourGhzSettings.axEnabled, null)
  two_four_ghz_settings_max_power           = try(each.value.twoFourGhzSettings.maxPower, null)
  two_four_ghz_settings_min_bitrate         = try(each.value.twoFourGhzSettings.minBitrate, null)
  two_four_ghz_settings_min_power           = try(each.value.twoFourGhzSettings.minPower, null)
  two_four_ghz_settings_rxsop               = try(each.value.twoFourGhzSettings.rxsop, null)
  two_four_ghz_settings_valid_auto_channels = try(each.value.twoFourGhzSettings.validAutoChannels, null)

  # 5 GHz settings (flattened by provider)
  five_ghz_settings_channel_width       = try(each.value.fiveGhzSettings.channelWidth, null)
  five_ghz_settings_max_power           = try(each.value.fiveGhzSettings.maxPower, null)
  five_ghz_settings_min_bitrate         = try(each.value.fiveGhzSettings.minBitrate, null)
  five_ghz_settings_min_power           = try(each.value.fiveGhzSettings.minPower, null)
  five_ghz_settings_rxsop               = try(each.value.fiveGhzSettings.rxsop, null)
  five_ghz_settings_valid_auto_channels = try(each.value.fiveGhzSettings.validAutoChannels, null)

  # 6 GHz settings (flattened by provider)
  six_ghz_settings_channel_width       = try(each.value.sixGhzSettings.channelWidth, null)
  six_ghz_settings_max_power           = try(each.value.sixGhzSettings.maxPower, null)
  six_ghz_settings_min_bitrate         = try(each.value.sixGhzSettings.minBitrate, null)
  six_ghz_settings_min_power           = try(each.value.sixGhzSettings.minPower, null)
  six_ghz_settings_rxsop               = try(each.value.sixGhzSettings.rxsop, null)
  six_ghz_settings_valid_auto_channels = try(each.value.sixGhzSettings.validAutoChannels, null)
}
