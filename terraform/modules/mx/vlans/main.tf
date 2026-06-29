# ---------------------------------------------------------------------------
# MX VLANs sub-module
#
# Creates L3 VLANs on the MX appliance.  Each VLAN entry in the JSON
# config becomes a meraki_appliance_vlan resource.
#
# Dependency: mx/settings must run first (VLANs must be enabled).
#
# Provider resources:
#   - meraki_appliance_vlan (for_each)
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_appliance_vlan" "this" {
  for_each = { for v in try(var.config.vlans, []) : v.id => v }

  network_id   = var.network_id
  vlan_id      = each.value.id
  name         = each.value.name
  subnet       = each.value.subnet
  appliance_ip = each.value.applianceIp

  # Optional DHCP settings — pass through from JSON when present.
  dhcp_handling             = try(each.value.dhcpHandling, null)
  dhcp_lease_time           = try(each.value.dhcpLeaseTime, null)
  dhcp_boot_options_enabled = try(each.value.dhcpBootOptionsEnabled, null)
  dns_nameservers           = try(each.value.dnsNameservers, null)
}
