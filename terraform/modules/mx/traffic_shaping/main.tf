# ---------------------------------------------------------------------------
# MX Traffic Shaping sub-module
#
# Manages QoS / traffic shaping rules, uplink bandwidth, and uplink
# selection on the MX appliance.
#
# Provider resources:
#   - meraki_appliance_traffic_shaping_rules
#   - meraki_appliance_traffic_shaping_uplink_bandwidth
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# --- Traffic Shaping Rules (QoS) ---
resource "meraki_appliance_traffic_shaping_rules" "this" {
  count = try(var.config.traffic_shaping_rules, null) != null ? 1 : 0

  network_id            = var.network_id
  default_rules_enabled = try(var.config.traffic_shaping_rules.defaultRulesEnabled, true)

  rules = [for r in try(var.config.traffic_shaping_rules.rules, []) : {
    priority                            = try(r.priority, "normal")
    dscp_tag_value                      = try(r.dscpTagValue, null)
    per_client_bandwidth_limit_settings = try(r.perClientBandwidthLimitSettings, "network default")
    definitions = [for d in try(r.definitions, []) : {
      type  = d.type
      value = d.value
    }]
  }]
}

# --- Uplink Bandwidth (flattened attributes in provider) ---
resource "meraki_appliance_traffic_shaping_uplink_bandwidth" "this" {
  count = try(var.config.uplink_bandwidth, null) != null ? 1 : 0

  network_id          = var.network_id
  wan1_limit_down     = try(var.config.uplink_bandwidth.wan1.limitDown, null)
  wan1_limit_up       = try(var.config.uplink_bandwidth.wan1.limitUp, null)
  wan2_limit_down     = try(var.config.uplink_bandwidth.wan2.limitDown, null)
  wan2_limit_up       = try(var.config.uplink_bandwidth.wan2.limitUp, null)
  cellular_limit_down = try(var.config.uplink_bandwidth.cellular.limitDown, null)
  cellular_limit_up   = try(var.config.uplink_bandwidth.cellular.limitUp, null)
}
