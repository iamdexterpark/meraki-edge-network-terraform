# ---------------------------------------------------------------------------
# MX VPN sub-module
#
# Manages site-to-site VPN and BGP settings on the MX appliance.
#
# Provider resources:
#   - meraki_appliance_site_to_site_vpn
#   - meraki_appliance_vpn_bgp
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# --- Site-to-Site VPN ---
# hubs and subnets are flat list attributes in this provider, not nested blocks.
resource "meraki_appliance_site_to_site_vpn" "this" {
  count = try(var.config.site_to_site_vpn, null) != null ? 1 : 0

  network_id = var.network_id
  mode       = var.config.site_to_site_vpn.mode
  hubs       = try(var.config.site_to_site_vpn.hubs, null)
  subnets    = try(var.config.site_to_site_vpn.subnets, null)
}

# --- BGP ---
# neighbors is a flat list attribute in this provider, not a nested block.
resource "meraki_appliance_vpn_bgp" "this" {
  count = try(var.config.bgp, null) != null ? 1 : 0

  network_id      = var.network_id
  enabled         = try(var.config.bgp.enabled, false)
  as_number       = try(var.config.bgp.asNumber, null)
  ibgp_hold_timer = try(var.config.bgp.ibgpHoldTimer, null)
  neighbors       = try(var.config.bgp.neighbors, null)
}
