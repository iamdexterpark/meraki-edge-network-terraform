# ---------------------------------------------------------------------------
# Network module
#
# Creates a Meraki network within the given organization.
# The network is the container that all device modules bind to.
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

resource "meraki_network" "this" {
  organization_id = var.organization_id
  name            = var.config.name
  product_types   = var.config.product_types
  time_zone       = try(var.config.time_zone, "Etc/UTC")
  tags            = try(var.config.tags, ["managed-by-terraform"])
  notes           = try(var.config.notes, "Managed by Terraform — meraki-edge-network-terraform")
}
